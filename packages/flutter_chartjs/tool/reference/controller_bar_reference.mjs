// Original code, not ported from Chart.js: bar controller reference generator.
//
// It writes test/port/controllers/controller_bar_reference.dart, the data of
// test/port/controllers/controller.bar_test.dart: real bar charts of a build
// of the pinned Chart.js (Chart.js ADR 0030). See the headers of
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases:
// - The 23 cases of Chart.js ADR 0030, section 7 (the row `bar`). The first
//   case is `default`, with the options of the scales. The test file runs
//   them again with the light preset (theming.md section 8 test 3).
// - The pin cases of Chart.js ADR 0036, section 9 (names that start with
//   `parsed:`, the bar rows of the parsed-data spec, section 7.3) and of
//   Chart.js ADR 0028, section 8 (names that start with `interfaces:`, the
//   bar rows of the interfaces spec, section 7.3). The themed run does not
//   run them.
//
// The case `a timeseries index axis` needs the date adapter of the specs.
// Thus this generator loads it (scale_time_common.mjs) and fixes
// `Date.now()` for all cases. The test file runs each case at that time.
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js
// v24.12.0:
//
//   TZ=UTC CHARTJS_DIST=<build>/dist/chart.js \
//   MOMENT_NODE_MODULES=<scratch>/node_modules \
//     node tool/reference/controller_bar_reference.mjs
//
// The two paths can also be the first and the second argument.

import {fileURLToPath} from 'node:url';

import {
  loadChartJs,
  named,
  registerPhase7,
  runControllerCase,
  writeControllerReference,
} from './controller_chart_common.mjs';
import {appendAdapterInfo, loadMomentAdapter} from './scale_time_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/controllers/controller_bar_reference.dart', import.meta.url),
);

const C = await loadChartJs();
await loadMomentAdapter(C);
registerPhase7(C);

/** One day in ms. */
const DAY = 86400000;

/** The first time of the timeseries case: 2021-01-04T00:00:00Z. */
const T0 = Date.UTC(2021, 0, 4);

/**
 * The probe `barEdges`: for each dataset, `[enableBorderRadius,
 * borderSkipped, Number(inflateAmount)]` of each bar. The observations of
 * Chart.js ADR 0030 have no such key. The port converts a raw
 * `inflateAmount` to a number at the write (Chart.js ADR 0036, section 6),
 * and its only reader applies `ToNumber`. Thus the probe compares the
 * number on both sides.
 */
const barEdges = named('barEdges', (chart) =>
  chart.data.datasets.map((_, i) =>
    chart.getDatasetMeta(i).data.map((el) => [
      el.enableBorderRadius,
      el.borderSkipped,
      Number(el.inflateAmount),
    ]),
  ),
);

/**
 * The probe `stackKeys`: the keys of `_stacks` of each parsed item of the
 * dataset 0. A List item holds `_stacks` as an array property; the parsed
 * observation of a List item has no `_stacks`.
 */
const stackKeys = named('stackKeys', (chart) =>
  chart
    .getDatasetMeta(0)
    ._parsed.map((p) => Object.keys(p._stacks || {})),
);

/** A bar chart with the labels a, b, c and one dataset [extra] with [data]. */
const one = (extra, data = [10, 5, -3]) => ({
  type: 'bar',
  data: {labels: ['a', 'b', 'c'], datasets: [{data, ...extra}]},
});

/** `scales: {x: {stacked}, y: {stacked}}`. */
const stackedScales = (stacked) => ({scales: {x: {stacked}, y: {stacked}}});

// ---------------------------------------------------------------------------
// The 23 cases of Chart.js ADR 0030, section 7.

const cases = [
  runControllerCase(
    'default',
    {
      type: 'bar',
      data: {
        labels: ['a', 'b', 'c', 'd', 'e'],
        datasets: [
          {data: [10, 20, -5, 15], label: 'one'},
          {
            data: [5, -10, 8, 12],
            label: 'two',
            backgroundColor: 'red',
            borderColor: '#0000ff',
            borderWidth: 2,
          },
        ],
      },
    },
    {
      scaleOptions: true,
      steps: [
        ['update'],
        ['setActive', [[1, 2]]],
        ['update', 'none'],
        ['push', 0, 6],
        ['splice', 1, 1, 1, 9, 8],
        ['reset'],
        ['update'],
      ],
    },
  ),
  runControllerCase('indexAxis y', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [{data: [3, -2, 6]}, {data: [1, 2, -3], borderWidth: 1}],
    },
    options: {indexAxis: 'y'},
  }),
  runControllerCase('stacked true with borderSkipped middle', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {data: [10, -5, 2], borderSkipped: 'middle', borderWidth: 2},
        {data: [3, 4, -6], borderSkipped: 'middle', borderWidth: 2},
        {data: [1, -2, 2], borderSkipped: 'middle', borderWidth: 2},
      ],
    },
    options: stackedScales(true),
  }),
  runControllerCase('stacked single', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [{data: [5, -3, 4]}, {data: [-2, 6, 3]}, {data: [1, 1, -8]}],
    },
    options: {scales: {x: {stacked: true}, y: {stacked: 'single'}}},
  }),
  runControllerCase('stack groups with negative values', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {data: [4, -2, 3], stack: 's1'},
        {data: [-3, 5, 1], stack: 's2'},
        {data: [2, -4, -1], stack: 's1'},
        {data: [1, 2, -6], stack: 's2'},
      ],
    },
    options: stackedScales(true),
  }),
  runControllerCase('floating bars', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c', 'd'],
      datasets: [
        {data: [[1, 5], [-2, 3], [4, -1], 7]},
        {data: [[0, 2], 3, [-3, -1], [2, 2]]},
      ],
    },
  }),
  runControllerCase('floating bars, stacked', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {data: [[1, 3], [-2, 2], 4]},
        {data: [[2, 4], 5, [-1, -3]]},
      ],
    },
    options: stackedScales(true),
  }),
  runControllerCase(
    'a hidden dataset and setDatasetVisibility',
    {
      type: 'bar',
      data: {
        labels: ['a', 'b', 'c'],
        datasets: [{data: [1, 2, 3], hidden: true}, {data: [3, 1, 2]}, {data: [2, 4, -1]}],
      },
    },
    {
      steps: [
        ['setDatasetVisibility', 0, true],
        ['setDatasetVisibility', 2, false],
      ],
    },
  ),
  runControllerCase('barThickness a number and flex, maxBarThickness', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c', 'd'],
      datasets: [
        {data: [1, 2, 3, 4], barThickness: 20},
        {data: [2, 3, 1, 1], barThickness: 'flex'},
        {data: [3, 1, 2, 5], maxBarThickness: 12},
      ],
    },
  }),
  runControllerCase('grouped false', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {data: [1, 2, 3], grouped: false},
        {data: [3, 1, 2], grouped: false, barPercentage: 0.5},
      ],
    },
  }),
  runControllerCase('skipNull with null items', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c', 'd'],
      datasets: [
        {data: [1, null, 3, 4]},
        {data: [null, 2, 5, null]},
        {data: [3, 4, null, 1]},
      ],
    },
    options: {skipNull: true},
  }),
  runControllerCase('minBarLength with 0 and negative values', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c', 'd', 'e'],
      datasets: [
        {data: [0, -0.1, 5, -3, 0.05], minBarLength: 10},
        {data: [0, 0, -2, 1, 0], minBarLength: 6},
      ],
    },
  }),
  runControllerCase('base', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c', 'd'],
      datasets: [
        {data: [5, 1, -3, 2], base: 2},
        {data: [3, -4, 0, 1], base: -1},
      ],
    },
  }),
  runControllerCase(
    'borderSkipped start, end, an edge, true and false',
    {
      type: 'bar',
      data: {
        labels: ['a', 'b'],
        datasets: [
          {data: [4, -3], borderSkipped: 'start', borderWidth: 3},
          {data: [4, -3], borderSkipped: 'end', borderWidth: 3},
          {data: [4, -3], borderSkipped: 'left', borderWidth: 3},
          {data: [4, -3], borderSkipped: true, borderWidth: 3},
          {data: [4, -3], borderSkipped: false, borderWidth: 3},
        ],
      },
    },
    {extras: {barEdges}},
  ),
  runControllerCase(
    'inflateAmount auto and a number, borderRadius',
    {
      type: 'bar',
      data: {
        labels: ['a', 'b', 'c'],
        datasets: [
          {data: [3, -2, 5], inflateAmount: 'auto', borderRadius: 6, borderWidth: 2},
          {data: [2, 4, -1], inflateAmount: 3},
          {
            data: [1, -3, 2],
            borderRadius: {topLeft: 8, bottomRight: 4},
            borderSkipped: false,
            borderWidth: 1,
          },
        ],
      },
    },
    {extras: {barEdges}},
  ),
  runControllerCase('a linear index axis', {
    type: 'bar',
    data: {
      datasets: [
        {
          data: [
            {x: 1, y: 2},
            {x: 3, y: 4},
            {x: 4, y: 1},
          ],
        },
        {
          data: [
            {x: 2, y: 5},
            {x: 4, y: 3},
          ],
        },
      ],
    },
    options: {scales: {x: {type: 'linear'}}},
  }),
  runControllerCase('a timeseries index axis', {
    type: 'bar',
    data: {
      datasets: [
        {
          data: [
            {x: T0, y: 3},
            {x: T0 + DAY, y: 5},
            {x: T0 + 3 * DAY, y: 2},
            {x: T0 + 4 * DAY, y: 7},
          ],
        },
        {
          data: [
            {x: T0 + DAY, y: 1},
            {x: T0 + 2 * DAY, y: 4},
          ],
        },
      ],
    },
    options: {scales: {x: {type: 'timeseries'}}},
  }),
  runControllerCase('a logarithmic value axis', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c', 'd'],
      datasets: [{data: [1, 10, 100, 1000]}, {data: [5, 50, 0.5, 2000]}],
    },
    options: {scales: {y: {type: 'logarithmic'}}},
  }),
  runControllerCase('reversed scales', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {data: [3, -2, 5], borderWidth: 2},
        {data: [-1, 4, 2], borderWidth: 2},
      ],
    },
    options: {scales: {x: {reverse: true}, y: {reverse: true}}},
  }),
  runControllerCase('clip false', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {data: [1, 2, 3], clip: false},
        {data: [2, 3, 1], clip: 10},
      ],
    },
    options: {scales: {y: {min: 0, max: 2}}},
  }),
  runControllerCase('object data with parsing keys', {
    type: 'bar',
    data: {
      datasets: [
        {
          data: [
            {k: 'a', v: 3},
            {k: 'b', v: 5},
          ],
          parsing: {xAxisKey: 'k', yAxisKey: 'v'},
        },
        {
          data: [
            {k: 'b', nested: {v: 2}},
            {k: 'c', nested: {v: -1}},
          ],
          parsing: {xAxisKey: 'k', yAxisKey: 'nested.v'},
        },
      ],
    },
  }),
  runControllerCase('parsing false', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {
          data: [
            {x: 0, y: 3},
            {x: 1, y: 5},
            {x: 2, y: -2},
          ],
          parsing: false,
        },
        {
          data: [
            {
              x: 1,
              y: 4,
              _custom: {barStart: 1, barEnd: 4, start: 1, end: 4, min: 1, max: 4},
            },
            {x: 2, y: 2},
          ],
          parsing: false,
        },
      ],
    },
  }),
  runControllerCase('string values, null and NaN', {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c', 'd'],
      datasets: [{data: ['10', '-5', '7.5', 'abc']}, {data: [null, NaN, 4, '2']}],
    },
  }),
];

if (cases.length !== 23) throw new Error(`${cases.length} cases; ADR 0030 gives 23.`);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0036 (parsed-data spec, section 7.3).

cases.push(
  runControllerCase('parsed: parsing false, an absent value key and a null value', {
    type: 'bar',
    data: {
      labels: ['a', 'b'],
      datasets: [{data: [{x: 'a'}, {x: 'b', y: null}], parsing: false}],
    },
  }),
);
for (const [label, inflateAmount] of [
  ["'2'", '2'],
  ['null', null],
  ['true', true],
  ["'abc'", 'abc'],
]) {
  cases.push(
    runControllerCase(
      `parsed: inflateAmount ${label}`,
      one({inflateAmount, borderWidth: 1}),
      {extras: {barEdges}},
    ),
  );
}
for (const [label, extra, data] of [
  ['base 5', {base: 5}],
  ["base '5'", {base: '5'}],
  ['base 5 with minBarLength 20', {base: 5, minBarLength: 20}, [5, 6, 0]],
  ["base '5' with minBarLength 20", {base: '5', minBarLength: 20}, [5, 6, 0]],
  ["base '0' with minBarLength 10", {base: '0', minBarLength: 10}, [0, 0.01, 3]],
  ['base 0 with minBarLength 10', {base: 0, minBarLength: 10}, [0, 0.01, 3]],
  ["base ''", {base: ''}],
  ["base 'abc'", {base: 'abc'}],
  ['base true', {base: true}],
  ["minBarLength '20'", {minBarLength: '20'}, [0.01, 0, -0.01]],
  ["barThickness '20'", {barThickness: '20'}],
  ["barThickness 'flex' with grouped false", {barThickness: 'flex', grouped: false}],
  ['maxBarThickness null', {maxBarThickness: null}],
  ["maxBarThickness '30'", {maxBarThickness: '30'}],
]) {
  cases.push(runControllerCase(`parsed: ${label}`, one(extra, data)));
}
cases.push(
  runControllerCase("parsed: base 'b' on a category value axis", {
    type: 'bar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [{data: ['c', 'a', 'b'], base: 'b'}],
    },
    options: {scales: {y: {type: 'category', labels: ['a', 'b', 'c']}}},
  }),
  runControllerCase('parsed: xAxisKey null', {
    type: 'bar',
    data: {labels: ['a'], datasets: [{data: [{x: 'a', y: 1}], parsing: {xAxisKey: null}}]},
  }),
  runControllerCase('parsed: xAxisKey 5', {
    type: 'bar',
    data: {labels: ['a'], datasets: [{data: [{x: 'a', y: 1}], parsing: {xAxisKey: 5}}]},
  }),
  runControllerCase('parsed: a bad yAxisKey on a category index axis', {
    type: 'bar',
    data: {
      datasets: [
        {
          data: [
            {x: 'q', y: 1},
            {x: 'r', y: 2},
          ],
          parsing: {yAxisKey: 5},
        },
      ],
    },
  }),
  runControllerCase(
    'parsed: stacked List items with parsing false',
    {
      type: 'bar',
      data: {
        labels: ['a', 'b'],
        datasets: [
          {
            data: [
              [0, 1],
              [1, 2],
            ],
            parsing: false,
          },
        ],
      },
      options: stackedScales(true),
    },
    {extras: {barEdges, stackKeys}},
  ),
  runControllerCase('parsed: stacked numbers with parsing false', {
    type: 'bar',
    data: {labels: ['a', 'b'], datasets: [{data: [1, 2], parsing: false}]},
    options: stackedScales(true),
  }),
);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0028 (interfaces spec, section 7.3): the
// label of getLabelAndValue is a string for the bar controller.

for (const [label, labels] of [
  ['1', [['line 1', 'line 2'], 5, 0, 'd', undefined]],
  ['2', [['line 1', 'line 2'], 7, '', null, 'e']],
]) {
  cases.push(
    runControllerCase(`interfaces: the labels of getLabelAndValue, set ${label}`, {
      type: 'bar',
      data: {labels, datasets: [{data: [1, 2, 3, 4, 5, 6]}]},
    }),
  );
}

writeControllerReference(OUT, 'controllerBar', cases, {title: 'bar controller'});
appendAdapterInfo(OUT, 'controllerBar');
