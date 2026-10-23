// Original code, not ported from Chart.js: category scale reference generator.
//
// It writes test/port/scales/scale_category_reference.dart, the data of
// test/port/scales/scale.category_test.dart: real charts with the category
// scale of a build of the pinned Chart.js (see the header of
// tool/reference/scale_chart_common.mjs for the method, the usage and the
// limits).
//
// The value axis of the charts is the test scale `testLinear`, a subclass of
// Scale of the dist: the range of the data (getMinMax), five ticks at equal
// steps from min to max, and a linear mapping. Thus the test sets the
// mapping of the value axis, and only the category scale of the port is
// under test. The cartesian test controller `categoryTest` has the category
// scale on the index axis and `testLinear` on the value axis. A case can
// give the value axis the type `category` in its options. The Dart test has
// the same test scale and test controller.
//
// For each case, the script records the chart area, each scale (type, min,
// max, ticks, box, label rotation, paddings, the pixel mapping), the points
// and the calls of one draw. For a category scale, the observations also
// have the labels after the layout and the results of getLabelForValue,
// parse, getPixelForValue, getValueForPixel and getPixelForTick for fixed
// values (categoryObservations). An action case changes the chart after its
// creation and calls chart.update(), before the observations
// (runActionCase). The Dart test has the same actions, by the case name.
// For a scale whose position is an object, `observe` records the entries of
// the resolver (jsonValue). observeChart of
// test/port/scales/scale_chart_harness.dart records the same entries: the
// own keys of the resolver and the read of each key.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   node tool/reference/scale_category_reference.mjs \
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
  new URL('../../test/port/scales/scale_category_reference.dart', import.meta.url),
);

const C = await loadChartJs();

/**
 * The test scale `testLinear`: the range of the data (getMinMax), five
 * ticks at equal steps from min to max, and a linear mapping.
 */
class TestLinearScale extends C.Scale {
  static id = 'testLinear';
  static defaults = {};

  determineDataLimits() {
    const {min, max} = this.getMinMax(false);
    this.min = min;
    this.max = max;
  }

  buildTicks() {
    const ticks = [];
    for (let i = 0; i <= 4; i++) {
      ticks.push({value: this.min + ((this.max - this.min) * i) / 4});
    }
    return ticks;
  }

  getPixelForValue(value) {
    return this.getPixelForDecimal((value - this.min) / (this.max - this.min));
  }

  getValueForPixel(pixel) {
    return this.min + this.getDecimalForPixel(pixel) * (this.max - this.min);
  }
}

/** The cartesian test controller: category on the index axis. */
const CategoryTestController = cartesianTestController('categoryTest', {
  scales: {_index_: {type: 'category'}, _value_: {type: 'testLinear'}},
});

registerBuiltins(C, TestLinearScale, CategoryTestController);

/**
 * The observations of a category scale [s], after the observations of
 * `observe`. The Dart test gives the same keys with the same calls.
 *
 * - `labels`: a copy of getLabels(), before the other calls.
 * - `labelForValue`: getLabelForValue of 0, 1, 1.5, '1', -1, the label
 *   count, 'x', true and null.
 * - `parse`: parse of -10, -0.1, 4.1, 5, 1, 1.4, 1.5, NaN, Infinity,
 *   -Infinity, true, false, null and undefined (scale.category.tests.js:
 *   116-150). None of them adds a label.
 * - `pixelForValue`: getPixelForValue of 0, 1, 2.5, -1, the label count,
 *   null, undefined, NaN, true and Infinity. None of them adds a label.
 * - `pixelForLabel`: getPixelForValue of each label.
 * - `valuesForPixels`: getValueForPixel of the start - 50, of the start +
 *   0.37 of the length, and of the end + 50, along the axis.
 * - `tickPixelsOutside`: getPixelForTick of -1 and of the tick count.
 */
function categoryObservations(s) {
  if (!(s instanceof C.CategoryScale)) return {};
  const labels = [...s.getLabels()];
  const n = labels.length;
  const horizontal = s.isHorizontal();
  const start = horizontal ? s.left : s.top;
  const end = horizontal ? s.right : s.bottom;
  return {
    labels,
    labelForValue: [0, 1, 1.5, '1', -1, n, 'x', true, null].map((v) => s.getLabelForValue(v)),
    parse: [
      -10, -0.1, 4.1, 5, 1, 1.4, 1.5, NaN, Infinity, -Infinity, true, false, null, undefined,
    ].map((v) => s.parse(v)),
    pixelForValue: [0, 1, 2.5, -1, n, null, undefined, NaN, true, Infinity].map((v) =>
      s.getPixelForValue(v),
    ),
    pixelForLabel: labels.map((label) => s.getPixelForValue(label)),
    valuesForPixels: [start - 50, start + 0.37 * (end - start), end + 50].map((p) =>
      s.getValueForPixel(p),
    ),
    tickPixelsOutside: [s.getPixelForTick(-1), s.getPixelForTick(s.ticks.length)],
  };
}

/**
 * categoryObservations, then getPixelForValue of 'zz', of '1' and of 'zz'
 * again: the first two add a label. `labelsAfter` gives the labels after the
 * calls.
 */
function addingObservations(s) {
  const observations = categoryObservations(s);
  if (!(s instanceof C.CategoryScale)) return observations;
  return {
    ...observations,
    pixelForNewLabels: ['zz', '1', 'zz'].map((v) => s.getPixelForValue(v)),
    labelsAfter: [...s.getLabels()],
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

/**
 * The times of the Date labels: 1, 2 and 3 January 2020, UTC. The config of
 * a case gives the labels as these numbers. The action of the case puts a
 * Date for each number in the labels.
 */
const times = [Date.UTC(2020, 0, 1), Date.UTC(2020, 0, 2), Date.UTC(2020, 0, 3)];

/** Puts a Date for each number in the labels of [chart]. */
function dateLabels(chart) {
  const labels = chart.data.labels;
  for (let i = 0; i < labels.length; i++) labels[i] = new Date(labels[i]);
  return labels;
}

/**
 * The tick callback `indexLabel`: the tick value as a string. The cases with
 * Date labels use it, because the string of a Date changes with the time
 * zone.
 */
const indexLabel = named('indexLabel', (value) => String(value));

/**
 * The observations of a category scale with Date labels. A copy of a label
 * is a new Date with the same time. `indexOf`, `lastIndexOf` and `===`
 * compare two Dates by identity (scale.category.js:15, :19 and :75). Thus
 * parse finds a label, but not a copy of the label. A copy gets the index
 * argument of parse. Without an index, it gets its time value, which
 * validIndex clamps to the last index.
 *
 * - `labelTimes`: the time value of each label.
 * - `parseLabel`: parse of each label.
 * - `parseLabelAt0`: parse of each label with the index 0.
 * - `parseCopy`: parse of a copy of each label.
 * - `parseCopyAt0`: parse of a copy of each label with the index 0.
 * - `pixelForLabel`: getPixelForValue of each label.
 * - `pixelForCopy`: getPixelForValue of a copy of each label.
 */
function dateObservations(s) {
  if (!(s instanceof C.CategoryScale)) return {};
  const labels = [...s.getLabels()];
  const copies = labels.map((d) => new Date(d.getTime()));
  return {
    labelTimes: labels.map((d) => d.getTime()),
    parseLabel: labels.map((d) => s.parse(d)),
    parseLabelAt0: labels.map((d) => s.parse(d, 0)),
    parseCopy: copies.map((d) => s.parse(d)),
    parseCopyAt0: copies.map((d) => s.parse(d, 0)),
    pixelForLabel: labels.map((d) => s.getPixelForValue(d)),
    pixelForCopy: copies.map((d) => s.getPixelForValue(d)),
  };
}

/** A case of the category test controller with the category observations. */
const chartCase = (name, config, options = {}) =>
  runCase(name, {type: 'categoryTest', ...config}, {options, extra: categoryObservations});

/** An action case of the category test controller. */
const actionCase = (name, config, action) =>
  runActionCase(name, {type: 'categoryTest', ...config}, action, {extra: categoryObservations});

/**
 * The tick callback `upperLabel`: the label of the value in upper case. It
 * reads `this`, the scale.
 */
const upperLabel = named('upperLabel', function (value) {
  return String(this.getLabelForValue(value)).toUpperCase();
});

const months = ['January', 'February', 'March', 'April', 'May', 'June'];
const values = [10, 50, 20, 90, 30, 0];
const abc = ['A', 'B', 'C'];
const many = Array.from({length: 40}, (_, i) => `Label ${i + 1}`);

const cases = [
  chartCase('labels from data.labels', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
  }),
  chartCase('data.xLabels on a horizontal axis before data.labels', {
    data: {
      labels: ['a', 'b', 'c', 'd', 'e'],
      xLabels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
      datasets: [{data: [10, 5, 0, 25, 78]}],
    },
  }),
  chartCase('data.yLabels on a vertical axis', {
    data: {
      labels: ['a', 'b', 'c', 'd', 'e'],
      yLabels: ['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
      datasets: [{data: [10, 5, 0, 25, 78]}],
    },
    options: {indexAxis: 'y'},
  }),
  chartCase('options.labels before the data labels', {
    data: {labels: ['a', 'b', 'c'], datasets: [{data: [10, 5, 0, 25]}]},
    options: {scales: {x: {labels: ['w', 'x', 'y', 'z']}}},
  }),
  chartCase('object data with label strings', {
    data: {
      labels: ['a', 'b', 'c', 'd'],
      datasets: [
        {
          data: [
            {x: 'c', y: 10},
            {x: 'a', y: 30},
            {x: 'd', y: 20},
          ],
        },
      ],
    },
  }),
  chartCase('object data with parsing keys', {
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {
          data: [
            {name: 'b', v: 4},
            {name: 'c', v: 8},
            {name: 'a', v: 0},
          ],
          parsing: {xAxisKey: 'name', yAxisKey: 'v'},
        },
      ],
    },
  }),
  chartCase('object data with numbers and invalid values', {
    data: {
      labels: ['a', 'b', 'c', 'd', 'e', 'f'],
      datasets: [
        {
          data: [
            {x: 2, y: 10},
            {x: null, y: 20},
            {x: NaN, y: 30},
            {x: true, y: 40},
            {x: undefined, y: 50},
            {x: 'f', y: 60},
            {x: 'b', y: 0},
          ],
        },
      ],
    },
  }),
  chartCase('string data on a category value axis', {
    data: {
      labels: ['Mon', 'Tue', 'Wed', 'Thu'],
      yLabels: ['high', 'mid', 'low'],
      datasets: [{data: ['high', 'low', 'mid', 'low']}],
    },
    options: {scales: {y: {type: 'category'}}},
  }),
  chartCase('labels that parse adds', {
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {
          data: [
            {x: 'a', y: 1},
            {x: 'd', y: 2},
            {x: 'e', y: 3},
            {x: 'd', y: 4},
          ],
        },
      ],
    },
  }),
  chartCase('labels that parse adds to empty data labels', {
    data: {
      datasets: [
        {
          data: [
            {x: 'p', y: 5},
            {x: 'q', y: 1},
          ],
        },
      ],
    },
  }),
  chartCase('repeated labels', {
    data: {
      labels: ['tick1', 'tick1', 'tick3', 'tick3', 'tick5'],
      datasets: [{data: [10, 5, 0, 25, 78]}],
    },
  }),
  chartCase('numeric labels', {
    data: {
      labels: [2020, 2021, 2022, 2023],
      datasets: [
        {
          data: [
            {x: 2022, y: 3},
            {x: 2020, y: 9},
          ],
        },
      ],
    },
  }),
  chartCase('multi-line labels', {
    data: {
      labels: [['First', 'line'], 'Second', ['Third', 'and', 'more']],
      datasets: [{data: [1, 2, 3]}],
    },
  }),
  chartCase('min and max as label strings', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {scales: {x: {min: 'February', max: 'April'}}},
  }),
  chartCase('min and max as fractional indexes', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {scales: {x: {min: 1.4, max: 3.5}}},
  }),
  chartCase('min and max out of the range', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {scales: {x: {min: -3, max: 99}}},
  }),
  chartCase('min after max', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {scales: {x: {min: 'April', max: 'February'}}},
  }),
  chartCase('a string min that is not a label', {
    data: {labels: ['a', 'b', 'c'], datasets: [{data: [5, 10, 15]}]},
    options: {scales: {x: {min: 'zz'}}},
  }),
  chartCase('bounds data', {
    data: {
      labels: [...months],
      datasets: [
        {
          data: [
            {x: 'February', y: 1},
            {x: 'April', y: 7},
          ],
        },
      ],
    },
    options: {scales: {x: {bounds: 'data'}}},
  }),
  chartCase('bounds data with suggestedMin and suggestedMax', {
    data: {
      labels: [...months],
      datasets: [
        {
          data: [
            {x: 'March', y: 1},
            {x: 'April', y: 7},
          ],
        },
      ],
    },
    options: {scales: {x: {bounds: 'data', suggestedMin: 'February', suggestedMax: 5}}},
  }),
  chartCase('offset', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {scales: {x: {offset: true}}},
  }),
  chartCase('offset with grid offset and min and max', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {scales: {x: {offset: true, grid: {offset: true}, min: 1, max: 4}}},
  }),
  chartCase('reverse on a horizontal axis', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {scales: {x: {reverse: true}}},
  }),
  chartCase('reverse on a vertical axis', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {indexAxis: 'y', scales: {y: {reverse: true}}},
  }),
  chartCase('a vertical axis at the right with offset', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {indexAxis: 'y', scales: {y: {position: 'right', offset: true}}},
  }),
  chartCase('an axis at the top', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {scales: {x: {position: 'top'}}},
  }),
  chartCase(
    'rotated labels on a narrow canvas',
    {
      data: {
        labels: ['A long first label', 'Second label', 'The third label', 'Last'],
        datasets: [{data: [4, 8, 2, 6]}],
      },
      options: {scales: {x: {ticks: {autoSkip: false}}}},
    },
    {canvas: {width: 200, height: 300}},
  ),
  chartCase(
    'autoskip with many labels',
    {
      data: {labels: [...many], datasets: [{data: many.map((_, i) => (i * 7) % 40)}]},
    },
    {canvas: {width: 300, height: 300}},
  ),
  chartCase('maxTicksLimit', {
    data: {labels: [...many], datasets: [{data: many.map((_, i) => (i * 7) % 40)}]},
    options: {scales: {x: {ticks: {maxTicksLimit: 5, maxRotation: 0}}}},
  }),
  chartCase('a ticks callback that reads this', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {scales: {x: {ticks: {callback: upperLabel}}}},
  }),
  chartCase('a hidden dataset with new labels', {
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {
          hidden: true,
          data: [
            {x: 'h1', y: 100},
            {x: 'h2', y: -100},
          ],
        },
        {
          data: [
            {x: 'b', y: 10},
            {x: 'c', y: 20},
          ],
        },
      ],
    },
    options: {scales: {x: {bounds: 'data'}}},
  }),
  chartCase('a dataset with empty data', {
    data: {labels: ['a', 'b', 'c', 'd'], datasets: [{data: []}, {data: [3, 9]}]},
  }),
  chartCase('parsing false with label strings', {
    data: {
      labels: [...abc],
      datasets: [
        {
          data: [
            {x: 'A', y: 1},
            {x: 'C', y: 3},
            {x: 'B', y: 2},
          ],
        },
      ],
    },
    options: {parsing: false},
  }),
  // The cases below come from the fidelity review of the port.
  chartCase('parsing false with fractional and negative indexes', {
    data: {
      labels: [...months],
      datasets: [
        {
          data: [
            {x: -1.5, y: 1},
            {x: 0.5, y: 2},
            {x: 2.25, y: 3},
          ],
        },
      ],
    },
    options: {parsing: false, scales: {x: {bounds: 'data'}}},
  }),
  chartCase('bounds data with empty data', {
    data: {labels: [...abc], datasets: [{data: []}]},
    options: {scales: {x: {bounds: 'data'}}},
  }),
  chartCase('object data on repeated labels', {
    data: {
      labels: ['a', 'a', 'b'],
      datasets: [
        {
          data: [
            {x: 'a', y: 1},
            {x: 'b', y: 2},
            {x: 'a', y: 3},
            {x: 'a', y: 4},
          ],
        },
      ],
    },
  }),
  // getPixelForValue of a repeated label gives validIndex of the label
  // itself: Math.round('5') is 5, the last index here, and Math.round('1')
  // is 1.
  chartCase('repeated numeric string labels', {
    data: {labels: ['5', '5', 'x', '1', '1'], datasets: [{data: [1, 2, 3, 4, 5]}]},
  }),
  // scale.category.tests.js:92-114: the data object gives the x values a,
  // b, c and d, and parse adds b, c and d to options.labels.
  chartCase('object data as a Map with options.labels', {
    data: {datasets: [{data: {a: 1, b: 3, c: -1, d: 10}}]},
    options: {scales: {x: {labels: ['a']}}},
  }),
  chartCase('more values than labels', {
    data: {labels: ['a', 'b'], datasets: [{data: [1, 2, 3, 4]}]},
  }),
  chartCase('labels with null and undefined', {
    data: {labels: ['a', null, 'c', undefined], datasets: [{data: [1, 2, 3, 4]}]},
  }),
  chartCase('an empty string label that parse adds', {
    data: {
      labels: ['a', 'b'],
      datasets: [
        {
          data: [
            {x: '', y: 1},
            {x: 'b', y: 2},
          ],
        },
      ],
    },
  }),
  chartCase('numeric string data on numeric labels', {
    data: {
      labels: [2020, 2021, 2022],
      datasets: [
        {
          data: [
            {x: '2021', y: 1},
            {x: 2022, y: 2},
          ],
        },
      ],
    },
  }),
  chartCase('options.labels with labels that parse adds', {
    data: {
      labels: ['x'],
      datasets: [
        {
          data: [
            {x: 'p', y: 1},
            {x: 'z', y: 2},
          ],
        },
      ],
    },
    options: {scales: {x: {labels: ['p', 'q']}}},
  }),
  chartCase('an empty options.labels', {
    data: {labels: ['a', 'b'], datasets: [{data: [1, 2, {x: 'k', y: 3}]}]},
    options: {scales: {x: {labels: []}}},
  }),
  chartCase('max only', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {scales: {x: {max: 'March'}}},
  }),
  chartCase('a numeric string min', {
    data: {labels: ['a', 'b', 'c', 'd'], datasets: [{data: [1, 2, 3, 4]}]},
    options: {scales: {x: {min: '2'}}},
  }),
  chartCase('a stacked category value axis with bounds data', {
    data: {
      labels: [...abc],
      yLabels: ['l0', 'l1', 'l2', 'l3', 'l4', 'l5'],
      // The stacks give the max 4 (l4). Without the stacks, the max is 3.
      datasets: [{data: ['l1', 'l2', 'l1']}, {data: ['l2', 'l2', 'l3']}],
    },
    options: {scales: {y: {type: 'category', stacked: true, bounds: 'data'}}},
  }),
  chartCase('reverse and offset on a vertical axis at the left', {
    data: {labels: [...months], datasets: [{data: [...values]}]},
    options: {indexAxis: 'y', scales: {y: {position: 'left', reverse: true, offset: true}}},
  }),
  chartCase('offset as a truthy string', {
    data: {labels: [...abc], datasets: [{data: [1, 2, 3]}]},
    options: {scales: {x: {offset: 'yes'}}},
  }),
  // Chart.js ADR 0025, probe P2 (d): the border and the labels of y are at
  // the pixel of 'B'. The position null gives NaN.
  chartCase('a y axis at the position of a label', {
    data: {labels: [...abc], datasets: [{data: [1, 3, 2]}]},
    options: {scales: {y: {position: {x: 'B'}}}},
  }),
  chartCase('a y axis at the position null', {
    data: {labels: [...abc], datasets: [{data: [1, 3, 2]}]},
    options: {scales: {y: {position: {x: null}}}},
  }),
  runCase(
    'getPixelForValue of strings that are not labels',
    {type: 'categoryTest', data: {labels: [...abc], datasets: [{data: [1, 3, 2]}]}},
    {extra: addingObservations},
  ),
  actionCase(
    'the next update removes the added labels',
    {
      data: {
        labels: ['a', 'b', 'c'],
        datasets: [
          {
            data: [
              {x: 'a', y: 1},
              {x: 'd', y: 2},
              {x: 'e', y: 3},
            ],
          },
        ],
      },
    },
    (chart) => {
      chart.data.datasets[0].data = [
        {x: 'a', y: 1},
        {x: 'b', y: 2},
      ];
      chart.update();
    },
  ),
  actionCase(
    'the next update keeps the added labels at other indexes',
    {
      data: {
        labels: ['a', 'b', 'c'],
        datasets: [
          {
            data: [
              {x: 'a', y: 1},
              {x: 'd', y: 2},
              {x: 'e', y: 3},
            ],
          },
        ],
      },
    },
    (chart) => {
      chart.data.labels.unshift('z');
      chart.update();
    },
  ),
  actionCase(
    'the next update removes a string min',
    {
      data: {labels: ['a', 'b', 'c'], datasets: [{data: [5, 10, 15]}]},
      options: {scales: {x: {min: 'zz'}}},
    },
    (chart) => {
      chart.config.options.scales.x.min = 'b';
      chart.update();
    },
  ),
  actionCase(
    'the next update removes the label of getPixelForValue',
    {data: {labels: [...abc], datasets: [{data: [1, 3, 2]}]}},
    (chart) => {
      chart.scales.x.getPixelForValue('D');
      chart.update();
    },
  ),
  // scale.category.tests.js:543-570.
  actionCase(
    'bounds data, then bounds ticks',
    {
      data: {labels: ['a', 'b', 'c', 'd'], datasets: [{data: {b: 1, c: 99}}]},
      options: {scales: {x: {bounds: 'data'}}},
    },
    (chart) => {
      chart.config.options.scales.x.bounds = 'ticks';
      chart.update();
    },
  ),
  actionCase(
    'a later update keeps a label that the user adds',
    {
      data: {
        labels: ['a', 'b', 'c'],
        datasets: [
          {
            data: [
              {x: 'a', y: 1},
              {x: 'd', y: 2},
            ],
          },
        ],
      },
    },
    (chart) => {
      // The first update removes the label d that parse added, and init
      // clears the added labels. Thus the second update keeps the label d
      // of the user at the same index.
      chart.data.datasets[0].data = [
        {x: 'a', y: 1},
        {x: 'b', y: 2},
      ];
      chart.update();
      chart.data.labels.push('d');
      chart.update();
    },
  ),
  actionCase(
    'the next update keeps a label that parse adds to options.labels',
    {
      data: {
        labels: ['x'],
        datasets: [
          {
            data: [
              {x: 'p', y: 1},
              {x: 'z', y: 2},
            ],
          },
        ],
      },
      options: {scales: {x: {labels: ['p', 'q']}}},
    },
    (chart) => {
      chart.update();
    },
  ),
  // The data items 0 and 1 have copies of the labels 2 and 0. parse does not
  // find a copy, and gives the index of the item: x is 0 and 1. The item 2
  // has the label 1 itself: x is 1.
  runActionCase(
    'Date labels and object data with copies of the labels',
    {
      type: 'categoryTest',
      data: {labels: [...times], datasets: [{data: [1, 2, 3]}]},
      options: {scales: {x: {ticks: {callback: indexLabel}}}},
    },
    (chart) => {
      const labels = dateLabels(chart);
      chart.data.datasets[0].data = [
        {x: new Date(times[2]), y: 1},
        {x: new Date(times[0]), y: 2},
        {x: labels[1], y: 3},
      ];
      chart.update();
    },
    {extra: dateObservations},
  ),
  // The min is a copy of the label 1. parse does not find it, and validIndex
  // clamps its time value to the last index: the min and the max are 2.
  runActionCase(
    'Date labels and a copy of a label as min',
    {
      type: 'categoryTest',
      data: {labels: [...times], datasets: [{data: [1, 2, 3]}]},
      options: {scales: {x: {ticks: {callback: indexLabel}}}},
    },
    (chart) => {
      dateLabels(chart);
      chart.config.options.scales.x.min = new Date(times[1]);
      chart.update();
    },
    {extra: dateObservations},
  ),
];

writeReference(OUT, 'scaleCategory', cases, {title: 'category scale'});
