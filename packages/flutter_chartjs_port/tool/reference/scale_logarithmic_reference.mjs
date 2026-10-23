// Original code, not ported from Chart.js: logarithmic scale reference generator.
//
// It writes test/port/scales/scale_logarithmic_reference.dart, the data of
// test/port/scales/scale.logarithmic_test.dart: real charts with the
// logarithmic scale of a build of the pinned Chart.js (see the header of
// tool/reference/scale_chart_common.mjs for the method, the usage and the
// limits).
//
// Two cartesian test controllers:
// - `logTest`: the logarithmic scale on both axes.
// - `logValueTest`: the category scale on the index axis and the
//   logarithmic scale on the value axis, as a line chart of upstream.
// The Dart test has the same controllers. The cases also port the configs of
// the fixtures of test/fixtures/scale.logarithmic/ and of some charts of
// test/specs/scale.logarithmic.tests.js.
//
// The action cases (runAction) change the chart after its creation and call
// chart.update(). The Dart test has the same actions (_actions).
//
// For each case, the script records the observations of `observe` and the
// calls of one draw. For a logarithmic scale, the observations also have
// start, end, the significand of each tick, and the results of
// getLabelForValue, parse, getPixelForValue and getValueForPixel for fixed
// values (logObservations).
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   node tool/reference/scale_logarithmic_reference.mjs \
//     <build>/dist/chart.js
//
// or with the environment variable CHARTJS_DIST.

import {fileURLToPath} from 'node:url';

import {
  cartesianTestController,
  drawCalls,
  loadChartJs,
  makeChart,
  named,
  observe,
  registerBuiltins,
  runCase,
  writeReference,
} from './scale_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/scales/scale_logarithmic_reference.dart', import.meta.url),
);

const C = await loadChartJs();

/** The cartesian test controller with the logarithmic scale on both axes. */
const LogTestController = cartesianTestController('logTest', {
  scales: {_index_: {type: 'logarithmic'}, _value_: {type: 'logarithmic'}},
});

/** The cartesian test controller with a logarithmic value axis. */
const LogValueTestController = cartesianTestController('logValueTest', {
  scales: {_index_: {type: 'category'}, _value_: {type: 'logarithmic'}},
});

registerBuiltins(C, LogTestController, LogValueTestController);

/**
 * The observations of a logarithmic scale [s], after the observations of
 * `observe`. The Dart test gives the same keys with the same calls.
 *
 * - `start`, `end`: the values at the ends of the axis.
 * - `significands`: the significand of each tick.
 * - `labelForValue`: getLabelForValue of min, max, 1234.5, 0.000125,
 *   98765.4321, undefined, null, '7.5', true and 0.
 * - `parse`: parse of null, undefined, NaN, Infinity, -Infinity, 12, -5, 0,
 *   -0, '12.5', '0', 'abc', '', true, false, [7] and {}. The 0 values set
 *   `_zero`, which no later call reads.
 * - `pixelForValue`: getPixelForValue of undefined, 0 (twice: an int and a
 *   double in Dart), -0, null, NaN, '100', 100 (twice), true, min (twice:
 *   the Dart test gives an int for an integral min), max, Infinity, -5,
 *   1e-300, 'abc', false, [100] and {}.
 * - `valuesForPixels`: getValueForPixel of the start - 50, of the start +
 *   0.37 of the length, and of the end + 50, along the axis.
 */
function logObservations(s) {
  if (!(s instanceof C.LogarithmicScale)) return {};
  const horizontal = s.isHorizontal();
  const start = horizontal ? s.left : s.top;
  const end = horizontal ? s.right : s.bottom;
  return {
    start: s.start,
    end: s.end,
    significands: s.ticks.map((t) => (t.significand === undefined ? NaN : t.significand)),
    labelForValue: [
      s.min,
      s.max,
      1234.5,
      0.000125,
      98765.4321,
      undefined,
      null,
      '7.5',
      true,
      0,
    ].map((v) => s.getLabelForValue(v)),
    parse: [
      null,
      undefined,
      NaN,
      Infinity,
      -Infinity,
      12,
      -5,
      0,
      -0,
      '12.5',
      '0',
      'abc',
      '',
      true,
      false,
      [7],
      {},
    ].map((v) => s.parse(v, 0)),
    pixelForValue: [
      undefined,
      0,
      0,
      -0,
      null,
      NaN,
      '100',
      100,
      100,
      true,
      s.min,
      s.min,
      s.max,
      Infinity,
      -5,
      1e-300,
      'abc',
      false,
      [100],
      {},
    ].map((v) => s.getPixelForValue(v)),
    valuesForPixels: [start - 50, start + 0.37 * (end - start), end + 50].map((p) =>
      s.getValueForPixel(p),
    ),
  };
}

/** runCase with the observations of logObservations. */
function run(name, config, options) {
  return runCase(name, config, {options, extra: logObservations});
}

/** A copy of a config before the chart writes into it (copy of runCase). */
function copy(v) {
  if (Array.isArray(v)) return v.map(copy);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.keys(v).map((k) => [k, copy(v[k])]));
  }
  return v;
}

/**
 * run with [action] after the creation of the chart: [action] changes the
 * chart and calls chart.update(). The Dart test has an action of the same
 * case name.
 */
function runAction(name, config, action) {
  const literal = copy(config);
  const chart = makeChart(config);
  try {
    action(chart);
    const expected = observe(chart, logObservations);
    expected.drawCalls = drawCalls(chart);
    return {name, config: literal, options: {}, expected};
  } finally {
    chart.destroy();
  }
}

/** A chart of the controller [type] with [datasets], [options], [labels]. */
const chartOf = (type) => (datasets, options, labels) => ({
  type,
  data: labels ? {labels, datasets} : {datasets},
  ...(options ? {options} : {}),
});

/** A chart with the logarithmic scale on both axes. */
const log = chartOf('logTest');

/** A chart with a category index axis and a logarithmic value axis. */
const logValue = chartOf('logValueTest');

/** The points of [xs] and [ys]. */
const points = (xs, ys) => xs.map((x, i) => ({x, y: ys[i]}));

/** The labels of the fixtures of test/fixtures/scale.logarithmic/. */
const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July'];

/** The data of a range from 1 to 1e6 on both axes. */
const wide = [{data: points([1, 30, 1e6], [1, 1e3, 1e6])}];

/** The data of a range from 0.001 to 1000 on both axes. */
const small = [{data: points([0.001, 0.5, 1000], [0.002, 3, 999])}];

/** The options of a fixture: no x axis and no autoskip on y. */
const fixture = (y = {}) => ({
  scales: {x: {display: false}, y: {ticks: {autoSkip: false}, ...y}},
});

/** The tick callback `withUnit`: the value and the unit kg. */
const withUnit = named('withUnit', (value) => value + ' kg');

const cases = [
  // The data forms.
  run('log x and log y from 1 to 1e6', log(wide)),
  run('values from 0.001 to 1000', log(small)),
  run(
    'primitives and labels',
    logValue([{data: [5, 50, 500, 5000]}], undefined, ['a', 'b', 'c', 'd']),
  ),
  run(
    'string values',
    logValue([{data: ['10', '100', '1000', 'abc']}], undefined, ['a', 'b', 'c', 'd']),
  ),
  run(
    'null, NaN, negative, string and boolean values',
    log([
      {
        data: [
          {x: 1, y: null},
          {x: 2, y: NaN},
          {x: null, y: 4},
          {x: 3, y: -5},
          {x: 'abc', y: 6},
          {x: '7', y: '8.5'},
          {x: 9, y: true},
          {x: 12, y: 40},
        ],
      },
    ]),
  ),
  run('data with zeros', logValue([{data: [0, 10, 100]}], undefined, ['a', 'b', 'c'])),
  run(
    'data with zeros and a min that is not a power of ten',
    logValue([{data: [0, 25, 300]}], undefined, ['a', 'b', 'c']),
  ),
  run('zeros on both axes', log([{data: points([0, 5, 50], [0, 2, 0])}])),
  run('only zeros', logValue([{data: [0, 0]}], undefined, ['a', 'b'])),
  run('empty data', log([{data: []}])),
  run(
    'a hidden dataset',
    log([
      {hidden: true, data: points([1e-5, 1e9], [1e-5, 1e9])},
      {data: points([3, 400], [20, 7000])},
    ]),
  ),
  run(
    'stacked values',
    logValue(
      [
        {data: [1, 39], stack: 'stack'},
        {data: [1, 39], stack: 'stack'},
      ],
      {scales: {y: {stacked: true}}},
      ['category 1', 'category 2'],
    ),
  ),
  // The parse of a 0 is undefined in the stacks: getMinMax skips it, and
  // applyStack does not add it.
  run(
    'stacked values with zeros',
    logValue(
      [
        {data: [0, 10, 5], stack: 'stack'},
        {data: [5, 0, 0], stack: 'stack'},
      ],
      {scales: {y: {stacked: true}}},
      ['a', 'b', 'c'],
    ),
  ),
  // The controller passes the absent x (undefined) to getPixelForValue.
  run(
    'parsing false with an absent x',
    log([{data: [{y: 5}, {x: 10, y: 50}, {x: 100, y: 500}]}], {parsing: false}),
  ),
  // Without the parse, the data limits get a 0 and negative values:
  // Math.max(0, min) gives 0, and handleTickRangeOptions lowers the max by
  // one exponent. The negative value gives NaN, and the 0 gives the min.
  run(
    'parsing false with zero, negative and string values',
    log(
      [
        {
          data: [
            {x: -5, y: -3},
            {x: 0, y: 0},
            {x: 100, y: 500},
            {x: '20', y: '7'},
          ],
        },
      ],
      {parsing: false},
    ),
  ),

  // The range options.
  run('min and max', log(small, {scales: {x: {min: 0.5, max: 2e4}, y: {min: 1, max: 1000}}})),
  run(
    'min and max that are not powers of ten',
    logValue([{data: [250, 240, 270, 320, 450, 300, 280]}], fixture({min: 233, max: 471}), MONTHS),
  ),
  run('string min and max', log(wide, {scales: {x: {min: '10'}, y: {min: '10', max: '5000'}}})),
  run(
    'negative and invalid min and max',
    log(small, {scales: {x: {min: -10, max: 'abc'}, y: {min: NaN, max: -1000}}}),
  ),
  run('min 0 and max 0', log(small, {scales: {x: {min: 0}, y: {max: 0}}})),
  // scale.logarithmic.tests.js:1048-1081: the empty data with min 0 and a
  // max (:1048-1058), and the zeros in the data with min 0 (:1060-1081). The
  // parse of the min 0 is undefined, which sets `_zero`.
  run(
    'min 0 with empty data and a max',
    log([{data: []}], {scales: {x: {min: 0, max: 80}, y: {min: 0, max: 0.8}}}),
  ),
  run(
    'min 0 with zeros in the data',
    log([{data: points([0, 10, 1.2, 25, 78], [0, 10, 6.3, 25, 78])}], {
      scales: {x: {min: 0}, y: {min: 0}},
    }),
  ),
  run(
    'suggestedMin and suggestedMax',
    log(small, {
      scales: {x: {suggestedMin: 0.1, suggestedMax: 1e5}, y: {suggestedMin: 50, suggestedMax: 60}},
    }),
  ),
  run(
    'suggested bounds and empty data',
    log([{data: []}], {
      scales: {x: {suggestedMin: 0.5}, y: {suggestedMin: 10, suggestedMax: 100}},
    }),
  ),
  // parse(0) gives undefined: `null !== undefined`, and changeExponent(null)
  // gives 0.
  run('suggestedMin 0 and empty data', log([{data: []}], {scales: {y: {suggestedMin: 0}}})),
  run(
    'beginAtZero',
    logValue([{data: [5, 50]}], {scales: {y: {beginAtZero: true}}}, ['a', 'b']),
  ),
  run(
    'beginAtZero with the suggestedMin at the data min',
    logValue([{data: [10, 100]}], {scales: {y: {beginAtZero: true, suggestedMin: 10}}}, ['a', 'b']),
  ),
  run(
    'beginAtZero with a min',
    logValue([{data: [5, 50]}], {scales: {y: {beginAtZero: true, min: 3}}}, ['a', 'b']),
  ),
  // `_zero` is true and both limits are null: `null !== null` is false, so
  // min stays null, and handleTickRangeOptions gives 1 and 10.
  run('beginAtZero and empty data', log([{data: []}], {scales: {y: {beginAtZero: true}}})),
  run(
    'one value',
    log([{data: points([5, 5], [100, 100])}]),
  ),
  run(
    'one value with a min and a max',
    log([{data: points([5, 5], [100, 100])}], {scales: {x: {min: 5}, y: {max: 100}}}),
  ),
  run(
    'empty data with a max',
    log([{data: []}], {scales: {x: {max: 80}, y: {max: 0.8}}}),
  ),
  run('min above max', log(small, {scales: {y: {min: 100, max: 10}}})),
  run('grace', log(small, {scales: {x: {grace: 3}, y: {grace: '50%'}}})),
  run(
    'bounds data',
    log([{data: points([3, 700], [0.03, 45])}], {
      scales: {x: {bounds: 'data'}, y: {bounds: 'data'}},
    }),
  ),

  // The fixtures of test/fixtures/scale.logarithmic/.
  run('fixture small range', logValue([{data: [3, 1, 4, 2, 5, 3, 16]}], fixture(), MONTHS)),
  run('fixture medium range', logValue([{data: [25, 24, 27, 32, 45, 30, 28]}], fixture(), MONTHS)),
  run(
    'fixture large range',
    logValue([{data: [23, 21, 34, 52, 115, 3333, 5116]}], fixture(), MONTHS),
  ),
  run(
    'fixture large values in a small range',
    logValue(
      [{data: [5000.002, 5000.012, 5000.01, 5000.03, 5000.04, 5000.004, 5000.032]}],
      fixture(),
      MONTHS,
    ),
  ),
  run(
    'fixture null values',
    logValue(
      [
        {data: [150, null, 1500, 200, 9000, 3000, 8888]},
        {data: [1000, 5500, 800, 7777, null, 6666, 5555]},
      ],
      {scales: {x: {display: false}, y: {display: false}}},
      MONTHS,
    ),
  ),
  // startExp raises the range exponent once: 11 steps of 1.
  run('a range from 0.5 to 10.4', log([{data: points([0.5, 10.4], [0.5, 10.4])}])),
  run('a range from 5000 to 6000', logValue([{data: [5000, 6000]}], undefined, ['a', 'b'])),
  // The first tick has the significand 0: the formatter computes its
  // remain.
  run('a range from 1000 to 10000', logValue([{data: [1000, 10000]}], undefined, ['a', 'b'])),

  // The axis options.
  run(
    'reverse with zeros',
    log([{data: points([0, 10, 1000], [0.5, 0, 80])}], {
      scales: {x: {reverse: true}, y: {reverse: true}},
    }),
  ),
  run(
    'positions top and right',
    log(wide, {scales: {x: {position: 'top'}, y: {position: 'right'}}}),
  ),
  run('offset', log(small, {scales: {x: {offset: true}, y: {offset: true}}})),

  // The labels.
  run('a tick callback', log(small, {scales: {y: {ticks: {callback: withUnit}}}})),
  run(
    'locale and format',
    log([{data: points([0.5, 12345], [1.5, 2750])}], {
      locale: 'de-DE',
      scales: {y: {ticks: {format: {maximumFractionDigits: 1}}}},
    }),
  ),
  run(
    'linear tick options',
    log(small, {
      scales: {y: {ticks: {stepSize: 7, count: 3, precision: 1, includeBounds: false}}},
    }),
  ),
  // The numeric formatter writes scientific labels below 1e-4. Above 1e15,
  // package:intl writes other scientific labels than V8, for example '10E14'
  // for 1e15 (differences.md `adapt-intl-number-format`).
  run('scientific labels', log([{data: points([2, 9000], [3e-7, 2e-5])}])),

  // The rotation and the skip of labels.
  run('a narrow canvas', log(wide), {canvas: {width: 150, height: 200}}),
  run(
    'a narrow canvas without major ticks',
    log(wide, {
      scales: {x: {ticks: {major: {enabled: false}}}, y: {ticks: {major: {enabled: false}}}},
    }),
    {canvas: {width: 150, height: 200}},
  ),
  run(
    'maxTicksLimit',
    log(small, {scales: {x: {ticks: {maxTicksLimit: 3}}, y: {ticks: {maxTicksLimit: 5}}}}),
    {canvas: {width: 300, height: 250}},
  ),

  // The updates. No method resets `_zero` (scale.logarithmic.js:105-106,
  // :118-120): after a 0 or beginAtZero, the min stays one exponent lower.
  runAction(
    'data without zeros after data with zeros',
    logValue([{data: [0, 10, 100]}], undefined, ['a', 'b', 'c']),
    (chart) => {
      chart.data.datasets[0].data = [10, 100, 50];
      chart.update();
    },
  ),
  runAction(
    'beginAtZero removed after the creation',
    logValue([{data: [5, 50]}], {scales: {y: {beginAtZero: true}}}, ['a', 'b']),
    (chart) => {
      chart.config.options.scales.y.beginAtZero = false;
      chart.data.datasets[0].data = [20, 100];
      chart.update();
    },
  ),
];

writeReference(OUT, 'scaleLogarithmic', cases, {title: 'logarithmic scale'});
