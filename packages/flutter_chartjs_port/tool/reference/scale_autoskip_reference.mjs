// Original code, not ported from Chart.js: autoSkip reference generator.
//
// It writes test/port/core/scale_autoskip_reference.dart, the data of
// test/port/core/core.scale.autoskip_test.dart: the ticks that `autoSkip`
// keeps for a scale object `{options, _tickSize(), _length, _maxLength}` and
// a tick list. The header records the Node.js version, the V8 version and
// the architecture. The cases are fixed, so a rerun on the same Node.js
// writes the same file. Nothing in lib/ or test/ runs this script
// (porting-flow.md section 4).
//
// The script runs the pinned upstream source
// third_party/Chart.js/src/core/core.scale.autoskip.js with the type
// stripping of Node.js. A resolve hook maps the upstream `./x.js` imports to
// the `.ts` files. Check out the submodules first
// (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/scale_autoskip_reference.mjs
//
// The reference is V8 13.6 on arm64 (Chart.js ADR 0045). The script does not
// stop on another architecture.

import {execFileSync} from 'node:child_process';
import {existsSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

const SOURCE = new URL(
  '../../../../third_party/Chart.js/src/core/core.scale.autoskip.js',
  import.meta.url,
);
const OUT = fileURLToPath(
  new URL('../../test/port/core/scale_autoskip_reference.dart', import.meta.url),
);

if (!existsSync(fileURLToPath(SOURCE))) {
  console.error(
    `${fileURLToPath(SOURCE)} is missing. ` +
      'Check out the submodules with `dart run melos run upstream`.',
  );
  process.exit(1);
}

// The upstream sources import `../helpers/helpers.core.js` and the other
// modules with a `.js` suffix; the files on disk are `.ts`.
registerHooks({
  resolve(specifier, context, nextResolve) {
    if (
      specifier.endsWith('.js') &&
      context.parentURL?.includes('/third_party/Chart.js/')
    ) {
      const js = new URL(specifier, context.parentURL);
      const ts = new URL(specifier.replace(/\.js$/, '.ts'), context.parentURL);
      if (!existsSync(fileURLToPath(js)) && existsSync(fileURLToPath(ts))) {
        return nextResolve(ts.href, context);
      }
    }
    return nextResolve(specifier, context);
  },
});

const {autoSkip} = await import(SOURCE.href);

/** The Dart literal of a number. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return Number.isInteger(v) ? `${v}.0` : String(v);
}

/** The Dart literal of an option value. */
function dart(v) {
  if (v === null) return 'null';
  if (v === undefined) return 'undefined';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string') return `'${v}'`;
  if (Array.isArray(v)) return `<Object?>[${v.map(dart).join(', ')}]`;
  if (typeof v === 'object') {
    const entries = Object.keys(v).map((k) => `'${k}': ${dart(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

/** A deterministic sequence of numbers in [0, 1) (a linear congruence). */
function lcg(seed) {
  let state = seed >>> 0;
  return () => {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0;
    return state / 2 ** 32;
  };
}

const cases = [];

/**
 * Adds the case `name`: `count` ticks, with a major tick at each index of
 * `majors`, and the scale members.
 */
function add(name, {count, majors = [], options, tickSize, length, maxLength}) {
  const majorSet = new Set(majors);
  const ticks = [];
  for (let i = 0; i < count; i++) {
    ticks.push(majorSet.has(i) ? {value: i, major: true} : {value: i});
  }
  const scale = {
    options,
    _tickSize: () => tickSize,
    _length: length,
    _maxLength: maxLength,
  };
  const kept = autoSkip(scale, ticks).map((tick) => ticks.indexOf(tick));
  cases.push({name, count, majors, options, tickSize, length, maxLength, kept});
}

const plain = (ticks, offset = false) => ({offset, ticks});

// No major ticks.
add('no ticks', {
  count: 0,
  options: plain({major: {}}),
  tickSize: 20,
  length: 400,
  maxLength: 420,
});
add('all ticks fit', {
  count: 10,
  options: plain({major: {}}),
  tickSize: 20,
  length: 400,
  maxLength: 420,
});
add('a fractional spacing', {
  count: 30,
  options: plain({major: {}}),
  tickSize: 47,
  length: 400,
  maxLength: 420,
});
add('the chart length limits', {
  count: 30,
  options: plain({major: {}}),
  tickSize: 30,
  length: 400,
  maxLength: 200,
});
add('an offset scale', {
  count: 30,
  options: plain({major: {}}, true),
  tickSize: 30,
  length: 400,
  maxLength: 420,
});
add('a larger maxTicksLimit', {
  count: 300,
  options: plain({maxTicksLimit: 300, major: {}}),
  tickSize: 20,
  length: 400,
  maxLength: 420,
});
add('a smaller maxTicksLimit', {
  count: 300,
  options: plain({maxTicksLimit: 3, major: {}}),
  tickSize: 20,
  length: 400,
  maxLength: 420,
});
add('a maxTicksLimit of 0 is falsy', {
  count: 30,
  options: plain({maxTicksLimit: 0, major: {}}),
  tickSize: 40,
  length: 400,
  maxLength: 420,
});
add('a maxTicksLimit of null is falsy', {
  count: 30,
  options: plain({maxTicksLimit: null, major: {}}),
  tickSize: 40,
  length: 400,
  maxLength: 420,
});
add('a tick size of 0', {
  count: 30,
  options: plain({major: {}}),
  tickSize: 0,
  length: 400,
  maxLength: 420,
});
add('a NaN tick size', {
  count: 30,
  options: plain({major: {}}),
  tickSize: NaN,
  length: 400,
  maxLength: 420,
});
add('room for one tick', {
  count: 12,
  options: plain({major: {}}),
  tickSize: 300,
  length: 400,
  maxLength: 420,
});

// Major ticks.
add('majors disabled', {
  count: 30,
  majors: [0, 5, 10, 15, 20, 25],
  options: plain({major: {enabled: false}}),
  tickSize: 40,
  length: 400,
  maxLength: 420,
});
add('evenly spaced majors from 0', {
  count: 30,
  majors: [0, 6, 12, 18, 24],
  options: plain({major: {enabled: true}}),
  tickSize: 40,
  length: 400,
  maxLength: 420,
});
add('evenly spaced majors that equal the first index', {
  count: 36,
  majors: [6, 12, 18, 24, 30],
  options: plain({major: {enabled: true}}),
  tickSize: 30,
  length: 400,
  maxLength: 420,
});
add('evenly spaced majors with a large factor', {
  count: 120,
  majors: [12, 24, 36, 48, 60, 72, 84, 96, 108],
  options: plain({major: {enabled: true}}),
  tickSize: 20,
  length: 400,
  maxLength: 420,
});
add('unevenly spaced majors', {
  count: 40,
  majors: [3, 9, 17, 28, 35],
  options: plain({major: {enabled: true}}),
  tickSize: 40,
  length: 400,
  maxLength: 420,
});
add('a start before the first tick', {
  count: 40,
  majors: [2, 9, 16, 23, 30, 37],
  options: plain({major: {enabled: true}}),
  tickSize: 50,
  length: 400,
  maxLength: 420,
});
add('one major tick', {
  count: 25,
  majors: [7],
  options: plain({major: {enabled: true}}),
  tickSize: 50,
  length: 400,
  maxLength: 420,
});
add('one major tick at 0', {
  count: 25,
  majors: [0],
  options: plain({major: {enabled: true}}),
  tickSize: 50,
  length: 400,
  maxLength: 420,
});
add('too many majors', {
  count: 60,
  majors: [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42],
  options: plain({major: {enabled: true}}),
  tickSize: 80,
  length: 400,
  maxLength: 420,
});
add('too many majors with a fractional spacing', {
  count: 50,
  majors: [1, 4, 8, 11, 15, 18, 22, 25, 29, 32, 36, 39, 43],
  options: plain({major: {enabled: true}}),
  tickSize: 70,
  length: 400,
  maxLength: 420,
});
add('majors and a maxTicksLimit', {
  count: 48,
  majors: [0, 12, 24, 36],
  options: plain({maxTicksLimit: 6, major: {enabled: true}}),
  tickSize: 10,
  length: 400,
  maxLength: 420,
});

// A sweep over counts, tick sizes, limits and major patterns.
const random = lcg(20261019);
for (let k = 0; k < 160; k++) {
  const count = 1 + Math.floor(random() * 90);
  const tickSize = 5 + Math.floor(random() * 120);
  const length = 100 + Math.floor(random() * 500);
  const maxLength = length + Math.floor(random() * 60);
  const offset = random() < 0.3;
  const limitRoll = random();
  const maxTicksLimit =
    limitRoll < 0.6 ? undefined : 1 + Math.floor(random() * 15);
  const majorRoll = random();
  let majors = [];
  let enabled = false;
  if (majorRoll < 0.35) {
    enabled = true;
    const step = 2 + Math.floor(random() * 9);
    const first = Math.floor(random() * step);
    for (let i = first; i < count; i += step) majors.push(i);
  } else if (majorRoll < 0.55) {
    enabled = true;
    for (let i = 0; i < count; i++) if (random() < 0.15) majors.push(i);
  }
  const ticks =
    maxTicksLimit === undefined
      ? {major: {enabled}}
      : {maxTicksLimit, major: {enabled}};
  add(`sweep ${k}`, {
    count,
    majors,
    options: plain(ticks, offset),
    tickSize,
    length,
    maxLength,
  });
}

const body = cases
  .map(
    (c) =>
      `  (name: '${c.name}', count: ${c.count}, ` +
      `majors: <int>[${c.majors.join(', ')}], options: ${dart(c.options)}, ` +
      `tickSize: ${num(c.tickSize)}, length: ${num(c.length)}, ` +
      `maxLength: ${num(c.maxLength)}, kept: <int>[${c.kept.join(', ')}]),\n`,
  )
  .join('');

const usesUndefined = body.includes('undefined');

const out = `// Original code, not ported from Chart.js: autoSkip reference data.

// Generated by tool/reference/scale_autoskip_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/core/core.scale.autoskip.js at the pinned Chart.js. ${cases.length} cases.
${usesUndefined ? "\nimport 'package:flutter_chartjs_port/src/js/js_undefined.dart';\n" : ''}
/// The Node.js version that generated the data.
const String autoskipReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String autoskipReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String autoskipReferenceArch = '${process.arch}';

/// One call of \`autoSkip(scale, ticks)\`.
///
/// The ticks are \`{value: i}\` for \`i\` from 0 to \`count - 1\`, with
/// \`major: true\` at each index of \`majors\`. The scale is the object
/// \`{options, _tickSize: () => tickSize, _length: length, _maxLength:
/// maxLength}\`. \`kept\` lists the indexes of the ticks that the result
/// keeps, in order.
typedef AutoskipReferenceCase = ({
  String name,
  int count,
  List<int> majors,
  Map<String, Object?> options,
  double tickSize,
  double length,
  double maxLength,
  List<int> kept,
});

/// The cases of \`autoSkip\`.
const List<AutoskipReferenceCase> autoskipReference = [
${body}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${cases.length} cases to ${OUT}`);
