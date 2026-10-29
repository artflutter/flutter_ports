// Original code, not ported from Chart.js: pie controller reference generator.
//
// It writes test/port/controllers/controller_pie_reference.dart, the data of
// test/port/controllers/controller.pie_test.dart: real pie charts of a build
// of the pinned Chart.js (Chart.js ADR 0030). See the headers of
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// controller.pie.js extends controller.doughnut.js and changes only the
// defaults. Thus these cases examine the pie defaults and the statics that
// the pie class gets from the doughnut class (the descriptors and the
// overrides). The doughnut generator examines the other option branches.
//
// The cases:
// - The 4 cases of Chart.js ADR 0030, section 7 (the row `pie`). The first
//   case is `default`, with the options of the scales (a pie chart has no
//   scale). The test file runs them again with the light preset (theming.md
//   section 8 test 3).
// - The pin cases of Chart.js ADR 0028, section 8 (names that start with
//   `interfaces:`, the pie rows of the interfaces spec, section 7.3). The
//   themed run does not run them. Pie has no rows in section 7.3 of the
//   parsed-data spec: the parse is the doughnut parse.
// - The legend override cases of Chart.js ADR 0041, section 5 (names that
//   start with `legend:`): the real legend with the label options of the
//   old test legend, its items and hit boxes, and a click on the item 1.
//   The legend functions of `overrides.pie` are the doughnut functions
//   (Chart.js ADR 0028, section 6). The test file runs them unthemed only
//   (report decision 2: plugin.legend_test.dart runs the legend with the
//   light preset).
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045):
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/controller_pie_reference.mjs
//
// The path can also be the first argument.

import {fileURLToPath} from 'node:url';

import {
  loadChartJs,
  named,
  registerBuiltins,
  runControllerCase,
  writeControllerReference,
} from './controller_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/controllers/controller_pie_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerBuiltins(C);

// The platform of the charts, as in controller_doughnut_reference.mjs. The
// Dart harness gives each chart the platform of platform.flutter.dart, with
// the no-op updateConfig of platform.base.js:80. The fake canvas of
// makeChart gives the BasicPlatform, whose updateConfig writes
// `options.animation = false` (platform.basic.js:20-22). Thus this
// generator gives the BasicPlatform the no-op of the BasePlatform. No case
// gives an animation object: makeChart writes `animation: false` in each
// case, the value of the BasicPlatform. The patch keeps the platform of
// both sides equal for a later case with an animation object.
C.BasicPlatform.prototype.updateConfig = C.BasePlatform.prototype.updateConfig;

/**
 * The probe `ringGeometry`: `[offsetX, offsetY, outerRadius, innerRadius]`
 * of the controller of each dataset. `update` computes them from the
 * rotation extents of all pie datasets (`_getRotationExtents`,
 * controller.doughnut.js:187-206, :224-238).
 */
const ringGeometry = named('ringGeometry', (chart) =>
  chart.data.datasets.map((_, i) => {
    const c = chart.getDatasetMeta(i).controller;
    return [c.offsetX, c.offsetY, c.outerRadius, c.innerRadius];
  }),
);

/**
 * The probe `realLegend`: the items and the hit boxes of the real legend,
 * `{items: chart.legend.legendItems, hitBoxes: chart.legend.legendHitBoxes}`
 * as plain copies (Chart.js ADR 0041, section 5), and `keys`, the
 * `Object.keys` of each item in order: the harness compares only the
 * expected keys of a Map, so `keys` pins the key list of the items. `buildLabels`
 * (plugin.legend.js:104-121) makes the items with the legend functions of
 * `overrides.pie.plugins.legend`: the doughnut functions
 * (controller.doughnut.js:92-129), which the pie class gets through the
 * class chain.
 */
const realLegend = named('realLegend', (chart) => ({
  items: chart.legend.legendItems,
  keys: chart.legend.legendItems.map((item) => Object.keys(item)),
  hitBoxes: chart.legend.legendHitBoxes,
}));

/**
 * Two pie datasets with the labels a, b, c, d, with [extra1] and [extra2].
 *
 * The data of the second dataset is the data of the doughnut generator
 * ([5, 15, 10, 20]). The case `the step toggleDataVisibility` has a hit tie
 * at its step 2 (the steps count from 0: only the index 3 hidden): the hit
 * point 12, (244, 268), is on the line x + y = 512, and query 10 compares
 * two equal distances. `Math.sin(3.665191429188092)` decides the item.
 * `jsSin` gives the V8 bits on every target (Chart.js ADR 0045). The case
 * pins the tie.
 */
const two = (extra1, extra2, options = undefined) => ({
  type: 'pie',
  data: {
    labels: ['a', 'b', 'c', 'd'],
    datasets: [
      {data: [10, 20, 30, 15], ...extra1},
      {data: [5, 15, 10, 20], ...extra2},
    ],
  },
  ...(options === undefined ? {} : {options}),
});

// ---------------------------------------------------------------------------
// The 4 cases of Chart.js ADR 0030, section 7.

const cases = [
  runControllerCase(
    'default',
    {
      type: 'pie',
      data: {
        labels: ['a', 'b', 'c', 'd', 'e'],
        datasets: [{data: [10, 20, 30, 15], label: 'one'}],
      },
    },
    {
      scaleOptions: true,
      steps: [
        ['update'],
        ['setActive', [[0, 2]]],
        ['update', 'none'],
        ['push', 0, 6],
        ['splice', 0, 1, 1, 9, 8],
        ['reset'],
        ['update'],
      ],
    },
  ),
  runControllerCase('the step toggleDataVisibility', two({}, {}), {
    steps: [
      ['toggleDataVisibility', 1],
      ['toggleDataVisibility', 3],
      ['toggleDataVisibility', 1],
    ],
  }),
  runControllerCase(
    'two datasets',
    two(
      {label: 'one'},
      {
        label: 'two',
        backgroundColor: ['red', 'green', 'blue', 'yellow'],
        borderColor: '#0000ff',
        borderWidth: 3,
      },
    ),
  ),
  runControllerCase(
    'the step hover',
    {
      type: 'pie',
      data: {
        labels: ['a', 'b', 'c'],
        datasets: [
          {
            data: [10, 20, 30],
            hoverOffset: 20,
            hoverBorderWidth: 5,
            hoverBackgroundColor: ['#ff0000', '#00ff00', '#0000ff'],
          },
        ],
      },
    },
    {steps: [['hover', 346, 100], ['update'], ['mouseout']]},
  ),
];

if (cases.length !== 4) throw new Error(`${cases.length} cases; ADR 0030 gives 4.`);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0028 (interfaces spec, section 7.3).

cases.push(
  runControllerCase(
    'interfaces: two datasets with other rotation and circumference',
    two({rotation: 0, circumference: 90}, {rotation: 90, circumference: 90}),
    {extras: {ringGeometry}},
  ),
);
for (const [label, labels] of [
  ['1', [['line 1', 'line 2'], 5, 0, 'd', undefined]],
  ['2', [['line 1', 'line 2'], 7, '', null, 'e']],
]) {
  cases.push(
    runControllerCase(`interfaces: the labels of getLabelAndValue, set ${label}`, {
      type: 'pie',
      data: {labels, datasets: [{data: [1, 2, 3, 4, 5, 6]}]},
    }),
  );
}

// ---------------------------------------------------------------------------
// The legend override cases of Chart.js ADR 0041, section 5.

/**
 * A pie chart with 3 labels (the label 1 has two lines), 1 dataset and the
 * label options of the old test legend in `plugins.legend.labels`. The step
 * `clickLegend` clicks the center of the hit box of the item 1: the
 * `onClick` of the overrides (controller.doughnut.js:125-128) toggles the
 * data index 1 and updates the chart.
 */
const legendChart = () => ({
  type: 'pie',
  data: {
    labels: ['a', ['b1', 'b2'], 'c'],
    datasets: [{data: [1, 2, 3], backgroundColor: ['red', 'green', 'blue'], borderRadius: 3}],
  },
  options: {
    plugins: {
      legend: {
        labels: {pointStyle: 'circle', textAlign: 'left', useBorderRadius: true, borderRadius: 0},
      },
    },
  },
});

cases.push(
  runControllerCase('legend: items', legendChart(), {extras: {realLegend}}),
  runControllerCase('legend: click', legendChart(), {
    steps: [['clickLegend', 1]],
    extras: {realLegend},
  }),
  runControllerCase('legend: click twice', legendChart(), {
    steps: [
      ['clickLegend', 1],
      ['clickLegend', 1],
    ],
    extras: {realLegend},
  }),
);

writeControllerReference(OUT, 'controllerPie', cases, {title: 'pie controller'});
