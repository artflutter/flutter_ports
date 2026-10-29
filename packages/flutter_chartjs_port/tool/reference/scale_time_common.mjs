// Original code, not ported from Chart.js: time scale generator code.
//
// The shared code of tool/reference/scale_time_reference.mjs and
// tool/reference/scale_timeseries_reference.mjs: the date adapter of the
// specs in Node.js, the fixed clock and the observations of a time scale.
// Nothing in lib/ or test/ runs this code (porting-flow.md section 4). See
// the header of tool/reference/scale_chart_common.mjs for the method of the
// scale reference tests.
//
// The date adapter. Chart.js has no date adapter. The specs load
// chartjs-adapter-moment 1.0.1 on moment 2.29.4 with moment-timezone 0.5.42
// (karma.conf.cjs:106-111, pnpm-lock.yaml:48-50, :123-128), and set the
// default zone 'Etc/UTC' (test/index.js:23). The port has its own default
// adapter with the same results (Chart.js ADR 0024). loadMomentAdapter()
// loads the three packages in the order of karma.conf.cjs:106-111:
// moment/min/moment.min.js and
// moment-timezone/builds/moment-timezone-with-data.min.js as globals, then
// chartjs-adapter-moment/dist/chartjs-adapter-moment.esm.js. A resolve hook
// maps its imports `chart.js` and `moment` to the module of the dist and to
// the global moment. Thus the adapter overrides `_adapters._date` of the
// same dist that the charts use. Then it calls
// `moment.tz.setDefault('Etc/UTC')`, as test/index.js:23 does. The Dart
// tests run in UTC too (test/flutter_test_config.dart). The process zone is
// UTC as well (the module sets TZ), because the moment fallback and the
// current date read it.
//
// The clock. `Date.now()` gives the fixed time NOW (2021-06-15T12:34:56.789Z)
// in the generators: the time scale reads it for a chart without data
// (scale.time.js:342-343), and moment reads it for the current date of a
// parse with a format. The Dart tests run each chart in `withClock` with
// the same time (Chart.js ADR 0024, section 7).
//
// The display formats. The labels use the moment FORMATS of
// chartjs-adapter-moment. The Dart adapter has ICU patterns with the same
// en_US text (Chart.js ADR 0024, section 6). A format that a config or an
// observation gives itself is a string with the same text in both: 'HH:mm'
// and 'MMM'.
//
// How to run a generator, from packages/flutter_chartjs_port, with the darwin-arm64
// build of Node.js v24.22.1 (Chart.js ADR 0045) and the Dart SDK on the PATH:
//
//   npm install --no-save --prefix <scratch> moment@2.29.4 \
//     moment-timezone@0.5.42 chartjs-adapter-moment@1.0.1
//   CHARTJS_DIST=<build>/dist/chart.js \
//   MOMENT_NODE_MODULES=<scratch>/node_modules \
//     node tool/reference/scale_time_reference.mjs
//
// <build> is the build of the pinned Chart.js (see the header of
// tool/reference/scale_chart_common.mjs). The two paths can also be the
// first and the second argument. The generator stops unless the three
// packages have the versions of the Chart.js lockfile. The output file
// records the sha256 of each loaded file.

import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {existsSync, readFileSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {join} from 'node:path';
import {pathToFileURL} from 'node:url';
import vm from 'node:vm';

// The process zone of the moment fallback and of the current date
// (test/index.js runs in a browser with any zone, but sets the default zone
// of moment-timezone; the fallback is not part of the reference).
process.env.TZ = 'UTC';

/** The fixed time of `Date.now()`: 2021-06-15T12:34:56.789Z. */
export const NOW = Date.UTC(2021, 5, 15, 12, 34, 56, 789);

/** Writes [message] to stderr and stops the process. */
function stop(message) {
  console.error(message);
  process.exit(1);
}

/** The versions of the Chart.js lockfile (pnpm-lock.yaml:48-50, :123-128). */
const VERSIONS = {
  moment: '2.29.4',
  'moment-timezone': '0.5.42',
  'chartjs-adapter-moment': '1.0.1',
};

/** The files that loadMomentAdapter() loads, by package. */
const FILES = {
  moment: 'moment/min/moment.min.js',
  'moment-timezone': 'moment-timezone/builds/moment-timezone-with-data.min.js',
  'chartjs-adapter-moment': 'chartjs-adapter-moment/dist/chartjs-adapter-moment.esm.js',
};

/**
 * The versions and the sha256 of the loaded files, after
 * loadMomentAdapter(): `{package: {version, file, sha256}}`.
 */
const loadedFiles = {};

/**
 * Loads the date adapter of the specs into the chart.js dist [C] (see the
 * header), sets the default zone of moment to 'Etc/UTC' and fixes
 * `Date.now()` at NOW. loadChartJs() must run first.
 *
 * The node_modules folder comes from the environment variable
 * MOMENT_NODE_MODULES or from the second argument of the process. The
 * first argument (or CHARTJS_DIST) is the dist of loadChartJs().
 */
export async function loadMomentAdapter(C) {
  const nodeModules = process.env.MOMENT_NODE_MODULES ?? process.argv[3];
  if (!nodeModules || !existsSync(nodeModules)) {
    stop(
      'Give the node_modules folder of moment, moment-timezone and ' +
        'chartjs-adapter-moment as the second argument, or set MOMENT_NODE_MODULES.',
    );
  }
  for (const [name, version] of Object.entries(VERSIONS)) {
    const file = join(nodeModules, name, 'package.json');
    if (!existsSync(file)) stop(`${file} does not exist.`);
    const found = JSON.parse(readFileSync(file, 'utf8')).version;
    if (found !== version) stop(`${name} is ${found}; the Chart.js lockfile gives ${version}.`);
    const path = join(nodeModules, FILES[name]);
    if (!existsSync(path)) stop(`${path} does not exist.`);
    loadedFiles[name] = {
      version,
      file: FILES[name],
      sha256: createHash('sha256').update(readFileSync(path)).digest('hex'),
    };
  }
  if (new Date(Date.UTC(2021, 6, 1)).getTimezoneOffset() !== 0) {
    stop('The process zone is not UTC.');
  }

  // karma.conf.cjs:106-107: moment and moment-timezone as globals.
  globalThis.window = globalThis;
  for (const name of ['moment', 'moment-timezone']) {
    const path = join(nodeModules, FILES[name]);
    vm.runInThisContext(readFileSync(path, 'utf8'), {filename: path});
  }
  const moment = globalThis.moment;
  moment.suppressDeprecationWarnings = true;

  const dist = process.argv[2] ?? process.env.CHARTJS_DIST;
  const chartModule = pathToFileURL(dist).href;
  const momentModule =
    'data:text/javascript,' + encodeURIComponent('export default globalThis.moment;');
  registerHooks({
    resolve(specifier, context, next) {
      if (specifier === 'chart.js') return {url: chartModule, shortCircuit: true};
      if (specifier === 'moment') return {url: momentModule, shortCircuit: true};
      return next(specifier, context);
    },
  });
  await import(pathToFileURL(join(nodeModules, FILES['chartjs-adapter-moment'])).href);
  if (C._adapters._date.prototype._id !== 'moment') {
    stop('chartjs-adapter-moment did not override the adapter of the dist.');
  }

  // test/index.js:23.
  moment.tz.setDefault('Etc/UTC');
  Date.now = () => NOW;
  return moment;
}

/**
 * Appends the adapter files and NOW to the Dart file [outPath] of
 * writeReference() with the prefix [name], and formats it again.
 */
export function appendAdapterInfo(outPath, name) {
  const entries = Object.entries(loadedFiles)
    .map(
      ([pkg, {version, file, sha256}]) =>
        `  '${pkg}': (version: '${version}', file: '${file}', sha256: '${sha256}'),\n`,
    )
    .join('');
  const out =
    readFileSync(outPath, 'utf8') +
    `
/// The date adapter of the generator: the packages of the Chart.js lockfile,
/// with the loaded file and its sha256.
const Map<String, ({String version, String file, String sha256})>
    ${name}ReferenceAdapter = {
${entries}};

/// The fixed time of \`Date.now()\` in the generator, in ms since the epoch.
const double ${name}ReferenceNow = ${NOW};
`;
  writeFileSync(outPath, out);
  execFileSync('dart', ['format', outPath], {stdio: 'inherit'});
}

/** The middle of the range of the scale [s]. */
const middle = (s) => (s.min + s.max) / 2;

/** The values of the parse probes of timeObservations. */
export const PARSE_PROBES = [
  '2021-03-04',
  '2021-03-04T05:06:07',
  '2021-03-04T05:06:07.890Z',
  '2021-03-04T05:06:07+02:00',
  '2021-W10-3',
  '2021-063',
  'Thu, 04 Mar 2021 05:06:07 +0000',
  '/Date(1614834367000)/',
  'garbage',
  '',
  1614834367000,
  0,
  -1,
  NaN,
  Infinity,
  null,
  undefined,
  true,
];

/**
 * The observations of a time scale [s] of the dist [C], after the
 * observations of `observe`. The Dart tests give the same keys with the
 * same calls. A scale of another type gives none.
 *
 * - `unit`: `_unit`. `_majorUnit` stays private in the port (Chart.js ADR
 *   0025, section 6): the major flags and the labels of the ticks show it.
 * - `offsets`: `[start, end, factor]` of `_offsets`.
 * - `dataTimestamps`, `labelTimestamps`: copies of getDataTimestamps() and
 *   getLabelTimestamps() after the layout (the caches).
 * - `decimalForValue`: getDecimalForValue of min, max, the middle, min - 1
 *   day, max + 1 day, null, undefined, NaN, 0, false, the middle as a
 *   string, and true.
 * - `pixelForValue`: getPixelForValue of null, undefined, NaN, the middle as
 *   a string, and true.
 * - `valuesForPixels`: getValueForPixel of the start - 20, of the start +
 *   0.3 of the length, and of the end + 20, along the axis.
 * - `labelForValue`: getLabelForValue of min, max, the middle and null.
 * - `format`: format() of min and max, and format() of min with 'HH:mm'.
 * - `parse`: parse of PARSE_PROBES and of the Date 2021-03-04T05:06:07.008Z,
 *   when the scale has no `time.parser` option. Else an empty list: a
 *   moment format parses other strings than an ICU pattern.
 */
export function timeObservations(C) {
  return (s) => {
    if (!(s instanceof C.TimeScale)) return {};
    const horizontal = s.isHorizontal();
    const start = horizontal ? s.left : s.top;
    const end = horizontal ? s.right : s.bottom;
    const mid = middle(s);
    const day = 86400000;
    const parse = s.options.time.parser
      ? []
      : [...PARSE_PROBES, new Date(Date.UTC(2021, 2, 4, 5, 6, 7, 8))].map((v) => s.parse(v));
    return {
      unit: s._unit,
      offsets: [s._offsets.start, s._offsets.end, s._offsets.factor],
      dataTimestamps: [...s.getDataTimestamps()],
      labelTimestamps: [...s.getLabelTimestamps()],
      decimalForValue: [
        s.min,
        s.max,
        mid,
        s.min - day,
        s.max + day,
        null,
        undefined,
        NaN,
        0,
        false,
        String(mid),
        true,
      ].map((v) => s.getDecimalForValue(v)),
      pixelForValue: [null, undefined, NaN, String(mid), true].map((v) => s.getPixelForValue(v)),
      valuesForPixels: [start - 20, start + 0.3 * (end - start), end + 20].map((p) =>
        s.getValueForPixel(p),
      ),
      labelForValue: [s.min, s.max, mid, null].map((v) => s.getLabelForValue(v)),
      format: [s.format(s.min), s.format(s.max), s.format(s.min, 'HH:mm')],
      parse,
    };
  };
}
