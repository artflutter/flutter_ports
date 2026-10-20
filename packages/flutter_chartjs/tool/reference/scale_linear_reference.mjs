// Original code, not ported from Chart.js: linear scale reference generator.
//
// It writes test/port/scales/scale_linear_reference.dart, the data of
// test/port/scales/scale.linear_test.dart: real charts with the linear scale
// of the chart.js 4.5.1 npm dist (see the header of
// tool/reference/scale_chart_common.mjs for the method, the usage and the
// limits).
//
// The charts use three cartesian test controllers:
// - `scaleTest` (ScaleTestController of scale_chart_common.mjs): category on
//   the index axis and linear on the value axis.
// - `scaleTest2`: the same overrides. A dataset of this type gets its own
//   stacks: the stack key has the dataset type
//   (core.datasetController.js:124-126).
// - `linearTest`: linear on both axes, for the data objects {x, y}.
// The Dart test has the same test controllers.
//
// For each case, the script records the observations of `observe` and the
// calls of one draw. For a linear scale, the observations also have
// (linearObservations): _startValue, _endValue, _valueRange, getTickLimit(),
// the results of getPixelForValue for a list of JS values, and the results
// of getValueForPixel for three pixels. An action case changes the chart
// after its creation and calls chart.update(), before the observations
// (runActionCase). The Dart test has the same actions, by the case name.
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js
// v24.12.0:
//
//   node tool/reference/scale_linear_reference.mjs \
//     <scratch>/node_modules/chart.js/dist/chart.js
//
// or with the environment variable CHARTJS_DIST.

import {fileURLToPath} from 'node:url';

import {
  ScaleTestController,
  cartesianTestController,
  drawCalls,
  loadChartJs,
  makeChart,
  named,
  observe,
  registerPhase6,
  runCase,
  writeReference,
} from './scale_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/scales/scale_linear_reference.dart', import.meta.url),
);

const C = await loadChartJs();

/** The test controller `scaleTest2`: the overrides of `scaleTest`. */
const ScaleTest2Controller = cartesianTestController('scaleTest2', {
  scales: {_index_: {type: 'category'}, _value_: {type: 'linear'}},
});

/** The test controller `linearTest`: linear on both axes. */
const LinearTestController = cartesianTestController('linearTest', {
  scales: {_index_: {type: 'linear'}, _value_: {type: 'linear'}},
});

registerPhase6(C, ScaleTestController, ScaleTest2Controller, LinearTestController);

/**
 * The values of the observation `pixelForValue`: numbers, and JS values that
 * are not numbers. The Dart test gives the integers below 1e6 as Dart `int`
 * values: they take the literal lines of getPixelForValue, not the fast
 * path. A Date is a Dart `DateTime` (Chart.js ADR 0024).
 */
const pixelValues = [
  0,
  1,
  -1,
  5,
  1e6,
  -2.5,
  null,
  undefined,
  NaN,
  Infinity,
  -Infinity,
  '5',
  ' 12.5 ',
  '0x10',
  'abc',
  '',
  true,
  false,
  [7],
  {},
  new Date(7),
];

/**
 * The observations of a linear scale [s], after the observations of
 * `observe`. A scale of another type gives no key. The Dart test gives the
 * same keys with the same calls.
 *
 * - `startValue`, `endValue` and `valueRange`: the fields of
 *   LinearScaleBase after the configure.
 * - `tickLimit`: getTickLimit(). Without stepSize, it is the smaller of
 *   computeTickLimit() and maxTicksLimit (11 when the option is falsy).
 * - `pixelForValue`: getPixelForValue of each value of pixelValues.
 * - `valuesForPixels`: getValueForPixel of the start - 50, of the start +
 *   0.37 of the length, and of the end + 50, along the axis.
 */
function linearObservations(s) {
  if (!(s instanceof C.LinearScale)) return {};
  const horizontal = s.isHorizontal();
  const start = horizontal ? s.left : s.top;
  const end = horizontal ? s.right : s.bottom;
  return {
    startValue: s._startValue,
    endValue: s._endValue,
    valueRange: s._valueRange,
    tickLimit: s.getTickLimit(),
    pixelForValue: pixelValues.map((v) => s.getPixelForValue(v)),
    valuesForPixels: [start - 50, start + 0.37 * (end - start), end + 50].map((p) =>
      s.getValueForPixel(p),
    ),
  };
}

/**
 * A copy of a config before the chart writes into it, as `copy` of
 * scale_chart_common.mjs: a function stays the same function.
 */
function copy(v) {
  if (Array.isArray(v)) return v.map(copy);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.keys(v).map((k) => [k, copy(v[k])]));
  }
  return v;
}

/**
 * runCase of scale_chart_common.mjs with [action] after the creation of the
 * chart: [action] changes the chart and calls chart.update(). The Dart test
 * has an action of the same case name.
 */
function runActionCase(name, config, action, {options = {}, extra} = {}) {
  const literal = copy(config);
  const optionsLiteral = copy(options);
  const chart = makeChart(config, copy(options));
  try {
    action(chart);
    const expected = observe(chart, extra);
    expected.drawCalls = drawCalls(chart);
    return {name, config: literal, options: optionsLiteral, expected};
  } finally {
    chart.destroy();
  }
}

/** A case of the test controller `scaleTest`. */
const chartCase = (name, config, options = {}) =>
  runCase(name, {type: 'scaleTest', ...config}, {options, extra: linearObservations});

/** A case of the test controller `linearTest`. */
const linearCase = (name, config, options = {}) =>
  runCase(name, {type: 'linearTest', ...config}, {options, extra: linearObservations});

/** An action case of the test controller `scaleTest`. */
const actionCase = (name, config, action) =>
  runActionCase(name, {type: 'scaleTest', ...config}, action, {extra: linearObservations});

/** The tick callback `indexLabel`: the index of the tick as a string. */
const indexLabel = named('indexLabel', (value, index) => index.toString());

/** The tick callback `withUnit`: the value and the unit kg. */
const withUnit = named('withUnit', (value) => value + ' kg');

/**
 * The tick callback `labelOfThis`: getLabelForValue of the scale, `this`,
 * in brackets.
 */
const labelOfThis = named('labelOfThis', function (value) {
  return '[' + this.getLabelForValue(value) + ']';
});

const abc = ['a', 'b', 'c'];
const letters = (n) => Array.from({length: n}, (_, i) => String.fromCharCode(97 + i));
const values = [10, 5, 0, -5, 78, -100];
const values2 = [150, 0, 0, -100, -10, 9];
const tens = [10, 10, 10, 10, 10, 10];
const scatter = [
  {x: 10, y: 100},
  {x: -10, y: 0},
  {x: 0, y: 0},
  {x: 99, y: 7},
];
const big = [
  {x: 1000000.125, y: 1},
  {x: 9999999.5, y: 2},
];

const cases = [
  // determineDataLimits: the data forms.
  chartCase('primitives', {data: {labels: letters(6), datasets: [{data: [...values]}]}}),
  chartCase('string values', {
    data: {labels: letters(6), datasets: [{data: values.map(String)}]},
  }),
  // scale.linear.tests.js:180-213.
  chartCase('two value axes and a hidden dataset', {
    data: {
      labels: letters(6),
      datasets: [
        {yAxisID: 'y', data: ['10', '5', '0', '-5', '78', '-100']},
        {yAxisID: 'y2', data: ['-1000', '1000']},
        {yAxisID: 'y', data: ['150'], hidden: true},
      ],
    },
    options: {scales: {y2: {position: 'right', type: 'linear'}}},
  }),
  // scale.linear.tests.js:215-250.
  chartCase('null, NaN, undefined and infinite values', {
    data: {
      labels: letters(8),
      datasets: [{data: [null, 90, NaN, undefined, 45, 30, Infinity, -Infinity]}],
    },
    options: {scales: {y: {beginAtZero: false}}},
  }),
  chartCase('only values that are not finite', {
    data: {labels: letters(4), datasets: [{data: [null, NaN, Infinity, 'abc']}]},
  }),
  chartCase('small numbers', {
    data: {labels: letters(4), datasets: [{data: [-1e-8, 3e-8, -4e-8, 6e-8]}]},
  }),
  chartCase('empty data', {data: {labels: [...abc], datasets: [{data: []}]}}),
  chartCase('no datasets', {data: {labels: [], datasets: []}}),
  // scale.linear.tests.js:133-157.
  chartCase('suggested bounds without values', {
    data: {labels: letters(6), datasets: [{data: []}]},
    options: {scales: {y: {suggestedMin: -10, suggestedMax: 15}}},
  }),
  // scale.linear.tests.js:159-178.
  chartCase('suggested bounds without datasets', {
    data: {datasets: []},
    options: {scales: {y: {suggestedMin: -10, suggestedMax: 0}}},
  }),
  // scale.linear.tests.js:276-316.
  linearCase('objects on two linear axes', {data: {datasets: [{data: copy(scatter)}]}}),
  linearCase('sorted objects', {
    data: {
      datasets: [
        {
          data: [
            {x: -5, y: 3},
            {x: 0, y: 9},
            {x: 12, y: -4},
            {x: 40, y: 1},
          ],
        },
      ],
    },
  }),
  // getMinMax skips the values outside the user bounds of the other scale.
  linearCase('the user bounds of the other axis', {
    data: {datasets: [{data: copy(scatter)}]},
    options: {scales: {x: {min: -5, max: 20}}},
  }),
  linearCase('objects with null, NaN and string values', {
    data: {
      datasets: [
        {
          data: [
            {x: 1, y: null},
            {x: 2, y: NaN},
            {x: null, y: 4},
            {x: 3, y: 5},
            {x: 'abc', y: 6},
            {x: '7', y: '8.5'},
          ],
        },
      ],
    },
  }),
  // With parsing false, the controller passes the raw values of the data
  // to getPixelForValue: strings, booleans, an array, null and undefined.
  linearCase('raw values with parsing false', {
    data: {
      datasets: [
        {
          parsing: false,
          data: [
            {x: 1, y: '5'},
            {x: 2},
            {x: '3', y: 4},
            {x: 4, y: null},
            {x: 5, y: true},
            {x: 6, y: [7]},
            {x: 7, y: 'abc'},
            {x: 8, y: -2},
          ],
        },
      ],
    },
  }),

  // determineDataLimits: the stacks.
  // scale.linear.tests.js:397-436, with one value axis.
  chartCase('stacked', {
    data: {
      labels: letters(6),
      datasets: [{data: [...values]}, {data: [...values2]}, {data: [...tens]}],
    },
    options: {scales: {y: {stacked: true}}},
  }),
  // scale.linear.tests.js:438-475.
  chartCase('stacked with a hidden dataset', {
    data: {
      labels: letters(6),
      datasets: [
        {data: [...values]},
        {data: [...values2]},
        {data: [10, 20, 30, 40, 50, 60], hidden: true},
      ],
    },
    options: {scales: {y: {stacked: true}}},
  }),
  // scale.linear.tests.js:477-507.
  chartCase('stacked datasets of two types', {
    data: {
      labels: letters(6),
      datasets: [{data: [...values]}, {type: 'scaleTest2', data: [...tens]}, {data: [...values2]}],
    },
    options: {scales: {y: {stacked: true}}},
  }),
  // isStacked: no stacked option and a stack option.
  chartCase('stack groups without the stacked option', {
    data: {
      labels: letters(6),
      datasets: [
        {stack: 'a', data: [...values]},
        {stack: 'a', data: [...values2]},
        {stack: 'b', data: [...tens]},
      ],
    },
  }),
  chartCase('stacked false with stack groups', {
    data: {
      labels: letters(6),
      datasets: [
        {stack: 'a', data: [...values]},
        {stack: 'a', data: [...values2]},
      ],
    },
    options: {scales: {y: {stacked: false}}},
  }),
  chartCase('stacked single', {
    data: {labels: letters(6), datasets: [{data: [...values]}, {data: [...values2]}]},
    options: {scales: {y: {stacked: 'single'}}},
  }),
  // scale.linear.tests.js:1165-1207, with the datasets hidden in the config.
  chartCase('stacked with all datasets hidden', {
    data: {
      labels: ['S1', 'S2', 'S3'],
      datasets: [
        {hidden: true, data: [2500, 2000, 1500]},
        {hidden: true, data: [1000, 2000, 1500]},
      ],
    },
    options: {indexAxis: 'y', scales: {x: {stacked: true}, y: {stacked: true}}},
  }),
  // scale.linear.tests.js:1209-1235.
  chartCase('a user min and all datasets hidden', {
    data: {labels: ['S1', 'S2', 'S3'], datasets: [{hidden: true, data: [2500, 2000, 1500]}]},
    options: {indexAxis: 'y', scales: {x: {min: 20}}},
  }),

  // handleTickRangeOptions.
  chartCase('equal large positive values', {
    data: {labels: letters(2), datasets: [{data: [10000, 10000]}]},
  }),
  chartCase('equal large negative values', {
    data: {labels: letters(2), datasets: [{data: [-10000, -10000]}]},
  }),
  chartCase('equal values with beginAtZero', {
    data: {labels: letters(2), datasets: [{data: [50, 50]}]},
    options: {scales: {y: {beginAtZero: true}}},
  }),
  chartCase('all values zero', {data: {labels: letters(2), datasets: [{data: [0, 0]}]}}),
  // scale.linear.tests.js:602-626.
  chartCase('suggestedMin and suggestedMax', {
    data: {labels: letters(5), datasets: [{data: [1, -1, 0, -2, 1]}]},
    options: {scales: {y: {suggestedMin: -10, suggestedMax: 10}}},
  }),
  // scale.linear.tests.js:628-655.
  chartCase('min and max', {
    data: {labels: letters(6), datasets: [{data: [...values]}]},
    options: {scales: {y: {min: -1010, max: 1010}}},
  }),
  // scale.linear.tests.js:1237-1262.
  chartCase('a user min of 0', {
    data: {labels: ['S1', 'S2', 'S3'], datasets: [{data: [2500, 2000, 1500]}]},
    options: {indexAxis: 'y', scales: {x: {min: 0, max: 3000}, y: {offset: false}}},
  }),
  // scale.linear.tests.js:1264-1289.
  chartCase('a user max of 0', {
    data: {labels: ['S1', 'S2', 'S3'], datasets: [{data: [-2500, -2000, -1500]}]},
    options: {indexAxis: 'y', scales: {x: {min: -3000, max: 0}}},
  }),
  // scale.linear.tests.js:54-74: the user min is above the data.
  chartCase('a user min above the data', {
    data: {labels: letters(1), datasets: [{data: [200]}]},
    options: {scales: {y: {min: 250}}},
  }),
  // scale.linear.tests.js:76-97: the user max is below the data.
  chartCase('a user max below the data', {
    data: {labels: letters(1), datasets: [{data: [200]}]},
    options: {scales: {y: {max: 150}}},
  }),
  // The value range is 0: getPixelForValue divides by 0. The ticks callback
  // keeps the labels short: the numeric format gives 20 fraction digits for
  // a tick spacing of 0, and package:intl gives 15
  // (differences.md#adapt-intl-number-format).
  chartCase('equal user min and max', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {scales: {y: {min: 5, max: 5, ticks: {callback: indexLabel}}}},
  }),
  chartCase('beginAtZero with positive and negative data', {
    data: {
      labels: letters(3),
      datasets: [{data: [20, 30, 40]}, {yAxisID: 'y2', data: [-20, -30, -40]}],
    },
    options: {
      scales: {
        y: {beginAtZero: true},
        y2: {type: 'linear', position: 'right', beginAtZero: true},
      },
    },
  }),
  chartCase('grace', {
    data: {labels: letters(3), datasets: [{data: [20, 30, 40]}]},
    options: {scales: {y: {grace: '10%'}}},
  }),
  chartCase('grace with beginAtZero', {
    data: {labels: letters(3), datasets: [{data: [0, 30, 40]}]},
    options: {scales: {y: {grace: 5, beginAtZero: true}}},
  }),

  // The ticks of LinearScaleBase on the linear scale.
  // scale.linear.tests.js:657-685.
  chartCase('min, max and stepSize', {
    data: {labels: letters(6), datasets: [{data: [...values]}]},
    options: {scales: {y: {min: 1, max: 11, ticks: {stepSize: 2}}}},
  }),
  // scale.linear.tests.js:687-707.
  chartCase('a max with a stepSize that does not fit', {
    data: {labels: letters(3), datasets: [{data: [0.5, 2.5, 1.7]}]},
    options: {scales: {y: {max: 2.6, ticks: {stepSize: 0.4}}}},
  }),
  // scale.linear.tests.js:761-787 and :789-817.
  chartCase('precision', {
    data: {
      labels: letters(4),
      datasets: [{data: [0.1, 0.4, 0.9, 1.25]}, {yAxisID: 'y2', data: [0.111, 0.244, 0.315]}],
    },
    options: {
      scales: {
        y: {ticks: {precision: 0}},
        y2: {type: 'linear', position: 'right', ticks: {precision: 2}},
      },
    },
  }),
  linearCase('count and includeBounds false', {
    data: {datasets: [{data: copy(scatter)}]},
    options: {
      scales: {
        x: {min: -11, max: 103.5, ticks: {includeBounds: false}},
        y: {ticks: {count: 6}},
      },
    },
  }),
  // scale.linear.tests.js:880-899.
  chartCase('the decimal places of the default format', {
    data: {labels: letters(5), datasets: [{data: [0.06, 0.005, 0, 0.025, 0.0078]}]},
  }),
  // scale.linear.tests.js:901-946.
  chartCase('maxTicksLimit 21', {
    data: {labels: letters(2), datasets: [{data: [0.5, 2.5]}]},
    options: {scales: {y: {beginAtZero: false, ticks: {maxTicksLimit: 21}}}},
  }),
  // scale.linear.tests.js:948-968.
  chartCase('bounds data', {
    data: {labels: letters(2), datasets: [{data: [1, 99]}]},
    options: {scales: {y: {bounds: 'data'}}},
  }),
  // scale.linear.tests.js:855-878.
  chartCase('reverse', {
    data: {labels: letters(6), datasets: [{data: [...values]}]},
    options: {scales: {y: {reverse: true}}},
  }),
  chartCase('offset', {
    data: {labels: letters(6), datasets: [{data: [...values]}]},
    options: {scales: {y: {offset: true}}},
  }),

  // The labels.
  // scale.linear.tests.js:970-996.
  chartCase('a ticks callback with the index', {
    data: {labels: letters(5), datasets: [{data: [10, 5, 0, 25, 78]}]},
    options: {scales: {y: {ticks: {callback: indexLabel}}}},
  }),
  chartCase('a ticks callback that reads this', {
    data: {labels: letters(5), datasets: [{data: [10, 5, 0, 25, 78]}]},
    options: {scales: {y: {ticks: {callback: labelOfThis}}}},
  }),
  // scale.linear.tests.js:357-395.
  linearCase('locale de-DE', {
    data: {
      datasets: [
        {
          data: [
            {x: 10000000, y: -1234.5},
            {x: 0, y: 98765.25},
          ],
        },
      ],
    },
    options: {locale: 'de-DE'},
  }),

  // computeTickLimit, vertical. maxTicksLimit 1000 gives the limit of the
  // axis size.
  chartCase(
    'a vertical tick limit on a short canvas',
    {
      data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
      options: {scales: {y: {ticks: {maxTicksLimit: 1000}}}},
    },
    {canvas: {width: 300, height: 150}},
  ),
  chartCase('a vertical tick limit with a large font', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {scales: {y: {ticks: {maxTicksLimit: 1000, font: {size: 40}}}}},
  }),
  chartCase('a vertical tick limit with a lineHeight in px', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {scales: {y: {ticks: {maxTicksLimit: 1000, font: {size: 12, lineHeight: '20px'}}}}},
  }),
  chartCase('a vertical tick limit with minRotation 60', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {scales: {y: {ticks: {maxTicksLimit: 1000, minRotation: 60}}}},
  }),
  // cos(90 degrees) is 6.1e-17, not 0.
  chartCase('a vertical tick limit with minRotation 90', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {scales: {y: {ticks: {maxTicksLimit: 1000, minRotation: 90}}}},
  }),
  // ticks.minRotation || 0 gives the label rotation 0 (core.scale.js:590),
  // but cos(NaN) is NaN: the ratio is 0.001.
  chartCase('a vertical tick limit with minRotation NaN', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {scales: {y: {ticks: {maxTicksLimit: 1000, minRotation: NaN}}}},
  }),
  // The line height 0: computeTickLimit gives Infinity, and getTickLimit
  // gives 11.
  chartCase('a vertical tick limit with a lineHeight of 0', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {scales: {y: {ticks: {font: {lineHeight: 0}}}}},
  }),
  chartCase('a vertical tick limit with the default maxTicksLimit', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
  }),

  // computeTickLimit, horizontal: indexAxis y puts the linear scale on x.
  // sin(0) is 0: the ratio is 0.001.
  chartCase('a horizontal tick limit', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {indexAxis: 'y', scales: {x: {ticks: {maxTicksLimit: 1000}}}},
  }),
  chartCase('a horizontal tick limit with minRotation 30', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {indexAxis: 'y', scales: {x: {ticks: {maxTicksLimit: 1000, minRotation: 30}}}},
  }),
  chartCase('a horizontal tick limit with a string minRotation', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {indexAxis: 'y', scales: {x: {ticks: {maxTicksLimit: 1000, minRotation: '45'}}}},
  }),
  // The line height 0.024 px: 0.024 / 0.001 is 24, below 40.
  chartCase('a horizontal tick limit with a tiny lineHeight', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {indexAxis: 'y', scales: {x: {ticks: {maxTicksLimit: 1000, font: {lineHeight: 0.002}}}}},
  }),
  chartCase('a horizontal tick limit with a large font', {
    data: {labels: letters(3), datasets: [{data: [0, 500, 1000]}]},
    options: {
      indexAxis: 'y',
      scales: {x: {ticks: {maxTicksLimit: 1000, minRotation: 45, font: {size: 30}}}},
    },
  }),

  // The rotation and the skip of labels on a narrow canvas.
  linearCase(
    'large values on a narrow canvas',
    {
      data: {datasets: [{data: copy(big)}]},
      options: {scales: {x: {ticks: {maxTicksLimit: 1000}}}},
    },
    {canvas: {width: 200, height: 300}},
  ),
  linearCase(
    'autoSkip false on a narrow canvas',
    {
      data: {datasets: [{data: copy(big)}]},
      options: {scales: {x: {ticks: {autoSkip: false, maxRotation: 90, callback: withUnit}}}},
    },
    {canvas: {width: 200, height: 300}},
  ),

  // The positions.
  linearCase('positions top and right', {
    data: {datasets: [{data: copy(scatter)}]},
    options: {scales: {x: {position: 'top'}, y: {position: 'right'}}},
  }),
  linearCase('a y axis at the position of an x value', {
    data: {datasets: [{data: copy(scatter)}]},
    options: {scales: {y: {position: {x: 20}}}},
  }),
  // getPixelForValue gets the string: core.scale.js:145.
  linearCase('a y axis at the position of a numeric string', {
    data: {datasets: [{data: copy(scatter)}]},
    options: {scales: {y: {position: {x: '20'}}}},
  }),
  linearCase('an x axis at the position null', {
    data: {datasets: [{data: copy(scatter)}]},
    options: {scales: {x: {position: {y: null}}}},
  }),
  linearCase('center positions', {
    data: {datasets: [{data: copy(scatter)}]},
    options: {scales: {x: {position: 'center'}, y: {position: 'center'}}},
  }),

  // The fit.
  // scale.linear.tests.js:1112-1163.
  linearCase('display false', {
    data: {datasets: [{data: copy(scatter)}]},
    options: {scales: {x: {display: false}, y: {display: false}}},
  }),
  // scale.linear.tests.js:1041-1110, with the titles in the config.
  linearCase('titles', {
    data: {datasets: [{data: copy(scatter)}]},
    options: {scales: {x: {title: {display: true, text: 'x'}}, y: {title: {display: true}}}},
  }),
  // scale.linear.tests.js:1372-1395.
  chartCase(
    'a canvas of size 0',
    {
      data: {
        labels: [0, 1, 2, 3, 4, 5, 6, 7, '7+'],
        datasets: [{data: [29.05, 4, 15.69, 11.69, 2.84, 4, 0, 3.84, 4]}],
      },
      options: {layout: {padding: {top: 30, left: 1, right: 1, bottom: 1}}},
    },
    {canvas: {width: 0, height: 0}},
  ),

  // The updates.
  // scale.linear.tests.js:215-250.
  actionCase(
    'stacked and beginAtZero after the creation',
    {
      data: {
        labels: letters(8),
        datasets: [{data: [null, 90, NaN, undefined, 45, 30, Infinity, -Infinity]}],
      },
      options: {scales: {y: {beginAtZero: false}}},
    },
    (chart) => {
      chart.config.options.scales.y.stacked = true;
      chart.update();
      chart.config.options.scales.y.beginAtZero = true;
      chart.update();
    },
  ),
  actionCase(
    'a dataset hidden after the creation',
    {
      data: {labels: letters(6), datasets: [{data: [...values]}, {data: [...values2]}]},
      options: {scales: {y: {stacked: true}}},
    },
    (chart) => {
      chart.setDatasetVisibility(1, false);
      chart.update();
    },
  ),
  // scale.linear.tests.js:901-946.
  actionCase(
    'maxTicksLimit, stepSize, min and max after the creation',
    {
      data: {labels: letters(2), datasets: [{data: [0.5, 2.5]}]},
      options: {scales: {y: {beginAtZero: false}}},
    },
    (chart) => {
      const y = chart.config.options.scales.y;
      y.ticks = {maxTicksLimit: 11, stepSize: 0.01};
      y.min = 0.3;
      y.max = 2.8;
      chart.update();
    },
  ),
  // scale.linear.tests.js:1291-1330.
  actionCase(
    'reverse after the creation',
    {
      data: {labels: letters(8), datasets: [{data: [0.05, -25, 10, 15, 20, 25, 30, 35]}]},
      options: {indexAxis: 'y'},
    },
    (chart) => {
      chart.config.options.scales.x.reverse = true;
      chart.update();
    },
  ),
];

writeReference(OUT, 'scaleLinear', cases, {title: 'linear scale'});
