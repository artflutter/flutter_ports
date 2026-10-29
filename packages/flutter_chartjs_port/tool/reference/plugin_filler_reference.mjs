// Original code, not ported from Chart.js: filler plugin reference generator.
//
// It writes test/port/plugins/plugin.filler/plugin_filler_reference.dart,
// the data of test/port/plugins/plugin.filler/index_test.dart: real charts
// with the filler plugin of a build of the pinned Chart.js (Chart.js ADR
// 0041, section 3, and Chart.js ADR 0040). See the headers of
// tool/reference/plugin_chart_common.mjs,
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The generator registers the built-in components and the seven plugins
// (registerBuiltins: src/index.umd.ts:28, then
// `defaults.plugins.colors.enabled = false`, test/index.js:25-28). Each case
// of items 1-11 is a unit case (Chart.js ADR 0041, section 4):
// `options.plugins` is unitPlugins(['filler'], ...), so each other plugin
// is `false`, as in wave 2, when the Dart test file registered only the
// filler plugin. The full cases of item 12 have the default plugin options.
//
// The observation of a case is the controller observation without the hit
// matrix, `boxes`, and `plugins.filler`: for each dataset, `meta.$filler`
// as Dart `null`, or `{visible, index, fill, axis, scale}` with the
// resolved `fill` and the id of the scale (Chart.js ADR 0041, section 3
// item 4). The draw calls of a case have the fill calls of the filler
// hooks in their upstream order.
//
// The probe `targets` gives, for each dataset with a source, the target of
// `_getTarget(source)` after the draw (filler spec section 4.2): `'shape'`,
// Dart `null`, `{kind: 'simpleArc', x, y, radius}`, `{kind: 'element'}`
// for another element, or `{kind: 'line', loop, fullLoop, count, points}`
// with the points read by name (`x`, `y`, `angle`; `undefined` stays). A
// line of more than 60 points has no `points`. The bundle does not export
// `_getTarget`. Thus the generator imports the pinned source files
// src/plugins/plugin.filler/filler.target.js and simpleArc.js with the type
// stripping of Node.js, as theme_light_reference.mjs does: a resolve hook
// maps the `./x.js` imports to the `.ts` files and `@kurkle/color` to
// third_party/kurkle-color/src/index.esm.js. The source functions read the
// chart of the bundle by name only. The Dart test calls `getTarget` of
// filler.target.dart.
//
// The cases (Chart.js ADR 0041, section 3 item 7; filler spec section 4.2):
// 1. The fills `origin`, `start`, `end`, `{value}`, `true`, `false`, `'-1'`,
//    `'+1'`, a number, `stack` and `shape` (one color) on line charts.
// 2. Lines with gaps (with and without `spanGaps`), `stepped`, a tension,
//    `cubicInterpolationMode: 'monotone'` and `indexAxis: 'y'`.
// 3. `above` and `below` on `x` and on `y` (the path clips) and between two
//    lines, `clip: false`, each `drawTime`, `propagate` `false` and `true`
//    with a hidden target and the step that shows it.
// 4. The list result of `interpolate`: a stack fill above a line with a
//    `segment.borderColor` style and above a line whose `x` goes back. Both
//    draw no stacked fill (Chart.js ADR 0040, section 2). The same chart
//    without the style draws one fill.
// 5. A stack fill on a scatter chart, with no line below.
// 6. An empty target with `above` and `below`, index axis `x` and `y`:
//    `first()` gives `0` upstream, and the hook calls `lineTo(NaN, clipY)`.
// 7. `offset: true` with `min` and `max` on a category scale (#12283).
// 8. A line of 120 points with `parsing: false` on a linear `x`. The cases
//    with the decimation plugin are full cases (below).
// 9. Radar charts on a polygon grid: `origin`, `start`, `end`, `{value}`, a
//    gap (the `'angle'` interpolate), `fill: 1` (`evenodd`), `reverse`, a
//    negative minimum, and `r` `min` and `max` below 0 and above 0 (the
//    three branches of `getBaseValue`, core.scale.js:950-955).
// 10. Radar charts on a circular grid, with and without a gap (simpleArc).
// 11. Throws (TypeError): `shape` with two colors, and a radar fill on a
//     chart without a layout (an inline plugin whose `beforeLayout` returns
//     `false`). Both throw in `new Chart`. The calls before the throw are in
//     the data of filler_target_reference.mjs.
// 12. The full cases of Chart.js ADR 0041, section 4 items 2-3 (names that
//     start with `full:`): the default plugin options, so each plugin
//     runs. A radar with the colors plugin on (the fill color of the
//     palette), and the decimation with a fill (filler spec section 4.2
//     item 8): `lttb` with `fill: 'origin'` (60 items to 12), and
//     `min-max` with `fill: 'stack'` on a canvas of 100 x 100 (64 items in
//     16 clusters of 4, each cluster in one pixel column of
//     plugin.decimation.js:95-97, so the branch :99-133 runs).
//
// The Dart test file runs the cases two times: unthemed, and with the
// light preset (theming.md section 8 test 3, Chart.js ADR 0042).
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045):
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/plugin_filler_reference.mjs
//
// The path can also be the first argument. The script also stops unless
// third_party/kurkle-color is at the `commit` of its entry in
// tool/port_sources.yaml, with no change in src/.

import {execFileSync} from 'node:child_process';
import {existsSync, readFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

import {
  loadChartJs,
  plain,
  registerBuiltins,
  runPluginCase,
  unitPlugins,
  writeControllerReference,
} from './plugin_chart_common.mjs';
import {named} from './controller_chart_common.mjs';

const OUT = fileURLToPath(
  new URL(
    '../../test/port/plugins/plugin.filler/plugin_filler_reference.dart',
    import.meta.url,
  ),
);

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const SRC = new URL('Chart.js/src/', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);

/**
 * Stops unless third_party/kurkle-color is at the `commit` of its entry in
 * tool/port_sources.yaml, with no change in src/. loadChartJs checks
 * third_party/Chart.js. The read of the commit is the one of checkPin in
 * theme_light_reference.mjs.
 */
function checkKurklePin() {
  const sources = fileURLToPath(new URL('../port_sources.yaml', import.meta.url));
  const entries = readFileSync(sources, 'utf8').split(/^ {2}- header: /m);
  const entry = entries.find((e) => e.startsWith('"@kurkle/color"\n'));
  const commit = entry?.match(/^ {6}commit: "?([0-9a-f]{40})"?\s*$/m)?.[1];
  if (!commit) {
    console.error(`${sources} has no commit for @kurkle/color.`);
    process.exit(1);
  }
  const checkout = fileURLToPath(new URL('kurkle-color', THIRD_PARTY));
  const git = (...args) =>
    execFileSync('git', ['-C', checkout, ...args], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    }).trim();
  if (git('rev-parse', 'HEAD') !== commit || git('status', '--porcelain', '--', 'src') !== '') {
    console.error(`${checkout} is not at the pin ${commit} or has changes in src/.`);
    process.exit(1);
  }
}

const C = await loadChartJs();
registerBuiltins(C);
checkKurklePin();

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === '@kurkle/color' && context.parentURL?.includes('/third_party/Chart.js/')) {
      return nextResolve(KURKLE.href, context);
    }
    // The upstream sources import `../helpers/helpers.core.js` and the
    // other modules with a `.js` suffix; most files on disk are `.ts`.
    if (specifier.endsWith('.js') && context.parentURL?.includes('/third_party/Chart.js/')) {
      const js = new URL(specifier, context.parentURL);
      const ts = new URL(specifier.replace(/\.js$/, '.ts'), context.parentURL);
      if (!existsSync(fileURLToPath(js)) && existsSync(fileURLToPath(ts))) {
        return nextResolve(ts.href, context);
      }
    }
    return nextResolve(specifier, context);
  },
});

const {_getTarget} = await import(
  new URL('plugins/plugin.filler/filler.target.js', SRC).href
);
const {simpleArc} = await import(new URL('plugins/plugin.filler/simpleArc.js', SRC).href);

/**
 * The observer `plugins.filler`: for each dataset, `meta.$filler` as
 * `null`, or `{visible, index, fill, axis, scale}` with the plain resolved
 * `fill` and the id of the scale.
 */
function observeFiller(chart) {
  return chart.data.datasets.map((_, i) => {
    const source = chart.getDatasetMeta(i).$filler;
    if (!source) return source;
    return {
      visible: source.visible,
      index: source.index,
      fill: plain(source.fill),
      axis: source.axis,
      scale: source.scale?.id,
    };
  });
}

/** The most points of a target line in the data. */
const MAX_POINTS = 60;

/** The description of the target [target] of `_getTarget`. */
function describeTarget(target) {
  if (target === true) return 'shape';
  if (!target) return null;
  if (target instanceof simpleArc) {
    return {kind: 'simpleArc', x: target.x, y: target.y, radius: target.radius};
  }
  if (target.segments === undefined) return {kind: 'element'};
  const points = target.points;
  return {
    kind: 'line',
    loop: target._loop,
    fullLoop: target._fullLoop,
    count: points.length,
    points:
      points.length > MAX_POINTS ? undefined : points.map((p) => [p.x, p.y, p.angle]),
  };
}

/** The probe `targets`: the target of each source after the draw. */
const targets = named('targets', (chart) =>
  chart.data.datasets.map((_, i) => {
    const source = chart.getDatasetMeta(i).$filler;
    return source ? describeTarget(_getTarget(source)) : null;
  }),
);

/** The segment style of the list-result case (filler spec 4.2 item 4). */
const segStyle = named('segStyle', (ctx) => (ctx.p0DataIndex < 2 ? 'red' : 'blue'));

/** The inline plugin `beforeLayout` of the case without a layout. */
const noLayout = named('noLayout', () => false);

const LABELS = ['a', 'b', 'c', 'd', 'e', 'f'];
const BLUE = 'rgba(0, 0, 255, 0.3)';
const RED = 'rgba(255, 0, 0, 0.3)';
const GREEN = 'rgba(0, 128, 0, 0.3)';
const A = [3, 5, 2, 6, 4, 7];
const B = [1, 2, 1, 3, 2, 4];
const MIXED = [-2, 1, -3, 2, -1, 3];

/** A dataset with the data [data], a border and a blue background. */
const ds = (data, extra = {}) => ({data, borderColor: 'black', backgroundColor: BLUE, ...extra});

/**
 * A chart of the type [type] with the [datasets], the chart [options] and
 * the filler options [filler]. `options.plugins` is the unit form.
 */
function chart(datasets, {type = 'line', labels = LABELS, options = {}, filler} = {}) {
  return {
    type,
    data: labels === null ? {datasets} : {labels, datasets},
    options: {
      ...options,
      plugins: unitPlugins(['filler'], filler === undefined ? {} : {filler}),
    },
  };
}

/** runPluginCase with the observer of the filler and the probe targets. */
const fillerCase = (name, config, opts = {}) =>
  runPluginCase(name, config, {
    ...opts,
    observers: {filler: observeFiller},
    extras: {targets},
  });

const radar = (datasets, scale = {}) =>
  chart(datasets, {type: 'radar', options: {scales: {r: scale}}});

const many = Array.from({length: 120}, (_, i) => ({x: i, y: (i * 37) % 23}));

const cases = [
  // 1. The fill modes on line charts.
  fillerCase('fill origin', chart([ds(MIXED, {fill: 'origin'})])),
  fillerCase('fill start', chart([ds(A, {fill: 'start'})])),
  fillerCase('fill end', chart([ds(A, {fill: 'end'})])),
  fillerCase('fill value', chart([ds(A, {fill: {value: 4}})])),
  fillerCase('fill true', chart([ds(MIXED, {fill: true})])),
  fillerCase('fill false', chart([ds(A, {fill: false})])),
  fillerCase('fill -1', chart([ds(B), ds(A, {fill: '-1', backgroundColor: RED})])),
  fillerCase('fill +1', chart([ds(A, {fill: '+1'}), ds(B)])),
  fillerCase(
    'fill as a dataset index',
    chart([ds(A, {fill: 2}), ds(MIXED), ds(B, {backgroundColor: GREEN})]),
  ),
  fillerCase(
    'fill stack',
    chart(
      [
        ds(B, {fill: 'origin'}),
        ds(A, {fill: 'stack', backgroundColor: RED}),
        ds(B, {fill: 'stack', backgroundColor: GREEN}),
      ],
      {options: {scales: {y: {stacked: true}}}},
    ),
  ),
  fillerCase('fill shape', chart([ds(MIXED, {fill: 'shape'})])),

  // 2. Gaps, stepped, curves and the index axis y.
  fillerCase('a gap without spanGaps', chart([ds([3, 5, null, 6, 4, 7], {fill: 'origin'})])),
  fillerCase(
    'a gap with spanGaps',
    chart([ds([3, 5, null, 6, null, 7], {fill: 'origin', spanGaps: true})]),
  ),
  fillerCase('stepped', chart([ds(MIXED, {fill: 'origin', stepped: true})])),
  fillerCase(
    'a tension with fill -1',
    chart([ds(B, {tension: 0.4}), ds(A, {fill: '-1', tension: 0.4, backgroundColor: RED})]),
  ),
  fillerCase(
    'monotone',
    chart([ds(MIXED, {fill: 'origin', cubicInterpolationMode: 'monotone'})]),
  ),
  fillerCase(
    'indexAxis y with fill origin',
    chart([ds(MIXED, {fill: 'origin'})], {options: {indexAxis: 'y'}}),
  ),
  fillerCase(
    'indexAxis y with fill -1',
    chart([ds(B), ds(A, {fill: '-1', backgroundColor: RED})], {options: {indexAxis: 'y'}}),
  ),

  // 3. above and below, clip, drawTime and propagate.
  fillerCase(
    'above and below on x',
    chart([ds(MIXED, {fill: {target: 'origin', above: RED, below: GREEN}})]),
  ),
  fillerCase(
    'above and below on y',
    chart([ds(MIXED, {fill: {target: 'origin', above: RED, below: GREEN}})], {
      options: {indexAxis: 'y'},
    }),
  ),
  fillerCase(
    'above and below between two lines',
    chart([ds(B), ds(MIXED, {fill: {target: '-1', above: RED, below: GREEN}})]),
  ),
  fillerCase('clip false', chart([ds(MIXED, {fill: 'origin', clip: false})])),
  fillerCase(
    'drawTime beforeDraw',
    chart([ds(B, {fill: 'origin'}), ds(A, {fill: 0, backgroundColor: RED})], {
      filler: {drawTime: 'beforeDraw'},
    }),
  ),
  fillerCase(
    'drawTime beforeDatasetsDraw',
    chart([ds(B, {fill: 'origin'}), ds(A, {fill: 0, backgroundColor: RED})], {
      filler: {drawTime: 'beforeDatasetsDraw'},
    }),
  ),
  fillerCase(
    'propagate false with a hidden target',
    chart(
      [
        ds(B, {fill: 'origin'}),
        ds(A, {fill: '-1', hidden: true, backgroundColor: GREEN}),
        ds(MIXED, {fill: '-1', backgroundColor: RED}),
      ],
      {filler: {propagate: false}},
    ),
    {steps: [['setDatasetVisibility', 1, true]]},
  ),
  fillerCase(
    'propagate true with a hidden target',
    chart(
      [
        ds(B, {fill: 'origin'}),
        ds(A, {fill: '-1', hidden: true, backgroundColor: GREEN}),
        ds(MIXED, {fill: '-1', backgroundColor: RED}),
      ],
      {filler: {propagate: true}},
    ),
    {steps: [['setDatasetVisibility', 1, true]]},
  ),

  // 4. The list result of interpolate.
  fillerCase(
    'stack above a line with segment styles',
    chart([
      ds([1, 2, 3, 2, 1], {fill: false, segment: {borderColor: segStyle}}),
      ds([3, 4, 5, 4, 3], {fill: 'stack', backgroundColor: RED}),
    ]),
  ),
  fillerCase(
    'stack above a line whose x goes back',
    chart(
      [
        ds(
          [
            {x: 0, y: 1},
            {x: 4, y: 2},
            {x: 2, y: 3},
            {x: 6, y: 1},
          ],
          {fill: false},
        ),
        ds(
          [
            {x: 0, y: 3},
            {x: 3, y: 4},
            {x: 6, y: 5},
          ],
          {fill: 'stack', backgroundColor: RED},
        ),
      ],
      {labels: null, options: {scales: {x: {type: 'linear'}}}},
    ),
  ),
  fillerCase(
    'stack above a line without segment styles',
    chart([
      ds([1, 2, 3, 2, 1], {fill: false}),
      ds([3, 4, 5, 4, 3], {fill: 'stack', backgroundColor: RED}),
    ]),
  ),

  // 5. A stack fill on a scatter chart.
  fillerCase(
    'stack on a scatter chart',
    chart(
      [
        ds(
          [
            {x: 0, y: 1},
            {x: 2, y: 3},
            {x: 4, y: 2},
          ],
          {fill: 'stack', showLine: true},
        ),
      ],
      {type: 'scatter', labels: null},
    ),
  ),

  // 6. An empty target with above and below.
  fillerCase(
    'an empty target on x',
    chart([ds([1, 2, 3, 2, 1], {fill: {target: 1, above: RED, below: GREEN}}), ds([])]),
  ),
  fillerCase(
    'an empty target on y',
    chart([ds([1, 2, 3, 2, 1], {fill: {target: 1, above: RED, below: GREEN}}), ds([])], {
      options: {indexAxis: 'y'},
    }),
  ),

  // 7. #12283: the clip to the bounds of the index scale.
  fillerCase(
    'offset with min and max on a category scale',
    chart([ds(A, {fill: 'origin'})], {
      options: {scales: {x: {offset: true, min: 'b', max: 'e'}}},
    }),
  ),

  // 8. Many points.
  fillerCase(
    '120 points without parsing',
    chart([ds(many, {fill: 'origin', pointRadius: 0})], {
      labels: null,
      options: {parsing: false, scales: {x: {type: 'linear'}}},
    }),
  ),

  // 9. Radar charts on a polygon grid.
  fillerCase('radar origin', radar([ds([1, 2, 3, 2, 1, 2], {fill: 'origin'})], {min: -1})),
  fillerCase('radar start', radar([ds([1, 2, 3, 2, 1, 2], {fill: 'start'})])),
  fillerCase('radar end', radar([ds([1, 2, 3, 2, 1, 2], {fill: 'end'})])),
  fillerCase('radar value', radar([ds([1, 2, 3, 2, 1, 2], {fill: {value: 2}})])),
  fillerCase(
    'radar with a gap',
    radar([ds([1, 2, null, 2, 1, 2], {fill: 'origin'})], {beginAtZero: true}),
  ),
  fillerCase(
    'radar fill 1',
    radar([ds([3, 4, 5, 4, 3, 4], {fill: 1}), ds([1, 2, 1, 2, 1, 2], {backgroundColor: RED})], {
      beginAtZero: true,
    }),
  ),
  fillerCase('radar reverse', radar([ds([1, 2, 3, 2, 1, 2], {fill: 'start'})], {reverse: true})),
  fillerCase(
    'radar with a negative minimum',
    radar([ds([-3, 2, -1, 4, 1, -2], {fill: 'origin'})]),
  ),
  fillerCase(
    'radar with r min and max',
    radar([ds([-4, -2, -3, -2, -4, -3], {fill: 'origin'})], {min: -5, max: -1}),
  ),
  fillerCase(
    'radar with a positive r min',
    radar([ds([1, 2, 3, 2, 1, 2], {fill: 'origin'})], {min: 1, max: 4}),
  ),

  // 10. Radar charts on a circular grid.
  fillerCase(
    'radar circular',
    radar([ds([1, 2, 3, 2, 1, 2], {fill: 'origin'})], {grid: {circular: true}, beginAtZero: true}),
  ),
  fillerCase(
    'radar circular with a gap',
    radar([ds([1, 2, null, 2, 1, 2], {fill: 'origin'})], {
      grid: {circular: true},
      beginAtZero: true,
    }),
  ),

  // 11. Throws.
  fillerCase(
    'throws: shape with two colors',
    chart([ds(MIXED, {fill: {target: 'shape', above: RED, below: GREEN}})]),
  ),
  fillerCase('throws: radar without a layout', {
    ...radar([ds([1, 2, 3, 2, 1, 2], {fill: 'origin'})]),
    plugins: [{id: 'noLayout', beforeLayout: noLayout}],
  }),
];

// ---------------------------------------------------------------------------
// The full cases of Chart.js ADR 0041, section 4 item 2 (wave 4): the
// default plugin options, so each registered plugin runs (no unitPlugins).
// A full case exists only where another plugin changes the result (section
// 4 item 3).

/** [n] items `{x: i, y: f(i)}` for the decimation. */
const series = (n, f) => Array.from({length: n}, (_, i) => ({x: i, y: f(i)}));

/**
 * 64 items in 16 clusters of 4, the y values plus [dy]: the x values of a
 * cluster are 0.25 apart, and the clusters are 10 apart. On a canvas of 100
 * pixels, each cluster is in one pixel column of minMaxDecimation
 * (plugin.decimation.js:95-97), so the min/max branch (:99-133) runs. The
 * data of `clustered()` of plugin_decimation_reference.mjs.
 */
const clustered = (dy) =>
  Array.from({length: 64}, (_, i) => ({
    x: Math.floor(i / 4) * 10 + (i % 4) * 0.25,
    y: ((i * 37) % 23) - 5 + dy,
  }));

/**
 * A line chart with the [datasets], `parsing: false`, a linear `x` and the
 * decimation options [decimation] (`threshold: 20`). No unitPlugins.
 */
const decimated = (datasets, decimation) => ({
  type: 'line',
  data: {datasets},
  options: {
    parsing: false,
    scales: {x: {type: 'linear'}},
    plugins: {decimation: {enabled: true, threshold: 20, ...decimation}},
  },
});

cases.push(
  fillerCase('full: radar with colors on', {
    type: 'radar',
    data: {
      labels: LABELS.slice(0, 5),
      datasets: [{data: [3, 5, 2, 6, 4]}, {data: [1, 2, 1, 3, 2]}],
    },
    options: {plugins: {colors: {enabled: true}}},
  }),
  fillerCase(
    'full: lttb with fill origin',
    decimated([ds(series(60, (i) => ((i * 37) % 23) - 8), {fill: 'origin', pointRadius: 0})], {
      algorithm: 'lttb',
      samples: 12,
    }),
  ),
  fillerCase(
    'full: min-max with fill stack',
    decimated(
      [
        ds(clustered(0), {pointRadius: 0}),
        ds(clustered(5), {
          fill: 'stack',
          backgroundColor: RED,
          pointRadius: 0,
        }),
      ],
      {algorithm: 'min-max'},
    ),
    {options: {canvas: {width: 100, height: 100}}},
  ),
);

writeControllerReference(OUT, 'pluginFiller', cases, {title: 'filler plugin'});
