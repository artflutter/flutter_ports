// Original code, not ported from Chart.js: line controller reference generator.
//
// It writes test/port/controllers/controller_line_reference.dart, the data
// of test/port/controllers/controller.line_test.dart: real line charts of a
// build of the pinned Chart.js (Chart.js ADR 0030). See the headers of
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases:
// - The 17 cases of Chart.js ADR 0030, section 7 (the row `line`). The
//   first case is `default`, with the options of the scales. The test file
//   runs them again with the light preset (theming.md section 8 test 3).
// - The pin cases of Chart.js ADR 0036, section 9 (names that start with
//   `parsed:`, the line rows of the parsed-data spec, section 7.3) and of
//   Chart.js ADR 0028, section 8 (names that start with `interfaces:`, the
//   line rows of the interfaces spec, section 7.3). The themed run does not
//   run them.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/controller_line_reference.mjs
//
// The path can also be the first argument.

import {fileURLToPath} from 'node:url';

import {
  loadChartJs,
  named,
  registerPhase7,
  runControllerCase,
  writeControllerReference,
} from './controller_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/controllers/controller_line_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerPhase7(C);

/**
 * The segment option `borderColor` of the cases with `segment`: red for
 * the segment that starts at the data index 1.
 */
const segColor = named('segColor', (ctx) => (ctx.p0DataIndex === 1 ? 'red' : undefined));

/**
 * The segment option `borderWidth` of the cases with `segment`: 5 for the
 * segment that ends at the data index 3.
 */
const segWidth = named('segWidth', (ctx) => (ctx.p1DataIndex === 3 ? 5 : undefined));

/** The option `segment` with the two named functions. */
const segment = () => ({borderColor: segColor, borderWidth: segWidth});

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

/**
 * The probe `pointParsed`: the property `parsed` of each point of the
 * dataset 0. The controller writes it only with `segment` (:106).
 */
const pointParsed = named('pointParsed', (chart) =>
  chart.getDatasetMeta(0).data.map((p) => p.parsed),
);

/**
 * The scriptable option `pointRadius` of the case `parsed: a scriptable
 * option writes ctx.parsed`: it writes the key `x` of the parsed item 1
 * (a probe of the pinned build: upstream reads the written value).
 */
const radiusWrite = named('radiusWrite', (ctx) => {
  if (ctx.dataIndex === 1) ctx.parsed.x = 10;
  return 3;
});

/** A line chart with the labels a to e and the datasets [datasets]. */
const lines = (datasets, options) => ({
  type: 'line',
  data: {labels: ['a', 'b', 'c', 'd', 'e'], datasets},
  ...(options ? {options} : {}),
});

/** Object data `{x, y}` on a linear x scale with gaps in x. */
const gapData = () => [
  {x: 0, y: 3},
  {x: 1, y: 5},
  {x: 4, y: 2},
  {x: 5, y: null},
  {x: 6, y: 4},
  {x: 9, y: 1},
  {x: 10, y: 6},
];

// ---------------------------------------------------------------------------
// The 17 cases of Chart.js ADR 0030, section 7.

const cases = [
  runControllerCase(
    'default',
    lines([
      {data: [10, 20, -5, 15, 8], label: 'one'},
      {
        data: [5, -10, 8, 12, 3],
        label: 'two',
        backgroundColor: 'red',
        borderColor: '#0000ff',
        borderWidth: 2,
      },
    ]),
    {
      scaleOptions: true,
      steps: [['update'], ['update', 'none'], ['reset'], ['update']],
    },
  ),
  runControllerCase(
    'showLine false',
    lines([{data: [3, 1, 4, 1, 5], showLine: false, borderWidth: 4}]),
  ),
  runControllerCase(
    'spanGaps true',
    lines([
      {data: [3, null, 4, null, 5], spanGaps: true},
      {data: [1, 2, null, 2, 1]},
    ]),
  ),
  runControllerCase('spanGaps a number', {
    type: 'line',
    data: {
      datasets: [
        {data: gapData(), spanGaps: 2},
        {data: gapData(), spanGaps: 3.5},
      ],
    },
    options: {scales: {x: {type: 'linear'}}},
  }),
  runControllerCase(
    'stepped before, after and middle',
    lines([
      {data: [1, 3, 2, 5, 4], stepped: 'before'},
      {data: [2, 4, 3, 6, 5], stepped: 'after'},
      {data: [3, 5, 4, 7, 6], stepped: 'middle'},
    ]),
  ),
  runControllerCase(
    'tension',
    lines([
      {data: [1, 8, 2, 9, 3], tension: 0.4},
      {data: [9, 2, 8, 1, 7], tension: 0.4, capBezierPoints: false},
    ]),
  ),
  runControllerCase(
    'cubicInterpolationMode monotone',
    lines([
      {data: [1, 8, 2, 9, 3], cubicInterpolationMode: 'monotone'},
      {data: [2, null, 5, 5, 1], cubicInterpolationMode: 'monotone', spanGaps: true},
    ]),
  ),
  runControllerCase(
    'segment with named functions',
    lines([{data: [1, 4, 2, 6, 3], segment: segment(), borderWidth: 2}]),
  ),
  runControllerCase(
    'stacked lines',
    lines(
      [
        {data: [10, -10, 10, -10, 5]},
        {data: [10, 15, 0, -4, 2]},
        {data: [1, 2, null, 3, '4']},
      ],
      {scales: {y: {stacked: true}}},
    ),
  ),
  runControllerCase(
    'indexAxis y',
    lines([{data: [3, -2, 6, 1, 4]}, {data: [1, 2, -3, 0, 2], borderWidth: 1}], {
      indexAxis: 'y',
    }),
  ),
  runControllerCase(
    'a linear x scale with min and max',
    {
      type: 'line',
      data: {datasets: [{data: gapData()}, {data: gapData().reverse()}]},
      options: {scales: {x: {type: 'linear', min: 2, max: 7}}},
    },
    {steps: [['update']]},
  ),
  runControllerCase(
    'pointRadius 0',
    lines([
      {data: [3, 1, 4, 1, 5], pointRadius: 0},
      {data: [2, 7, 1, 8, 2], pointRadius: 0, borderWidth: 6},
    ]),
  ),
  runControllerCase(
    'a hidden dataset and setDatasetVisibility',
    lines([
      {data: [1, 2, 3, 4, 5], hidden: true},
      {data: [5, 4, 3, 2, 1]},
      {data: [2, 4, 1, 3, 5]},
    ]),
    {
      steps: [
        ['setDatasetVisibility', 0, true],
        ['setDatasetVisibility', 2, false],
      ],
    },
  ),
  runControllerCase(
    'parsing false',
    lines([
      {
        data: [
          {x: 0, y: 3},
          {x: 1, y: 5},
          {x: 2, y: -2},
          {x: 3, y: 1},
        ],
        parsing: false,
      },
    ]),
  ),
  runControllerCase(
    'null items',
    lines([
      {data: [1, null, 3, NaN, 5]},
      {data: [{x: 'a', y: 2}, {x: 'b', y: null}, {x: 'c'}, {x: 'd', y: 4}]},
    ]),
  ),
  runControllerCase(
    'drawActiveElementsOnTop false with setActive',
    lines([
      {data: [1, 3, 2, 4, 3], drawActiveElementsOnTop: false, pointRadius: 6},
      {data: [2, 3, 1, 4, 2], pointRadius: 6},
    ]),
    {steps: [['setActive', [[0, 1], [1, 3]]]]},
  ),
  runControllerCase(
    'push',
    lines([{data: [1, 3, 2, 4]}, {data: [4, 2, 3]}]),
    {
      steps: [
        ['push', 0, 6],
        ['push', 1, 1, 5],
      ],
    },
  ),
];

if (cases.length !== 17) throw new Error(`${cases.length} cases; ADR 0030 gives 17.`);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0036 (parsed-data spec, section 7.3).

/** The data of the cases with a `null` item and `parsing: false`. */
const nullItem = () => [{x: 0, y: 1}, null, {x: 2, y: 3}];

cases.push(
  runControllerCase('parsed: parsing false, a null item', {
    type: 'line',
    data: {labels: ['a', 'b', 'c'], datasets: [{data: nullItem(), parsing: false}]},
  }),
  runControllerCase('parsed: parsing false, a null item, with segment', {
    type: 'line',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [{data: nullItem(), parsing: false, segment: segment()}],
    },
  }),
  runControllerCase('parsed: parsing false, a null item, hidden', {
    type: 'line',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [{data: nullItem(), parsing: false, hidden: true}],
    },
  }),
  runControllerCase('parsed: parsing false, a null item, a user min and max', {
    type: 'line',
    data: {datasets: [{data: nullItem(), parsing: false}]},
    options: {scales: {x: {type: 'linear', min: 0.5, max: 1.5}}},
  }),
  runControllerCase(
    'parsed: parsing false, a number item with segment',
    {
      type: 'line',
      data: {
        labels: ['a', 'b'],
        datasets: [{data: [5, {x: 1, y: 2}], parsing: false, segment: segment()}],
      },
    },
    {extras: {pointParsed}},
  ),
  runControllerCase('parsed: parsing false, x.min 1, an item without x', {
    type: 'line',
    data: {
      datasets: [
        {
          data: [
            {y: 50},
            {x: 2, y: 10},
            {x: 3, y: 20},
          ],
          parsing: false,
        },
      ],
    },
    options: {scales: {x: {type: 'linear', min: 1}}},
  }),
  runControllerCase('parsed: parsing false, x.min 1, an item with x null', {
    type: 'line',
    data: {
      datasets: [
        {
          data: [
            {x: null, y: 50},
            {x: 2, y: 10},
            {x: 3, y: 20},
          ],
          parsing: false,
        },
      ],
    },
    options: {scales: {x: {type: 'linear', min: 1}}},
  }),
  runControllerCase(
    'parsed: the one-read rule with segment, spanGaps 2 and start > 0',
    {
      type: 'line',
      data: {datasets: [{data: gapData(), segment: segment(), spanGaps: 2}]},
      options: {scales: {x: {type: 'linear', min: 4.5, max: 9.5}}},
    },
    {
      // The update with the same ranges starts at the index 2 (x 4), after
      // the gap 3 from x 1. The push updates the new point 7 (x 14) with
      // start 7 in the mode 'reset', after the gap 4 from x 10.
      steps: [
        ['update'],
        ['push', 0, {x: 14, y: 2}],
        ['update'],
      ],
    },
  ),
  runControllerCase("parsed: spanGaps '2'", {
    type: 'line',
    data: {datasets: [{data: gapData(), spanGaps: '2'}]},
    options: {scales: {x: {type: 'linear'}}},
  }),
  // The read `prevParsed[iAxis]` of :104 comes after the scriptable
  // options of the previous pass (:111): upstream reads the x 10 that the
  // option wrote, thus the point 2 gets `stop` and the line breaks there.
  runControllerCase('parsed: a scriptable option writes ctx.parsed', {
    type: 'line',
    data: {
      datasets: [
        {
          data: [
            {x: 0, y: 1},
            {x: 1, y: 2},
            {x: 2, y: 3},
            {x: 3, y: 4},
          ],
          spanGaps: 1.5,
          pointRadius: radiusWrite,
        },
      ],
    },
    options: {scales: {x: {type: 'linear'}}},
  }),
  runControllerCase(
    'parsed: stacked List items with parsing false',
    {
      type: 'line',
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
      options: {scales: {y: {stacked: true}}},
    },
    {extras: {stackKeys}},
  ),
  runControllerCase('parsed: stacked numbers with parsing false', {
    type: 'line',
    data: {labels: ['a', 'b'], datasets: [{data: [1, 2], parsing: false}]},
    options: {scales: {y: {stacked: true}}},
  }),
);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0028 (interfaces spec, section 7.3).

// The label of getLabelAndValue is a string for the line controller (the
// method of core.datasetController.js:687).
for (const [label, labels] of [
  ['1', [['line 1', 'line 2'], 5, 0, 'd', undefined]],
  ['2', [['line 1', 'line 2'], 7, '', null, 'e']],
]) {
  cases.push(
    runControllerCase(`interfaces: the labels of getLabelAndValue, set ${label}`, {
      type: 'line',
      data: {labels, datasets: [{data: [1, 2, 3, 4, 5, 6]}]},
    }),
  );
}

// A dataset element of another class: the update writes the four
// properties of :57-60 by name, and the draw throws at :140. The element
// class `OtherLine` has the id `otherLine`. The line defaults name it as
// the dataset element type for this case only.
class OtherLine extends C.Element {
  static id = 'otherLine';
}
C.Chart.register(OtherLine);
C.defaults.datasets.line.datasetElementType = 'otherLine';
cases.push(
  runControllerCase('interfaces: a dataset element of another class', {
    type: 'line',
    data: {labels: ['a', 'b', 'c'], datasets: [{data: [1, 2, 3]}]},
  }),
);
C.defaults.datasets.line.datasetElementType = 'line';
C.Chart.unregister(OtherLine);

writeControllerReference(OUT, 'controllerLine', cases, {title: 'line controller'});
