// Original code, not ported from Chart.js: date adapter reference generator.
//
// It writes test/port/core/date_adapter_reference.dart, the data of
// test/port/core/date_adapter_test.dart and date_zone_test.dart, also through
// date_table_zone.dart (Chart.js ADR 0024, decision 9): the results of
// chartjs-adapter-moment 1.0.1 on moment 2.29.4 with moment-timezone 0.5.42,
// the date adapter of the Chart.js v4.5.1 specs (karma.conf.cjs:106-111,
// pnpm-lock.yaml:48-50, :123-128). The cases are fixed or come from a seeded
// generator, so a rerun on the same Node.js writes the same file. Nothing in
// lib/ or test/ runs this script (porting-flow.md section 4).
//
// The script loads the files in the order of karma.conf.cjs:106-111:
// moment/min/moment.min.js and
// moment-timezone/builds/moment-timezone-with-data.min.js as globals, then
// `_adapters` of the pinned third_party/Chart.js/src/core/core.adapters.ts
// with the type stripping of Node.js, then
// chartjs-adapter-moment/dist/chartjs-adapter-moment.esm.js. A resolve hook
// maps its imports `chart.js` and `moment` to modules that export `_adapters`
// and the global moment. Then it calls `moment.tz.setDefault('Etc/UTC')`, as
// test/index.js:23 does. The output records the sha256 of each loaded file.
//
// Part 1 (UTC) records the members of the adapter: startOf, endOf, startOf
// with 'isoWeek', add, diff, parse without a format and format with the
// moment FORMATS. A time result is written as its difference to the
// TimeClip of the input time. A string that moment reads with its
// `new Date(string)` fallback (the moment deprecation hook reports it) goes
// to a separate list: the port gives an invalid date for it (row
// adapt-date-parse-fallback).
//
// Part 2 (local) sets process.env.TZ to America/New_York,
// Australia/Lord_Howe and Pacific/Apia, with no default zone of
// moment-timezone. It records the offset changes of each zone in 1900-2100
// (the exact offsets of the local fields of Date), the instants of wall
// times near the changes of 2015-2025 (the JS Date rule), and the results of
// the adapter near those changes and at random times of 1902-2037. The Dart
// tests run these cases through a table zone, a test-only DateZone, so that
// they give the same results on each machine and each compiler.
//
// Part 3 (hour 24) parses ISO strings with the hour 24 on the local date of
// each offset change of 2015-2025 and on the date before, with and without an
// offset, in the three zones of part 2 and in four zones that change at
// local midnight. moment gives the hour 24 to `new Date(y, m, d, 24)` or
// `Date.UTC(y, m, d, 24)` (moment.js:2640-2655). It records the offset
// changes of each zone in 2010-2026 for the table zone.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta), with the Dart
// SDK on the PATH (the script formats the output with `dart format`) and
// with the submodule third_party/Chart.js (`dart run melos run upstream`):
//
//   npm install --no-save --prefix <scratch> moment@2.29.4 \
//     moment-timezone@0.5.42 chartjs-adapter-moment@1.0.1
//   TZ=UTC node tool/reference/date_adapter_reference.mjs \
//     <scratch>/node_modules [--full <file>]
//
// The script stops unless TZ is UTC at the start, and the three packages
// have the versions of the Chart.js lockfile. `--full <file>` also writes the corpus of 357,576 calls
// (the 356,180 calls of the fidelity draft of Chart.js ADR 0024 and 1,396
// parse calls) to <file>, outside the
// repository. test/port/core/date_adapter_vm_test.dart reads it when the
// environment variable DATE_ADAPTER_FULL names the file. Run it once on a
// Chart.js bump and on a change of a lib/src/core/date_*.dart file.

import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {existsSync, readFileSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {join} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import vm from 'node:vm';

const fail = (message) => {
  console.error(message);
  process.exit(1);
};

if (process.env.TZ !== 'UTC') {
  fail('Run the script with TZ=UTC: the moment fallback reads the zone.');
}

let nodeModules = null;
let fullFile = null;
const args = process.argv.slice(2);
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--full') {
    fullFile = args[++i];
  } else {
    nodeModules = args[i];
  }
}
if (!nodeModules || (args.includes('--full') && !fullFile)) {
  fail('Usage: node date_adapter_reference.mjs <node_modules> [--full <file>]');
}

const versions = {
  moment: '2.29.4',
  'moment-timezone': '0.5.42',
  'chartjs-adapter-moment': '1.0.1',
};
for (const [name, version] of Object.entries(versions)) {
  const file = join(nodeModules, name, 'package.json');
  if (!existsSync(file)) fail(`${file} does not exist.`);
  const found = JSON.parse(readFileSync(file, 'utf8')).version;
  if (found !== version) {
    fail(`${name} is ${found}; the Chart.js lockfile gives ${version}.`);
  }
}

const ADAPTERS = new URL(
  '../../../../third_party/Chart.js/src/core/core.adapters.ts',
  import.meta.url,
);
if (!existsSync(ADAPTERS)) {
  fail(
    'third_party/Chart.js is not checked out. Run `dart run melos run upstream`.',
  );
}
const OUT = fileURLToPath(
  new URL('../../test/port/core/date_adapter_reference.dart', import.meta.url),
);

const FILES = [
  ['moment/min/moment.min.js', join(nodeModules, 'moment/min/moment.min.js')],
  [
    'moment-timezone/builds/moment-timezone-with-data.min.js',
    join(
      nodeModules,
      'moment-timezone/builds/moment-timezone-with-data.min.js',
    ),
  ],
  ['src/core/core.adapters.ts', fileURLToPath(ADAPTERS)],
  [
    'chartjs-adapter-moment/dist/chartjs-adapter-moment.esm.js',
    join(
      nodeModules,
      'chartjs-adapter-moment/dist/chartjs-adapter-moment.esm.js',
    ),
  ],
];
const sha256 = (file) =>
  createHash('sha256').update(readFileSync(file)).digest('hex');

// karma.conf.cjs:106-107: moment and moment-timezone as globals.
globalThis.window = globalThis;
for (const [, file] of FILES.slice(0, 2)) {
  vm.runInThisContext(readFileSync(file, 'utf8'), {filename: file});
}
const moment = globalThis.moment;
const dataModule = (source) =>
  'data:text/javascript,' + encodeURIComponent(source);
const chartModule = dataModule(
  `export {default as _adapters} from ${JSON.stringify(
    pathToFileURL(FILES[2][1]).href,
  )};`,
);
const momentModule = dataModule('export default globalThis.moment;');
registerHooks({
  resolve(specifier, context, next) {
    if (specifier === 'chart.js') return {url: chartModule, shortCircuit: true};
    if (specifier === 'moment') return {url: momentModule, shortCircuit: true};
    return next(specifier, context);
  },
});
const {_adapters} = await import(chartModule);
await import(pathToFileURL(FILES[3][1]).href);
// test/index.js:23.
moment.tz.setDefault('Etc/UTC');
const adapter = new _adapters._date({});

moment.suppressDeprecationWarnings = true;
let fallback = false;
moment.deprecationHandler = (name, message) => {
  if (name === null && /RFC2822 or ISO/.test(message)) fallback = true;
};

// Seeded random numbers (mulberry32).
let seed = 0x2468ace;
const random = () => {
  seed |= 0;
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
};
const pick = (list) => list[Math.floor(random() * list.length)];

/** Date.UTC with the years 0-99 as they are. */
const utc = (y, m = 0, d = 1, h = 0, mi = 0, s = 0, ms = 0) => {
  const x = new Date(0);
  x.setUTCFullYear(y, m, d);
  x.setUTCHours(h, mi, s, ms);
  return x.getTime();
};
const randomTime = (from, to) =>
  Math.floor(utc(from) + random() * (utc(to) - utc(from)));

/** TimeClip of a number. */
const clip = (t) => new Date(t).getTime();

/** The marker of a thrown TypeError. */
const TYPE_ERROR = Symbol('TypeError');
const call = (f) => {
  try {
    return f();
  } catch (e) {
    if (e instanceof TypeError) return TYPE_ERROR;
    throw e;
  }
};
/** A time result as its difference to the TimeClip of the input. */
const delta = (result, time) =>
  result === TYPE_ERROR ? TYPE_ERROR : result - clip(time);

// ---------------------------------------------------------------- Dart text

const dartString = (s) => {
  let out = "'";
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    const ch = s[i];
    if (ch === "'" || ch === '\\' || ch === '$') {
      out += '\\' + ch;
    } else if (c >= 0x20 && c < 0x7f) {
      out += ch;
    } else {
      out += `\\u{${c.toString(16).toUpperCase()}}`;
    }
  }
  return out + "'";
};

/** A number. In a `double` context, an integral value is an int literal. */
const dartNumber = (x, objectContext = false) => {
  if (Number.isNaN(x)) return '_nan';
  if (x === Infinity) return 'double.infinity';
  if (x === -Infinity) return 'double.negativeInfinity';
  if (Object.is(x, -0)) x = 0;
  if (Number.isInteger(x) && Math.abs(x) < 2 ** 53) {
    return objectContext ? `${x}.0` : `${x}`;
  }
  return String(x);
};

/** Any value of a JS input, in an `Object?` context. */
const dartValue = (v) => {
  if (v === undefined) return 'undefined';
  if (v === null) return 'null';
  if (v === TYPE_ERROR) return 'dateReferenceTypeError';
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'number') return dartNumber(v, true);
  if (typeof v === 'string') return dartString(v);
  if (Array.isArray(v)) return `<Object?>[${v.map(dartValue).join(', ')}]`;
  if (typeof v === 'object') {
    const entries = Object.entries(v).map(
      ([k, x]) => `${dartString(k)}: ${dartValue(x)}`,
    );
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart form for ${typeof v}`);
};

const doubles = (list) => `[${list.map((x) => dartNumber(x)).join(', ')}]`;
const ints = (list) => `[${list.join(', ')}]`;
const objects = (list) => `[${list.map(dartValue).join(', ')}]`;
const strings = (list) => `[${list.map(dartString).join(', ')}]`;
/** A list of time results: a number, or the TypeError marker. */
const results = (list) =>
  `[${list
    .map((x) => (x === TYPE_ERROR ? 'dateReferenceTypeError' : dartNumber(x, true)))
    .join(', ')}]`;

// ------------------------------------------------------------- Part 1: UTC

const T = [
  0, -1, 1, 1.5, -1.5, 0.5, -0.5, 1e12 + 0.7, -1e12 - 0.3, 8.64e15, -8.64e15,
  8.64e15 - 1, -8.64e15 + 1, 8.64e15 + 1, -8.64e15 - 1, NaN, Infinity,
  utc(2015, 0, 1, 20), utc(2015, 0, 4), utc(2015, 0, 4, 23, 59, 59, 999),
  utc(2015, 0, 5), utc(2015, 0, 5, 0, 0, 0, 1), utc(2015, 0, 10, 12),
  utc(2015, 0, 11, 23, 59), utc(2018, 0, 8, 5, 14, 23, 234),
  utc(2019, 1, 28, 13, 5), utc(2020, 0, 31, 12), utc(2020, 1, 29, 23, 59, 59, 999),
  utc(2020, 2, 31, 6), utc(2020, 11, 31, 23, 59, 59, 999), utc(2021, 0, 31, 13, 5),
  utc(2021, 1, 28), utc(2021, 2, 31), utc(2021, 3, 30, 6), utc(2021, 10, 30, 13, 5),
  utc(2021, 11, 31, 23, 59, 59, 999), utc(2016, 1, 29, 12), utc(2000, 1, 29),
  utc(1900, 0, 1), utc(1900, 1, 28, 12), utc(1969, 11, 31, 23, 59, 59, 999),
  utc(2100, 1, 28, 6, 30), utc(2100, 2, 1), utc(5, 5, 15, 15, 1, 2, 3),
  utc(99, 2, 1, 10), utc(99, 11, 31, 23, 59, 59, 999), utc(100, 0, 1),
  utc(0, 0, 1), utc(-1, 6, 2, 12, 30), utc(9999, 11, 31, 23), utc(10000, 0, 1),
  utc(10000, 5, 15, 8), utc(275760, 8, 12, 12), utc(-271821, 3, 20, 12),
  utc(1999, 9, 5, 13, 7, 9, 5), utc(2015, 11, 31, 12), utc(2016, 0, 1),
  utc(2020, 11, 28), utc(2021, 0, 3, 10), utc(2026, 9, 20, 9, 41),
];
for (let i = 0; i < 50; i++) T.push(randomTime(1900, 2100));

const UNITS = [
  'millisecond', 'second', 'minute', 'hour', 'day', 'date', 'week',
  'isoWeek', 'month', 'quarter', 'year', 'weekday', 'isoWeekday',
  'dayOfYear', 'weekYear', 'isoWeekYear', 'foo', '', 'constructor', null,
  undefined, 1, true,
];
const ALIAS_TIMES = [
  utc(2015, 0, 1, 20, 5, 6, 7), utc(2015, 0, 4, 13), utc(2020, 1, 29, 6, 30),
  utc(1999, 11, 31, 23, 59, 59, 999), utc(2021, 4, 17, 0, 0, 0, 1),
  utc(1900, 6, 9, 9),
];
const ALIASES = [
  'ms', 'milliseconds', 'MS', 'Ms', 's', 'seconds', 'S', 'm', 'minutes', 'M',
  'h', 'hours', 'H', 'HOURS', 'd', 'days', 'Days', 'DAY', 'D', 'dates',
  'Date', 'w', 'weeks', 'W', 'isoweek', 'isoweeks', 'ISOWEEK', 'months',
  'Month', 'Q', 'q', 'quarters', 'y', 'Y', 'years', 'YEAR', 'e', 'weekdays',
  'E', 'isoweekday', 'DDD', 'ddd', 'dayofyear', 'gg', 'GG', 'Gg',
  'weekyear', 'isoweekyears', 'CONSTRUCTOR', 'toString', 'ToString',
  'tostring', '__proto__', 'valueOf', 'hasOwnProperty', '__lookupGetter__',
  // JS toLowerCase gives 'i' and U+0307 for U+0130: no alias.
  'M\u0130NUTE', '\u0130SOWEEK',
];
const WEEKDAYS = [
  0, 1, 2, 3, 4, 5, 6, 7, 8, 1.5, 6.9, -1, -0.5, true, false, '3', 'abc',
  null, undefined, NaN, Infinity,
];

const startOf = [];
const endOf = [];
for (const t of T) {
  for (const u of UNITS) {
    startOf.push(delta(call(() => adapter.startOf(t, u)), t));
    endOf.push(delta(call(() => adapter.endOf(t, u)), t));
  }
}
const aliasStartOf = [];
const aliasEndOf = [];
for (const t of ALIAS_TIMES) {
  for (const u of ALIASES) {
    aliasStartOf.push(delta(adapter.startOf(t, u), t));
    aliasEndOf.push(delta(adapter.endOf(t, u), t));
  }
}
const isoWeek = [];
for (const t of T) {
  for (const w of WEEKDAYS) {
    isoWeek.push(delta(call(() => adapter.startOf(t, 'isoWeek', w)), t));
  }
}

const ADD_TIMES = [
  utc(2015, 0, 1, 20), utc(2015, 0, 31, 10, 30), utc(2016, 1, 29, 12),
  utc(2020, 2, 31, 23, 59, 59, 999), utc(99, 0, 31, 1), 1.5, 8.64e15 - 1,
  -8.64e15 + 1, NaN,
];
ADD_TIMES.push(randomTime(1900, 2100));
const AMOUNTS = [
  -13, -2.5, -1, -0.5, 0, 0.1, 1 / 3, 0.4, 0.5, 1, 1.5, 2.5, 13, 1e9,
  Infinity, NaN, '2', ' 3 ', '', 'abc', 'P1D', true, null, undefined, [2],
];
const ADD_UNITS = [
  'millisecond', 'second', 'minute', 'hour', 'day', 'date', 'week',
  'isoWeek', 'month', 'quarter', 'year', 'weekday', 'days', 'M', 'foo', '',
  null, undefined, NaN, 1, true, false, ['day'],
];
const add = [];
for (const t of ADD_TIMES) {
  for (const n of AMOUNTS) {
    for (const u of ADD_UNITS) add.push(delta(adapter.add(t, n, u), t));
  }
}
// The duration string 'P1D' is an amount of moment, not of the port (row
// adapt-date-parse-fallback): the test skips it.

const DIFF_GRID = [];
for (const [y, m, days] of [
  [2019, 10, [1, 15, 28, 29, 30]],
  [2019, 11, [1, 15, 28, 29, 30, 31]],
  [2020, 0, [1, 15, 28, 29, 30, 31]],
  [2020, 1, [1, 15, 28, 29]],
  [2020, 2, [1, 15, 28, 29, 30, 31]],
  [2020, 3, [1, 15, 28, 29, 30]],
]) {
  for (const d of days) DIFF_GRID.push(utc(y, m, d), utc(y, m, d, 12, 30));
}
const GRID_UNITS = ['month', 'quarter', 'year'];
const diffGrid = [];
for (const a of DIFF_GRID) {
  for (const b of DIFF_GRID) {
    for (const u of GRID_UNITS) diffGrid.push(adapter.diff(a, b, u));
  }
}
const DIFF_UNITS = [
  'millisecond', 'second', 'minute', 'hour', 'day', 'date', 'week',
  'isoWeek', 'month', 'quarter', 'year', 'weekday', 'foo', 'constructor',
  null, undefined,
];
const DIFF_PAIRS = [];
for (let i = 0; i < 100; i++) {
  const a = randomTime(1900, 2100);
  const scale = random() < 0.3 ? 0.01 : 1;
  DIFF_PAIRS.push(a, a - Math.floor(random() * 3 * 3.2e10 * scale));
}
for (let i = 0; i < 40; i++) DIFF_PAIRS.push(pick(T), pick(T));
DIFF_PAIRS.push(
  1001.5, 0.2, 100000.5, 0, -1.5, 1.5, NaN, 0, 0, NaN, 8.64e15 + 1, 0, 0,
  -8.64e15 - 1, null, utc(2015), utc(2015), null, 'abc', utc(2015),
  utc(2015), 'abc',
);
const diffPairs = [];
for (let i = 0; i < DIFF_PAIRS.length; i += 2) {
  for (const u of DIFF_UNITS) {
    diffPairs.push(adapter.diff(DIFF_PAIRS[i], DIFF_PAIRS[i + 1], u));
  }
}

// parse: the ISO corpus of the performance draft, the strings of the
// fidelity draft and the edges of the token parse.
const pad = (n, w) => String(Math.abs(n)).padStart(w, '0');
const PARSE = new Set();
for (let k = 0; k < 60; k++) {
  const y = 1900 + Math.floor(random() * 200);
  const Y = pad(y, 4);
  const M = pad(1 + Math.floor(random() * 12), 2);
  const D = pad(1 + Math.floor(random() * 31), 2);
  const H = pad(Math.floor(random() * 24), 2);
  const I = pad(Math.floor(random() * 60), 2);
  const S = pad(Math.floor(random() * 60), 2);
  const ms = pad(Math.floor(random() * 1000), 3);
  const week = pad(1 + Math.floor(random() * 53), 2);
  const day = 1 + Math.floor(random() * 7);
  for (const s of [
    `${Y}-${M}-${D}`, `${Y}-${M}-${D}T${H}:${I}`, `${Y}-${M}-${D}T${H}:${I}:${S}`,
    `${Y}-${M}-${D} ${H}:${I}:${S}.${ms}`, `${Y}-${M}-${D}T${H}:${I}:${S}.${ms}Z`,
    `${Y}-${M}-${D}T${H}:${I}:${S}+05:30`, `${Y}-${M}-${D}T${H}:${I}:${S}-0800`,
    `${Y}-${M}-${D}T${H}:${I}+02`, `${Y}${M}${D}`, `${Y}${M}${D}T${H}${I}${S}`,
    `${Y}${M}${D} ${H}${I}`, `${Y}-${M}`, `${Y}`,
    `${Y}-${pad(1 + Math.floor(random() * 366), 3)}`, `${Y}-W${week}-${day}`,
    `${Y}W${week}${day}`, `${Y}-W${week}`,
    `${Y}-${M}-${D}T${H}:${I}:${S}.${pad(Math.floor(random() * 1e6), 6)}`,
    `${Y}-${M}-${D}T${H}:${I}:${S},${Math.floor(random() * 10)}`,
    `${Y}-${M}-${D}T${H}`,
  ]) {
    PARSE.add(s);
  }
}
for (const s of [
  '2015-01-01T20:00:00', '2015-01-07T03:00', '2016-05-27', '2017',
  '2018-01-08T05:14:23.234Z', '+002015-01-01', '-000001-01-01',
  '+275760-09-13', '+275760-09-14', '-271821-04-20', '-271821-04-19T23:00',
  '+275760-09-13T00:00:00+01:00', '+275760-09-13T01:00:00+01:00',
  '2015-02-29', '2016-02-29', '2015-13-01', '2015-00-10', '2015-01-00',
  '2015-01-32', '2015-04-31', '2015-01-01T25:00', '2015-01-01T24:00',
  '2015-01-01T24:00:00.000', '2015-01-01T24:00:01', '2015-01-01T24:00Z',
  '2015-01-01T24:00+05:00', '2015-12-31T24:00', '2015-01-01T23:60',
  '2015-01-01T23:59:60', ' 2015-01-01', '\t2015-01-01T10:00',
  ' 　2015-01-01', '2015-1-1', '2015-01-01T2000', '20150101T20:00',
  '2015-W53-1', '2016-W53-1', '2015-W00-1', '2015-W01-0', '2015-W01-8',
  '2020-W53-7', '2021-W53', '2015-W54', '2015-366', '2016-366', '2015-000',
  '2015-01-01T10:00:00z', '2015-01-01T10:00:00 Z', '2015-01-01T10:00:00  Z',
  '2015-01-01T10:00:00 Z', '2015-01-01T10:00:00.5Z',
  '2015-01-01T10:00:00.9999', '2015-01-01T10:00:00.0579',
  '2015-01-01T10:00:00.035', '2015-01-01T10:00:00.123456789',
  '2015-01-01T10:00:00.9999999999999999999Z',
  '2015-01-01T10:00:00.57999999999999999Z', '2015-01-01T10:00:00+0530',
  '2015-01-01T10:00:00+05', '2015-01-01T10:00:00+5', '2015-01-01T10:00:00+05:3',
  '2015-01-01t10:00', '2015-01-01T10:00:00.', '2015-01-01T10:', '2015-01-01T1',
  '201501', '2015001', '20151', '2015-1', '0000-01-01', '0099-12-31',
  '0050-06-01T12:00', '2015-01-01T00:00:00+24:00', '2015-01-01T00:00:00+99:99',
  '2015-01-01T00:00:00-00:00', '2015-01-01T10:00:00Z ',
  '2015-01-01T10:00:00GMT', '12345', '1234567', '123456789', '2015-W011',
  '2015W011', '2015W01', '2015W537T10', '2015-W01-1T10:00Z',
  '2015-01-01T10:00:00.000000001Z', '+002015-01', '+002015-W01-1',
  '+002015-W01', '+002015-123', '+002015', '-000001', '+002015123',
  '+00201501', '+0020150101', '+0020150101T1030', '+002015W011', '+002015W01',
  '-002015-01-01T10:00:00Z', '20150101 200000Z', '2015-01-01T200000',
  '20150101T20:00:00', '2015-01-01T', '2015-01-01TZ', '2015-01-01Z',
  '2015-01-01T20:00:00+01:00Z', '2015-01T10:00', '2015-W01T10:00',
  'Thu, 01 Jan 2015 20:00:00 +0000', 'Thu, 01 Jan 2015 20:00:00 GMT',
  'Thu, 01 Jan 2015 20:00:00 +0100', 'Thu, 01 Jan 2015 20:00 EST',
  'Fri, 01 Jan 2015 20:00:00 GMT', '01 Jan 2015 20:00:00 Z',
  '1 Jan 15 20:00:00 UT', '1 Jan 49 20:00 GMT', '1 Jan 50 20:00 GMT',
  '1 Jan 999 20:00 GMT', '1 Jan 0050 10:00 z', '1 Jan 0000 10:00 z',
  'Thu, 01 Jan 2015 20:00:00 (comment) GMT',
  ' Thu,  01 Jan 2015   20:00:00 GMT ', 'Thu 01 Jan 2015 20:00:00 GMT',
  'Thu, 1 Jan 2015 20:00:00 PDT', 'Thu, 01 Jan 2015 20:00:00 gmt',
  'Thu, 01 Jan 2015 20:00:00 +01:00', 'Sun, 31 Feb 2015 20:00:00 GMT',
  '32 Jan 2015 20:00:00 +0000', 'Sun, 01 Feb 2015 20:00 GMT',
  '01 Jan 2015 24:00 GMT', '01 Jan 2015 23:60 GMT',
  '01 Jan 2015 23:59:60 GMT', '29 Feb 2015 10:00 GMT', '29 Feb 2016 10:00 CST',
  '01 Jan 2015 20:00:00 +9999', 'Thu 01 Jan 2015 20:00:00 -0130',
  'Thu,\t01 Jan 2015\n20:00:00 MDT', 'Thu, 01 Jan 2015 (a (b) c) 20:00 GMT',
  'Thu, 01 Jan 2015 20:00 (x GMT', '1 Jan 275760 10:00 GMT', '0 Jan 2015 10:00 GMT',
  '/Date(1420142400000)/', 'Date(1420142400000)', '/date(-5)/',
  '/Date(1420142400000+0100)/', '/Date(abc)/', 'Date(-5', 'DATE(12)',
  '/Date(-0)/', '/Date(000000000000000000012)/', 'Date(99999999999999999)/',
  'Date(8640000000000001)', '/Date(-8640000000000000)/',
  'Thu Jan 01 2015 20:00:00 GMT+0000 (Coordinated Universal Time)',
  'Thu Jan 01 2015', '1420142400000', '1e12', '2015/01/01', '01/02/2015',
  '1/2/2015', 'Jan 1, 2015', 'January 1, 2015', '2015-Jan-01', 'abc', ' ',
  'T10:00', '10:00', '2015-01-01 ', '2015-01-01T10:00:00+0100Z', 'true',
  // A signed year in a form of four digits: the token parse with a time and
  // a zone.
  '+356076-W19-4 21:12:15,671086  Z', '-764401301T074704,418Z',
  '+140830-W14-7T21:50:37,815923503', '-853801-057T15:05:30,424926644019+17',
  '-594233-W04-5 01:52 Z', '-061572-074T14 Z', '+754875-122T24 Z',
  '-759245-W41-7 18-15', '+397333-133T02:24+04', '+068230-062T21:44:31-2313',
  '+602904-088T14:19:04-14:60', '-585408072 0304', '+113448W347 1751',
  '+135359W151T16', '\u3000-360685-06', '-719710-W44-1T25:60:08',
  '-583466-090 04:60', '-859035839T24+10:23', '\ufeff2015-01-01',
  '\ufeff+002015-123T10:30Z',
  // The hour 24 of December 31 in a year 0-99: moment builds the year + 400
  // and then sets the year (moment.js:1282-1316).
  '0099-12-31T24:00', '0050-12-31T24:00Z', '0050-12-31T24:00+01:00',
  '0000-12-31T24:00', '0099-12-30T24:00', '0100-12-31T24:00',
  '+000050-12-31T24:00', '-000001-12-31T24:00', '00991231T24',
  '0099-365T24:00', '0099-W52-5T24:00', '0099-W53-4T24:00',
]) {
  PARSE.add(s);
}
const parseCases = [];
const fallbackStrings = [];
for (const s of PARSE) {
  fallback = false;
  const v = adapter.parse(s);
  if (fallback) {
    fallbackStrings.push(s);
  } else {
    parseCases.push([s, v]);
  }
}
for (const v of [
  1.5, -1.5, 0, -0.5, 1e300, 8.64e15, 8.64e15 + 1, -8.64e15, NaN, Infinity,
  -Infinity, null, '', true, false,
]) {
  // moment gives a boolean to its fallback: `new Date('true')` is invalid.
  parseCases.push([v, adapter.parse(v)]);
}

// format: the FORMATS of the adapter.
const FORMATS = adapter.formats();
const FORMAT_KEYS = Object.keys(FORMATS);
const FORMAT_TIMES = [
  utc(2015, 0, 1, 20), utc(2018, 0, 8, 5, 14, 23, 234), utc(2020, 6, 4),
  utc(2020, 6, 4, 12), utc(2020, 6, 4, 0, 30), utc(2020, 6, 4, 12, 30),
  utc(2021, 11, 31, 23, 59, 59, 999), utc(1999, 9, 5, 13, 7, 9, 5),
  utc(99, 2, 1, 10), utc(5, 5, 15, 15, 1, 2, 3), utc(0, 0, 1),
  utc(10000, 0, 1, 11), utc(275760, 8, 13), -1, 0, 1,
];
for (let i = 0; i < 104; i++) FORMAT_TIMES.push(randomTime(1900, 2100));
const formatTexts = [];
for (const t of FORMAT_TIMES) {
  for (const k of FORMAT_KEYS) formatTexts.push(adapter.format(t, FORMATS[k]));
}
const formatEdges = [];
for (const t of [utc(2015, 0, 1, 20), utc(12345, 0, 1), utc(-5, 0, 1), -1]) {
  for (const f of [undefined, null, '', false, 0, NaN]) {
    formatEdges.push([t, f, call(() => adapter.format(t, f))]);
  }
}
for (const [t, f] of [
  [utc(2015, 0, 1, 20), 5],
  [utc(2015, 0, 1, 20), {}],
  // An array format throws, unless moment has a cached format function for
  // its string ['YYYY'] → 'YYYY' (moment.js:522-534). The port throws.
  [utc(2015, 0, 1, 20), true],
  [NaN, 'YYYY'],
  [NaN, 5],
  [NaN, undefined],
  [null, 'YYYY'],
  ['abc', 'YYYY'],
  [8.64e15 + 1, {}],
]) {
  formatEdges.push([t, f, call(() => adapter.format(t, f))]);
}

// ---------------------------------------------------------- Part 2: local

const H = 3600000;
const DAY = 86400000;
/**
 * The exact offset of the instant t in the zone of the process: the UTC ms
 * of the local fields minus t. The scan starts in 1899, so Date.UTC does
 * not remap a year 0-99.
 */
const offsetOf = (t) => {
  const d = new Date(t);
  return (
    Date.UTC(
      d.getFullYear(),
      d.getMonth(),
      d.getDate(),
      d.getHours(),
      d.getMinutes(),
      d.getSeconds(),
      d.getMilliseconds(),
    ) - t
  );
};
const LOCAL_UNITS = ['hour', 'day', 'week', 'isoweek', 'month', 'year'];
const LOCAL_WEEKDAYS = [0, 3, 6];
const LOCAL_ADDS = [
  [1, 'hour'], [-1, 'hour'], [1, 'day'], [-1, 'day'], [0.5, 'day'],
  [1, 'week'], [1, 'month'], [-1, 'month'], [1, 'year'],
];
const LOCAL_DIFF_UNITS = ['hour', 'day', 'week', 'month'];
const LOCAL_FIELDS_FORMAT = 'YYYY-MM-DD HH:mm:ss.SSS';

/**
 * The offset changes of the zone of the process from start to end: a scan by
 * six hours, then a search of the first instant of the new offset. It gives
 * the offset at start, the instant of each change and the offset from it on.
 */
const offsetChanges = (start, end) => {
  const initialOffset = offsetOf(start);
  const changes = [];
  const offsets = [];
  let previous = initialOffset;
  for (let t = start; t <= end; t += 6 * H) {
    const offset = offsetOf(t);
    if (offset === previous) continue;
    let lo = t - 6 * H;
    let hi = t;
    while (hi - lo > 1) {
      const mid = lo + Math.floor((hi - lo) / 2);
      if (offsetOf(mid) === previous) lo = mid;
      else hi = mid;
    }
    changes.push(hi);
    offsets.push(offset);
    previous = offset;
  }
  return {initialOffset, changes, offsets};
};

/** The changes of 2015-2025: the instant, the offset before and after. */
const recentChanges = ({initialOffset, changes, offsets}) =>
  changes
    .map((c, i) => [c, i === 0 ? initialOffset : offsets[i - 1], offsets[i]])
    .filter(([c]) => c >= utc(2015) && c < utc(2026));

const zones = [];
for (const name of ['America/New_York', 'Australia/Lord_Howe', 'Pacific/Apia']) {
  process.env.TZ = name;
  moment.tz.setDefault();
  if (offsetOf(utc(2015, 6, 1)) === 0) fail(`TZ=${name} has no effect.`);
  // The offset changes of 1900-2100.
  const table = offsetChanges(utc(1899, 11, 31), utc(2101));
  const {initialOffset, changes, offsets} = table;
  // The wall times near the changes of 2015-2025 and their instants.
  const recent = recentChanges(table);
  const walls = [];
  const wallInstants = [];
  for (const [c, before] of recent) {
    for (const k of [-2, -1, 0, 1, 2, 3, 4]) {
      const wall = c + before + k * 1800000;
      const f = new Date(wall);
      walls.push(wall);
      wallInstants.push(
        new Date(
          f.getUTCFullYear(),
          f.getUTCMonth(),
          f.getUTCDate(),
          f.getUTCHours(),
          f.getUTCMinutes(),
        ).getTime(),
      );
    }
  }
  // The cases of the adapter.
  const times = [];
  for (const [c] of recent) {
    for (const k of [-1, 0, 1]) times.push(c + k * 1800000);
  }
  for (let i = 0; i < 30; i++) times.push(randomTime(1902, 2037));
  const zoneStartOf = [];
  const zoneEndOf = [];
  const zoneIsoWeek = [];
  const zoneAdd = [];
  const diffOthers = [];
  const zoneDiff = [];
  const formatDefault = [];
  const formatFields = [];
  times.forEach((t, i) => {
    for (const u of LOCAL_UNITS) {
      zoneStartOf.push(delta(adapter.startOf(t, u), t));
      zoneEndOf.push(delta(adapter.endOf(t, u), t));
    }
    for (const w of LOCAL_WEEKDAYS) {
      zoneIsoWeek.push(delta(adapter.startOf(t, 'isoWeek', w), t));
    }
    for (const [n, u] of LOCAL_ADDS) zoneAdd.push(delta(adapter.add(t, n, u), t));
    const others = [t - DAY, times[(i + 7) % times.length]];
    for (const b of others) {
      diffOthers.push(b);
      for (const u of LOCAL_DIFF_UNITS) zoneDiff.push(adapter.diff(t, b, u));
    }
    formatDefault.push(adapter.format(t));
    formatFields.push(adapter.format(t, LOCAL_FIELDS_FORMAT));
  });
  zones.push({
    name,
    initialOffset,
    changes,
    offsets,
    walls,
    wallInstants,
    times,
    startOf: zoneStartOf,
    endOf: zoneEndOf,
    isoWeek: zoneIsoWeek,
    add: zoneAdd,
    diffOthers,
    diff: zoneDiff,
    formatDefault,
    formatFields,
  });
}

// --------------------------------------------------------- Part 3: hour 24

// The zones of part 2 change at 02:00 or later. The other zones change at
// local midnight in 2015-2025, so 24:00 of the date before a change is a
// skipped or a repeated wall time.
const HOUR24_ZONES = [
  'America/New_York', 'Australia/Lord_Howe', 'Pacific/Apia',
  'America/Sao_Paulo', 'America/Havana', 'America/Santiago', 'Asia/Beirut',
];
const hour24Zones = [];
for (const name of HOUR24_ZONES) {
  process.env.TZ = name;
  moment.tz.setDefault();
  if (offsetOf(utc(2015, 6, 1)) === 0) fail(`TZ=${name} has no effect.`);
  const table = offsetChanges(utc(2010), utc(2027));
  const texts = [];
  const results = [];
  for (const [c, before] of recentChanges(table)) {
    // The local date of the change, and the date before.
    const wall = new Date(c + before);
    for (const k of [-1, 0]) {
      const day = new Date(
        utc(wall.getUTCFullYear(), wall.getUTCMonth(), wall.getUTCDate() + k),
      );
      const ymd =
        `${pad(day.getUTCFullYear(), 4)}-${pad(day.getUTCMonth() + 1, 2)}-` +
        pad(day.getUTCDate(), 2);
      for (const s of [
        `${ymd}T24:00`, `${ymd}T24:00Z`, `${ymd}T24:00:00.000+05:30`,
        `${ymd} 24:00-08:00`, `${ymd.replaceAll('-', '')}T2400+14`,
      ]) {
        texts.push(s);
        results.push(adapter.parse(s) ?? NaN);
      }
    }
  }
  hour24Zones.push({name, ...table, texts, results});
}
process.env.TZ = 'UTC';
moment.tz.setDefault('Etc/UTC');

// ------------------------------------------------------------------ Output

const hashes = FILES.map(([name, file]) => `//   ${name}: ${sha256(file)}`).join('\n');
const zoneText = (z) => `  (
    name: ${dartString(z.name)},
    initialOffset: ${z.initialOffset},
    changes: ${ints(z.changes)},
    offsets: ${ints(z.offsets)},
    walls: ${ints(z.walls)},
    wallInstants: ${ints(z.wallInstants)},
    times: ${doubles(z.times)},
    startOf: ${doubles(z.startOf)},
    endOf: ${doubles(z.endOf)},
    isoWeek: ${doubles(z.isoWeek)},
    add: ${doubles(z.add)},
    diffOthers: ${doubles(z.diffOthers)},
    diff: ${doubles(z.diff)},
    formatDefault: ${strings(z.formatDefault)},
    formatFields: ${strings(z.formatFields)},
  ),
`;
const hour24Text = (z) => `  (
    name: ${dartString(z.name)},
    initialOffset: ${z.initialOffset},
    changes: ${ints(z.changes)},
    offsets: ${ints(z.offsets)},
    texts: ${strings(z.texts)},
    results: ${doubles(z.results)},
  ),
`;

const out = `// Original code, not ported from Chart.js: date adapter reference data.

// Generated by tool/reference/date_adapter_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// chartjs-adapter-moment ${versions['chartjs-adapter-moment']} on moment ${moment.version} with
// moment-timezone ${versions['moment-timezone']} (moment.tz.setDefault('Etc/UTC') in part 1),
// and src/core/core.adapters.ts at the pinned Chart.js. The sha256 of the
// loaded files:
${hashes}

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// NaN, short for the lists below.
const double _nan = double.nan;

/// The Node.js version that generated the data.
const String dateReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String dateReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String dateReferenceArch = '${process.arch}';

/// The versions of moment, moment-timezone and chartjs-adapter-moment.
const List<String> dateReferencePackages = [
  'moment ${versions.moment}',
  'moment-timezone ${versions['moment-timezone']}',
  'chartjs-adapter-moment ${versions['chartjs-adapter-moment']}',
];

/// The result of a call that throws a \`TypeError\`.
const String dateReferenceTypeError = '<TypeError>';

// ----------------------------------------------------------- Part 1: UTC

/// The times of the \`startOf\`, \`endOf\` and \`isoWeek\` cases.
const List<double> dateReferenceTimes = ${doubles(T)};

/// The units of the \`startOf\` and \`endOf\` cases.
const List<Object?> dateReferenceUnits = ${objects(UNITS)};

/// \`startOf(time, unit)\` minus the TimeClip of the time, or
/// [dateReferenceTypeError], for each time of [dateReferenceTimes] and each
/// unit of [dateReferenceUnits] (the index is \`time * units + unit\`). A NaN
/// difference is a NaN result.
const List<Object> dateReferenceStartOf = ${results(startOf)};

/// \`endOf(time, unit)\` minus the TimeClip of the time, in the order of
/// [dateReferenceStartOf].
const List<Object> dateReferenceEndOf = ${results(endOf)};

/// The times of the alias cases.
const List<double> dateReferenceAliasTimes = ${doubles(ALIAS_TIMES)};

/// The unit spellings of the alias cases.
const List<String> dateReferenceAliases = ${strings(ALIASES)};

/// \`startOf(time, alias)\` minus the time, for each time of
/// [dateReferenceAliasTimes] and each alias of [dateReferenceAliases].
const List<double> dateReferenceAliasStartOf = ${doubles(aliasStartOf)};

/// \`endOf(time, alias)\` minus the time, in the order of
/// [dateReferenceAliasStartOf].
const List<double> dateReferenceAliasEndOf = ${doubles(aliasEndOf)};

/// The weekdays of the \`startOf(time, 'isoWeek', weekday)\` cases.
const List<Object?> dateReferenceWeekdays = ${objects(WEEKDAYS)};

/// \`startOf(time, 'isoWeek', weekday)\` minus the TimeClip of the time, or
/// [dateReferenceTypeError], for each time of [dateReferenceTimes] and each
/// weekday of [dateReferenceWeekdays].
const List<Object> dateReferenceIsoWeek = ${results(isoWeek)};

/// The times of the \`add\` cases.
const List<double> dateReferenceAddTimes = ${doubles(ADD_TIMES)};

/// The amounts of the \`add\` cases.
const List<Object?> dateReferenceAmounts = ${objects(AMOUNTS)};

/// The units of the \`add\` cases.
const List<Object?> dateReferenceAddUnits = ${objects(ADD_UNITS)};

/// \`add(time, amount, unit)\` minus the TimeClip of the time, for each time
/// of [dateReferenceAddTimes], each amount of [dateReferenceAmounts] and
/// each unit of [dateReferenceAddUnits] (the index is
/// \`(time * amounts + amount) * units + unit\`).
const List<double> dateReferenceAdd = ${doubles(add)};

/// The times of the \`diff\` grid: month ends of November 2019 to April
/// 2020, at 00:00 and 12:30.
const List<double> dateReferenceDiffGrid = ${doubles(DIFF_GRID)};

/// The units of the \`diff\` grid.
const List<String> dateReferenceGridUnits = ${strings(GRID_UNITS)};

/// \`diff(a, b, unit)\` for each time \`a\` and each time \`b\` of
/// [dateReferenceDiffGrid] and each unit of [dateReferenceGridUnits] (the
/// index is \`(a * times + b) * units + unit\`).
const List<double> dateReferenceDiffGridResults = ${doubles(diffGrid)};

/// The pairs of the \`diff\` cases: \`a\` and \`b\` of each pair, one after
/// the other.
const List<Object?> dateReferenceDiffPairs = ${objects(DIFF_PAIRS)};

/// The units of the \`diff\` pairs.
const List<Object?> dateReferenceDiffUnits = ${objects(DIFF_UNITS)};

/// \`diff(a, b, unit)\` for each pair of [dateReferenceDiffPairs] and each
/// unit of [dateReferenceDiffUnits].
const List<double> dateReferenceDiffPairResults = ${doubles(diffPairs)};

/// \`parse(value)\` without a format: the value and the result, or \`null\`
/// for an invalid date.
const List<(Object?, double?)> dateReferenceParse = [
${parseCases.map(([v, r]) => `  (${dartValue(v)}, ${r === null ? 'null' : dartNumber(r)}),\n`).join('')}];

/// The strings that moment reads with its \`new Date(string)\` fallback.
/// The port gives an invalid date for them (row
/// \`adapt-date-parse-fallback\`).
const List<String> dateReferenceFallbackStrings = ${strings(fallbackStrings)};

/// The keys of the moment \`FORMATS\`, in their order.
const List<String> dateReferenceFormatKeys = ${strings(FORMAT_KEYS)};

/// The moment \`FORMATS\` of chartjs-adapter-moment.
const List<String> dateReferenceMomentFormats = ${strings(FORMAT_KEYS.map((k) => FORMATS[k]))};

/// The times of the format cases.
const List<double> dateReferenceFormatTimes = ${doubles(FORMAT_TIMES)};

/// \`format(time, FORMATS[key])\` for each time of [dateReferenceFormatTimes]
/// and each key of [dateReferenceFormatKeys].
const List<String> dateReferenceFormatTexts = ${strings(formatTexts)};

/// \`format(time, format)\` of the edge cases: the time, the format and the
/// text or [dateReferenceTypeError].
const List<(Object?, Object?, String)> dateReferenceFormatEdges = [
${formatEdges.map(([t, f, r]) => `  (${dartValue(t)}, ${dartValue(f)}, ${dartValue(r)}),\n`).join('')}];

// --------------------------------------------------------- Part 2: local

/// The units of the \`startOf\` and \`endOf\` cases of a zone.
const List<String> dateReferenceLocalUnits = ${strings(LOCAL_UNITS)};

/// The weekdays of the \`startOf(time, 'isoWeek', weekday)\` cases of a
/// zone.
const List<double> dateReferenceLocalWeekdays = ${doubles(LOCAL_WEEKDAYS)};

/// The amounts and units of the \`add\` cases of a zone.
const List<(double, String)> dateReferenceLocalAdds = [
${LOCAL_ADDS.map(([n, u]) => `  (${dartNumber(n)}, ${dartString(u)}),\n`).join('')}];

/// The units of the \`diff\` cases of a zone.
const List<String> dateReferenceLocalDiffUnits = ${strings(LOCAL_DIFF_UNITS)};

/// The moment format of the \`formatFields\` of [DateReferenceZone].
const String dateReferenceLocalFieldsFormat = ${dartString(LOCAL_FIELDS_FORMAT)};

/// The data of one zone, with no default zone of moment-timezone.
///
/// - \`initialOffset\`: the offset at 1899-12-31T00:00Z, in ms.
/// - \`changes\` and \`offsets\`: the instant of each offset change of
///   1900-2100 and the offset from it on. The offsets are the exact offsets
///   of the local fields of \`Date\`.
/// - \`walls\` and \`wallInstants\`: wall times near the changes of 2015-2025
///   (the wall fields as UTC ms) and \`new Date(fields).getTime()\`.
/// - \`times\`: the times of the cases.
/// - \`startOf\` and \`endOf\`: the result minus the time, for each time and
///   each unit of [dateReferenceLocalUnits].
/// - \`isoWeek\`: \`startOf(time, 'isoWeek', weekday)\` minus the time, for
///   each weekday of [dateReferenceLocalWeekdays].
/// - \`add\`: the result minus the time, for each case of
///   [dateReferenceLocalAdds].
/// - \`diffOthers\` and \`diff\`: two other times \`b\` for each time \`a\`,
///   and \`diff(a, b, unit)\` for each unit of [dateReferenceLocalDiffUnits].
/// - \`formatDefault\`: \`format(time)\`, the ISO default text.
/// - \`formatFields\`: \`format(time, dateReferenceLocalFieldsFormat)\`.
typedef DateReferenceZone = ({
  String name,
  int initialOffset,
  List<int> changes,
  List<int> offsets,
  List<int> walls,
  List<int> wallInstants,
  List<double> times,
  List<double> startOf,
  List<double> endOf,
  List<double> isoWeek,
  List<double> add,
  List<double> diffOthers,
  List<double> diff,
  List<String> formatDefault,
  List<String> formatFields,
});

/// The zones of part 2.
const List<DateReferenceZone> dateReferenceZones = [
${zones.map(zoneText).join('')}];

// ------------------------------------------------------- Part 3: hour 24

/// The cases of the hour 24 of one zone, with no default zone of
/// moment-timezone.
///
/// - \`initialOffset\`, \`changes\` and \`offsets\`: the offset at
///   2010-01-01T00:00Z, the instant of each offset change of 2010-2026 and
///   the offset from it on, in ms.
/// - \`texts\`: ISO strings with the hour 24, with and without an offset, on
///   the local date of each offset change of 2015-2025 and on the date
///   before.
/// - \`results\`: \`parse(text)\` of each text.
typedef DateReferenceHour24Zone = ({
  String name,
  int initialOffset,
  List<int> changes,
  List<int> offsets,
  List<String> texts,
  List<double> results,
});

/// The zones of part 3.
const List<DateReferenceHour24Zone> dateReferenceHour24Zones = [
${hour24Zones.map(hour24Text).join('')}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
const size = readFileSync(OUT).length;
console.log(
  `Wrote ${OUT}: ${size} bytes; ${startOf.length * 2 + aliasStartOf.length * 2} ` +
    `startOf/endOf, ${isoWeek.length} isoWeek, ${add.length} add, ` +
    `${diffGrid.length + diffPairs.length} diff, ${parseCases.length} parse, ` +
    `${fallbackStrings.length} fallback, ${formatTexts.length + formatEdges.length} ` +
    `format, ${zones.map((z) => `${z.name} ${z.changes.length} changes ${z.times.length} times`).join(', ')}, ` +
    `${hour24Zones.reduce((n, z) => n + z.texts.length, 0)} hour 24.`,
);

// ------------------------------------------------------------ Full corpus

if (fullFile) writeFullCorpus(fullFile);

/**
 * The corpus of the fidelity draft of Chart.js ADR 0024 in UTC: the same
 * inputs as gen_corpus.mjs of the draft, written as JSON. A value that JSON
 * has no form for is an object: {u: 1} is undefined, {n: 'NaN'} a number,
 * {date: ms} a Date, {arr: [...]} an array and {obj: {...}} an object.
 */
function writeFullCorpus(file) {
  seed = 0x2468ace;
  const mk = utc;
  const T = [0, -1, 1, 1.5, -1.5, 0.5, -0.5, 1e12 + 0.7, -1e12 - 0.3, 8.64e15, -8.64e15, 8.64e15 - 1, -8.64e15 + 1];
  const years = [-1, 0, 1, 99, 100, 1600, 1899, 1900, 1969, 1970, 1999, 2000, 2015, 2016, 2020, 2021, 2038, 2100, 9999, 10000, 275759];
  for (const y of years) {
    const t = mk(y);
    T.push(t - 1, t, t + 1, mk(y, 6, 2, 12, 30, 15, 500));
  }
  for (let d = 1; d <= 31; d++) T.push(mk(2015, 0, d, 20, 0, 0, 123), mk(2015, 0, d), mk(2015, 0, d, 23, 59, 59, 999));
  for (let d = 25; d <= 34; d++) T.push(mk(2020, 1, d, 20, 0, 0, 123), mk(2021, 1, d, 6, 0));
  const monthEnds = [];
  for (const y of [2019, 2020, 2021]) for (let m = 0; m < 12; m++) monthEnds.push(mk(y, m + 1, 0, 13, 5), mk(y, m, 1, 0, 0));
  T.push(...monthEnds);
  for (let i = 0; i < 400; i++) T.push(Math.floor(utc(1) + random() * (utc(9999, 11, 31) - utc(1))));
  for (let i = 0; i < 400; i++) T.push(Math.floor(utc(1900) + random() * (utc(2100) - utc(1900))));
  for (let i = 0; i < 50; i++) T.push(utc(1960) + random() * 3e12 + (random() < 0.5 ? 0.25 : 0.75));
  const U = ['millisecond', 'second', 'minute', 'hour', 'day', 'week', 'month', 'quarter', 'year', 'isoWeek', 'date', 'days', 'd', 'D', 'M', 'm', 'MS', 'y', 'Q', 'w', 'W', 'Hour', 'isoweek', 'weekday', 'dayOfYear', 'foo', ''];
  const W = [0, 1, 2, 3, 4, 5, 6, 7, 8, -1, 1.5, 6.9, true, false, '3', 'abc', null, undefined, NaN, 2.5];
  const A = [1, 2, -1, 0, 0.4, 0.5, 0.6, 1.5, 2.5, -0.5, -1.5, -2.5, 0.25, 0.001, 13, 100, 1000, 1e6, 1e9, '2', '1.5', ' 3 ', '', 'abc', 'P1D', 'PT1H', '1.02:03:04', NaN, Infinity, -Infinity, true, null, undefined];
  const UA = ['millisecond', 'second', 'minute', 'hour', 'day', 'week', 'month', 'quarter', 'year', 'isoWeek', 'date', 'days', 'd', 'M', 'm', 'y', 'Q', 'w', 'foo', '', null, undefined, '5', 5, true, false];
  const UD = ['millisecond', 'second', 'minute', 'hour', 'day', 'week', 'month', 'quarter', 'year', 'isoWeek', 'date', 'foo', 'days', 'd', 'M', undefined, null];
  const enc = (v) => {
    if (v === undefined) return {u: 1};
    if (typeof v === 'number' && !Number.isFinite(v)) return {n: String(v)};
    if (v instanceof Date) return {date: v.getTime()};
    if (Array.isArray(v)) return {arr: v.map(enc)};
    if (v !== null && typeof v === 'object') return {obj: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, enc(x)]))};
    return v;
  };
  const res = (f) => {
    try {
      const r = f();
      return typeof r === 'number' ? (Number.isNaN(r) ? 'NaN' : r) : enc(r);
    } catch (e) {
      return 'throw:' + e.constructor.name;
    }
  };
  const corpus = {T, U, W: W.map(enc), A: A.map(enc), UA: UA.map(enc), UD: UD.map(enc)};
  corpus.startOf = U.map((u) => T.map((t) => res(() => adapter.startOf(t, u))));
  corpus.endOf = U.map((u) => T.map((t) => res(() => adapter.endOf(t, u))));
  corpus.isoWeek = W.map((w) => T.map((t) => res(() => adapter.startOf(t, 'isoWeek', w))));
  const TA = T.filter((_, i) => i < 60 || i % 9 === 0);
  corpus.TA = TA;
  corpus.add = UA.map((u) => A.map((n) => TA.map((t) => res(() => adapter.add(t, n, u)))));
  const P = [];
  for (let i = 0; i < 1500; i++) {
    const x = Math.floor(utc(1900) + random() * (utc(2100) - utc(1900)));
    P.push([x, x - Math.floor(random() * 3 * 3.2e10 * (random() < 0.3 ? 0.01 : 1))]);
  }
  for (const x of monthEnds) for (const y of monthEnds) P.push([x, y]);
  for (let i = 0; i < 300; i++) P.push([T[Math.floor(random() * T.length)], T[Math.floor(random() * T.length)]]);
  P.push([1001.5, 0.2], [100000.5, 0], [-1.5, 1.5], [NaN, 0], [0, NaN], [Infinity, 0]);
  corpus.P = P.map(([x, y]) => [enc(x), enc(y)]);
  corpus.diff = UD.map((u) => P.map(([x, y]) => res(() => adapter.diff(x, y, u))));
  const V = [...PARSE, null, NaN, Infinity, -Infinity, true, false, 1.5, -1.5, 0, 1e300, new Date(Date.UTC(2015, 0, 1, 20)), new Date(NaN)];
  corpus.V = V.map(enc);
  corpus.fallback = [];
  corpus.parse = V.map((v) => {
    fallback = false;
    const r = res(() => adapter.parse(v));
    corpus.fallback.push(fallback);
    return r;
  });
  corpus.F = FORMAT_TIMES;
  corpus.formats = FORMATS;
  corpus.format = Object.fromEntries(FORMAT_KEYS.map((k) => [k, FORMAT_TIMES.map((t) => adapter.format(t, FORMATS[k]))]));
  const calls =
    U.length * T.length * 2 + W.length * T.length + UA.length * A.length * TA.length + UD.length * P.length + V.length;
  writeFileSync(file, JSON.stringify(corpus));
  console.log(`Wrote ${file}: ${calls} calls.`);
}
