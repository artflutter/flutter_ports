// Original code, not ported from Chart.js: scatter controller reference generator.
//
// It writes test/port/controllers/controller_scatter_reference.dart, the
// data of test/port/controllers/controller.scatter_test.dart: real scatter
// charts of a build of the pinned Chart.js (Chart.js ADR 0030). See the
// headers of tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases:
// - The 6 cases of Chart.js ADR 0030, section 7 (the row `scatter`). The
//   first case is `default` (no dataset element), with the options of the
//   scales. The test file runs them again with the light preset (theming.md
//   section 8 test 3).
// - The pin cases of Chart.js ADR 0036, section 9 (names that start with
//   `parsed:`, the scatter rows of the parsed-data spec, section 7.3, and
//   the 3-read form of controller.scatter.js:128-133, Chart.js ADR 0036,
//   section 8) and of Chart.js ADR 0028, section 8 (names
//   that start with `interfaces:`, the scatter rows of the interfaces spec,
//   section 7.3, and the override `interaction.mode: 'point'` of
//   controller.scatter.js:25-27). The themed run does not run them.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/controller_scatter_reference.mjs
//
// The path can also be the first argument.

import {fileURLToPath} from 'node:url';

import {
  loadChartJs,
  makeChart,
  named,
  registerPhase7,
  runControllerCase,
  writeControllerReference,
} from './controller_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/controllers/controller_scatter_reference.dart', import.meta.url),
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
 * The scriptable option `pointRadius` of the case `parsed: a scriptable
 * option writes ctx.parsed`: it writes the key `x` of the parsed item 1
 * (Chart.js ADR 0036 §8: upstream reads the written value).
 */
const radiusWrite = named('radiusWrite', (ctx) => {
  if (ctx.dataIndex === 1) ctx.parsed.x = 10;
  return 3;
});

/** A scatter chart with the datasets [datasets] and the [options]. */
const scatter = (datasets, options) => ({
  type: 'scatter',
  data: {datasets},
  ...(options ? {options} : {}),
});

/**
 * The center of the element [i] of the dataset [d] of a chart of [config],
 * in whole pixels: the point of a `hover` step.
 */
function centerOf(config, d, i) {
  const chart = makeChart(JSON.parse(JSON.stringify(config)));
  try {
    const c = chart.getDatasetMeta(d).data[i].getCenterPoint();
    return [Math.round(c.x), Math.round(c.y)];
  } finally {
    chart.destroy();
  }
}

/** Object data `{x, y}` with gaps in x and a `null` y. */
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
// The 6 cases of Chart.js ADR 0030, section 7.

const cases = [
  runControllerCase(
    'default',
    scatter([
      {
        data: [
          {x: -10, y: 0},
          {x: 0, y: 10},
          {x: 10, y: 5},
          {x: 0.5, y: 5.5},
        ],
        label: 'one',
      },
      {
        data: [
          {x: 4, y: -3},
          {x: -6, y: 8},
          {x: 2, y: 2},
        ],
        label: 'two',
        backgroundColor: 'red',
        borderColor: '#0000ff',
        borderWidth: 2,
        pointRadius: 5,
      },
    ]),
    {
      scaleOptions: true,
      steps: [
        ['update'],
        ['setActive', [[1, 0]]],
        ['update', 'none'],
        ['push', 0, {x: 6, y: -2}],
        ['splice', 1, 1, 1, {x: 1, y: 1}, {x: 3, y: 9}],
        ['reset'],
        ['update'],
      ],
    },
  ),
  runControllerCase(
    'showLine true',
    {
      type: 'scatter',
      data: {
        datasets: [
          {data: gapData(), showLine: true, borderWidth: 3, spanGaps: 2},
          {data: gapData().map(({x, y}) => ({x, y: y === null ? null : -y})), segment: segment()},
          {
            data: [
              {x: 0, y: 1},
              {x: 3, y: 8},
              {x: 6, y: 2},
              {x: 9, y: 7},
            ],
            tension: 0.4,
          },
          {data: [{x: 2, y: -4}], showLine: false},
        ],
      },
      options: {showLine: true},
    },
    {
      steps: [
        ['update'],
        ['push', 0, {x: 12, y: 0}],
        ['splice', 2, 1, 1],
      ],
    },
  ),
  runControllerCase(
    'a visible x range',
    scatter(
      [
        {data: gapData(), showLine: true, spanGaps: 2, segment: segment()},
        {data: gapData().reverse()},
      ],
      {scales: {x: {min: 2, max: 7}}},
    ),
    {steps: [['update'], ['update', 'none']]},
  ),
  runControllerCase(
    'object data',
    scatter([
      {
        data: [
          {a: 1, n: {b: 4}},
          {a: 2, n: {b: null}},
          {a: 3},
          {a: 4, n: {b: '7'}},
          {a: '5', n: {b: 2}},
        ],
        parsing: {xAxisKey: 'a', yAxisKey: 'n.b'},
      },
      {
        data: [
          {x: 1, y: 2},
          {x: 3},
          {y: 4},
          {x: 5, y: NaN},
          {x: 6, y: 1},
        ],
      },
    ]),
  ),
  runControllerCase('getLabelAndValue with labels', {
    type: 'scatter',
    data: {
      labels: ['a', 'b', ['c1', 'c2']],
      datasets: [
        {
          data: [
            {x: 10, y: 15},
            {x: 12, y: 10},
            {x: 1.5, y: -2.25},
            {x: 1000, y: 0},
          ],
          label: 'one',
        },
        {data: [{x: 20, y: 10}], label: 'two'},
      ],
    },
  }),
  runControllerCase(
    'a hidden dataset',
    scatter([
      {
        data: [
          {x: 1, y: 2},
          {x: 2, y: 4},
        ],
        hidden: true,
      },
      {
        data: [
          {x: 3, y: 1},
          {x: 4, y: 3},
        ],
      },
      {
        data: [
          {x: 0, y: 5},
          {x: 5, y: 0},
        ],
        showLine: true,
      },
    ]),
    {
      steps: [
        ['setDatasetVisibility', 0, true],
        ['setDatasetVisibility', 2, false],
      ],
    },
  ),
];

if (cases.length !== 6) throw new Error(`${cases.length} cases; ADR 0030 gives 6.`);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0036 (parsed-data spec, section 7.3).

cases.push(
  runControllerCase(
    'parsed: parsing false, a null item',
    scatter([{data: [{x: 0, y: 1}, null, {x: 2, y: 3}], parsing: false}]),
  ),
  // A logarithmic x scale: `getPixelForValue(undefined)` gives the min
  // pixel, `getPixelForValue(null)` gives NaN (scatter.js:129).
  runControllerCase(
    'parsed: parsing false, a logarithmic x, an item without x',
    scatter(
      [
        {
          data: [
            {y: 5},
            {x: 10, y: 1},
            {x: 100, y: 2},
          ],
          parsing: false,
        },
      ],
      {scales: {x: {type: 'logarithmic'}}},
    ),
  ),
  runControllerCase(
    'parsed: parsing false, a logarithmic x, an item with x null',
    scatter(
      [
        {
          data: [
            {x: null, y: 5},
            {x: 10, y: 1},
            {x: 100, y: 2},
          ],
          parsing: false,
        },
      ],
      {scales: {x: {type: 'logarithmic'}}},
    ),
  ),
  runControllerCase(
    'parsed: the one-read rule with segment, spanGaps 2 and start > 0',
    scatter([{data: gapData(), segment: segment(), spanGaps: 2, showLine: true}], {
      scales: {x: {min: 4.5, max: 9.5}},
    }),
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
  runControllerCase(
    "parsed: spanGaps '2'",
    scatter([{data: gapData(), spanGaps: '2', showLine: true}]),
  ),
  // The read `prevParsed[iAxis]` of :133 comes after the scriptable
  // options of the previous pass (:140): upstream reads the x 10 that the
  // option wrote, thus the point 2 gets `stop` and the line breaks there
  // (Chart.js ADR 0036 §8).
  runControllerCase(
    'parsed: a scriptable option writes ctx.parsed',
    scatter([
      {
        data: [
          {x: 0, y: 1},
          {x: 1, y: 2},
          {x: 2, y: 3},
          {x: 3, y: 4},
        ],
        spanGaps: 1.5,
        showLine: true,
        pointRadius: radiusWrite,
      },
    ]),
  ),
  // The stacked value axis: `applyStack` at scatter.js:130.
  runControllerCase(
    'parsed: stacked object data',
    scatter(
      [
        {
          data: [
            {x: 1, y: 2},
            {x: 2, y: -3},
            {x: 3, y: null},
          ],
        },
        {
          data: [
            {x: 1, y: 4},
            {x: 2, y: 5},
            {x: 3, y: 1},
          ],
        },
      ],
      {scales: {y: {stacked: true}}},
    ),
  ),
  // `dataset.options && dataset.options.borderWidth || 0` keeps the raw
  // value: an empty data returns it as it is (scatter.js:169-173).
  runControllerCase(
    "parsed: showLine with no data returns the borderWidth '3'",
    scatter([
      {data: [], showLine: true, borderWidth: '3'},
      {data: [], showLine: true, borderWidth: 0},
    ]),
  ),
);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0028 (interfaces spec, section 7.3): the
// label of getLabelAndValue is `labels[index] || ''`, any value.

for (const [label, labels] of [
  ['1', [['line 1', 'line 2'], 5, 0, 'd', undefined]],
  ['2', [['line 1', 'line 2'], 7, '', null, 'e']],
]) {
  cases.push(
    runControllerCase(`interfaces: the labels of getLabelAndValue, set ${label}`, {
      type: 'scatter',
      data: {
        labels,
        datasets: [{data: [1, 2, 3, 4, 5, 6].map((v) => ({x: v, y: 7 - v}))}],
      },
    }),
  );
}

// The override `interaction.mode: 'point'` (controller.scatter.js:25-27)
// selects the active elements of a hover (core.controller.js
// `_handleEvent`, Chart.js ADR 0034). The points 0 of the two datasets are
// 1.3 px apart: the mode 'point' activates both, the mode 'nearest' of the
// defaults activates only the point 0 of the dataset 0.
const hoverConfig = scatter(
  [
    {
      data: [
        {x: 1, y: 1},
        {x: 5, y: 5},
      ],
    },
    {
      data: [
        {x: 1.03, y: 1},
        {x: 8, y: 2},
      ],
    },
  ],
  {scales: {x: {min: 0, max: 10}, y: {min: 0, max: 10}}},
);
cases.push(
  runControllerCase("interfaces: the hover with the override interaction.mode 'point'", hoverConfig, {
    steps: [['hover', ...centerOf(hoverConfig, 0, 0)], ['mouseout']],
  }),
);

writeControllerReference(OUT, 'controllerScatter', cases, {title: 'scatter controller'});
