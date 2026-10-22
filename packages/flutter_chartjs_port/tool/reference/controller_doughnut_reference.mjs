// Original code, not ported from Chart.js: doughnut controller reference generator.
//
// It writes test/port/controllers/controller_doughnut_reference.dart, the
// data of test/port/controllers/controller.doughnut_test.dart: real doughnut
// charts of a build of the pinned Chart.js (Chart.js ADR 0030). See the
// headers of tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases:
// - The 15 cases of Chart.js ADR 0030, section 7 (the row `doughnut`). The
//   first case is `default`, with the options of the scales (a doughnut
//   chart has no scale). The test file runs them again with the light
//   preset (theming.md section 8 test 3).
// - The pin cases of Chart.js ADR 0036, section 9 (names that start with
//   `parsed:`, the doughnut rows of the parsed-data spec, section 7.3) and
//   of Chart.js ADR 0028, section 8 (names that start with `interfaces:`,
//   the doughnut rows of the interfaces spec, section 7.3). The themed run
//   does not run them.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/controller_doughnut_reference.mjs
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
  new URL('../../test/port/controllers/controller_doughnut_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerPhase7(C);

// The platform of the charts. The Dart harness gives each chart the
// platform of platform.flutter.dart, the port of platform.dom.js (Chart.js
// ADR 0014). Its updateConfig is the no-op of platform.base.js:80. The fake
// canvas of makeChart gives the BasicPlatform, whose updateConfig writes
// `options.animation = false` (platform.basic.js:20-22). Thus this
// generator gives the BasicPlatform the no-op of the BasePlatform: a case
// with an animation object keeps it, as a chart of the DOM platform does.
// Only the two cases of the step reset give an animation object (the
// branches `animateRotate` and `animateScale` of controller.doughnut.js:250
// and :264). In each other case, makeChart writes `animation: false`, the
// value of the BasicPlatform.
C.BasicPlatform.prototype.updateConfig = C.BasePlatform.prototype.updateConfig;

/**
 * The probe `parsedIsData`: `meta._parsed === dataset.data` of the dataset
 * 0. With `parsing: false`, the parsed items are the data array
 * (controller.doughnut.js:153).
 */
const parsedIsData = named(
  'parsedIsData',
  (chart) => chart.getDatasetMeta(0)._parsed === chart.data.datasets[0].data,
);

/**
 * The probe `ringGeometry`: `[offsetX, offsetY, outerRadius, innerRadius]`
 * of the controller of each dataset. `update` computes them from the
 * rotation extents of all doughnut datasets (`_getRotationExtents`,
 * controller.doughnut.js:187-206, :224-238).
 */
const ringGeometry = named('ringGeometry', (chart) =>
  chart.data.datasets.map((_, i) => {
    const c = chart.getDatasetMeta(i).controller;
    return [c.offsetX, c.offsetY, c.outerRadius, c.innerRadius];
  }),
);

/**
 * The probe `legendItems`: the legend functions of
 * `overrides.doughnut.plugins.legend` (controller.doughnut.js:92-129) with
 * a test legend `{chart, options}`. `items` and `keys` come from
 * `generateLabels`, then `onClick` with the item index 1 toggles that
 * index, and `visible` and `after` give the state after the click.
 */
const legendItems = named('legendItems', (chart) => {
  const legend = C.Chart.overrides.doughnut.plugins.legend;
  const labels = {
    pointStyle: 'circle',
    textAlign: 'left',
    color: '#666',
    useBorderRadius: true,
    borderRadius: 0,
  };
  chart.legend = {chart, options: {labels}};
  const items = legend.labels.generateLabels(chart);
  legend.onClick({}, {index: 1}, chart.legend);
  return {
    items,
    keys: items.map((item) => Object.keys(item)),
    visible: [0, 1, 2].map((i) => chart.getDataVisibility(i)),
    after: legend.labels.generateLabels(chart),
  };
});

/** A doughnut chart with the labels a, b, c, d and one dataset [extra]. */
const one = (extra, data = [10, 20, 30, 15], options = undefined) => ({
  type: 'doughnut',
  data: {labels: ['a', 'b', 'c', 'd'], datasets: [{data, ...extra}]},
  ...(options === undefined ? {} : {options}),
});

/** Two datasets of [one], the second with [extra2]. */
const two = (extra1, extra2, options = undefined) => ({
  type: 'doughnut',
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
// The 15 cases of Chart.js ADR 0030, section 7.

const cases = [
  runControllerCase(
    'default',
    {
      type: 'doughnut',
      data: {
        labels: ['a', 'b', 'c', 'd', 'e'],
        datasets: [
          {data: [10, 20, 30, 15], label: 'one'},
          {
            data: [5, 10, 8, 12],
            label: 'two',
            backgroundColor: ['red', 'green', 'blue', 'yellow'],
            borderColor: '#0000ff',
            borderWidth: 3,
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
  runControllerCase("cutout '50%'", two({cutout: '50%'}, {})),
  runControllerCase('cutout a number', one({}, undefined, {cutout: 60})),
  runControllerCase(
    'partial rotation and circumference',
    two({}, {borderWidth: 4}, {rotation: 45, circumference: 180}),
  ),
  runControllerCase('two datasets with weight', {
    type: 'doughnut',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {data: [1, 2, 3], weight: 2},
        {data: [3, 2, 1]},
        {data: [2, 2, 2], weight: 0.5},
      ],
    },
  }),
  runControllerCase('the step toggleDataVisibility', two({}, {}), {
    steps: [
      ['toggleDataVisibility', 1],
      ['toggleDataVisibility', 3],
      ['toggleDataVisibility', 1],
    ],
  }),
  runControllerCase('spacing with the default spacingMode', two({spacing: 10}, {spacing: 4})),
  runControllerCase(
    "spacing with spacingMode 'proportional'",
    two({spacing: 10, spacingMode: 'proportional'}, {spacing: 4, spacingMode: 'proportional'}),
  ),
  runControllerCase(
    "spacing with spacingMode 'parallel'",
    two({spacing: 10, spacingMode: 'parallel'}, {spacing: 4, spacingMode: 'parallel'}),
  ),
  runControllerCase(
    'offset and hoverOffset with the step hover',
    {
      type: 'doughnut',
      data: {
        labels: ['a', 'b', 'c'],
        datasets: [{data: [10, 20, 30], offset: [0, 10, 0], hoverOffset: 20}],
      },
    },
    {steps: [['hover', 346, 100], ['update'], ['mouseout']]},
  ),
  runControllerCase(
    "borderAlign 'inner'",
    two({borderAlign: 'inner', borderWidth: 10}, {borderWidth: 4}),
  ),
  runControllerCase(
    'the step reset with animateRotate',
    two({}, {}, {animation: {duration: 0, animateRotate: true, animateScale: false}}),
    {steps: [['reset'], ['update']]},
  ),
  runControllerCase(
    'the step reset with animateScale',
    two({}, {}, {animation: {duration: 0, animateRotate: false, animateScale: true}}),
    {steps: [['reset'], ['update']]},
  ),
  runControllerCase('parsing false', one({parsing: false}, [3, '2', null, 5])),
  runControllerCase('labels that are arrays', {
    type: 'doughnut',
    data: {
      labels: [['a1', 'a2'], 'b', ['c']],
      datasets: [{data: [1, 2, 3]}],
    },
  }),
];

if (cases.length !== 15) throw new Error(`${cases.length} cases; ADR 0030 gives 15.`);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0036 (parsed-data spec, section 7.3).

cases.push(
  runControllerCase('parsed: object data', {
    type: 'doughnut',
    data: {labels: ['a', 'b'], datasets: [{data: {a: 1, b: 2}}]},
  }),
  runControllerCase('parsed: object data with parsing false', {
    type: 'doughnut',
    data: {labels: ['a', 'b'], datasets: [{data: {a: 1, b: 2}, parsing: false}]},
  }),
  runControllerCase(
    "parsed: parsing false, [1, '2', null]",
    {
      type: 'doughnut',
      data: {labels: ['a', 'b', 'c'], datasets: [{data: [1, '2', null], parsing: false}]},
    },
    {extras: {parsedIsData}},
  ),
  runControllerCase(
    'parsed: parsing false, object items',
    {
      type: 'doughnut',
      data: {labels: ['a', 'b'], datasets: [{data: [{value: 1}, {value: 2}], parsing: false}]},
    },
    {extras: {parsedIsData}},
  ),
  runControllerCase(
    'parsed: parsing false, [1, null, 2]',
    {
      type: 'doughnut',
      data: {labels: ['a', 'b', 'c'], datasets: [{data: [1, null, 2], parsing: false}]},
    },
    {extras: {parsedIsData}},
  ),
  runControllerCase('parsed: object items with the default key', {
    type: 'doughnut',
    data: {labels: ['a', 'b'], datasets: [{data: [{value: 1}, {value: '3'}]}]},
  }),
  runControllerCase('parsed: object items with a parsing key', {
    type: 'doughnut',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [{data: [{n: {v: 2}}, {n: {v: 4}}, {n: {}}], parsing: {key: 'n.v'}}],
    },
  }),
  runControllerCase('parsed: object items with the parsing key 5', {
    type: 'doughnut',
    data: {labels: ['a'], datasets: [{data: [{value: 1}], parsing: {key: 5}}]},
  }),
);

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
      type: 'doughnut',
      data: {labels, datasets: [{data: [1, 2, 3, 4, 5, 6]}]},
    }),
  );
}
cases.push(
  runControllerCase(
    'interfaces: the legend functions with a test legend',
    {
      type: 'doughnut',
      data: {
        labels: ['a', ['b1', 'b2'], 'c'],
        datasets: [
          {data: [1, 2, 3], backgroundColor: ['red', 'green', 'blue'], borderRadius: 3},
        ],
      },
    },
    {extras: {legendItems}},
  ),
);

writeControllerReference(OUT, 'controllerDoughnut', cases, {title: 'doughnut controller'});
