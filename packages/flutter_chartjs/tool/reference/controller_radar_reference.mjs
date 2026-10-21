// Original code, not ported from Chart.js: radar controller reference generator.
//
// It writes test/port/controllers/controller_radar_reference.dart, the data
// of test/port/controllers/controller.radar_test.dart: real radar charts of
// a build of the pinned Chart.js (Chart.js ADR 0030). See the headers of
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases:
// - The 8 cases of Chart.js ADR 0030, section 7 (the row `radar`). The first
//   case is `default`, with the options of the scales. The test file runs
//   them again with the light preset (theming.md section 8 test 3).
// - The pin cases of Chart.js ADR 0027, section 9 (names that start with
//   `parsed:`, the radar rows of the parsed-data spec, section 7.3) and of
//   Chart.js ADR 0028, section 8 (names that start with `interfaces:`, the
//   radar rows of the interfaces spec, section 7.3). The themed run does not
//   run them.
//
// The generator registers no plugin (registerPhase7). Thus no filler plugin
// calls `updateControlPoints` of the radar line: a line with a tension
// strokes the control points that the points do not have (NaN), as in the
// port of phase 7. The shared recorder (dartArgs of scale_chart_common.mjs)
// converts the arguments of `bezierCurveTo` and `quadraticCurveTo` with
// `ToNumber`, as a browser does: `undefined` gives NaN.
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/controller_radar_reference.mjs
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
  new URL('../../test/port/controllers/controller_radar_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerPhase7(C);

/**
 * The integer point `[x, y]` of the center (`Math.round` of
 * `getCenterPoint()`) of the element [index] of the dataset [d] of the
 * chart of [config]. A hover step at that point hits the element.
 */
function centerOf(config, d, index) {
  const chart = makeChart(structuredClone(config));
  try {
    const c = chart.getDatasetMeta(d).data[index].getCenterPoint(false);
    return [Math.round(c.x), Math.round(c.y)];
  } finally {
    chart.destroy();
  }
}

/**
 * The probe `pointAngles`: for each dataset, the `angle` of each point.
 * The observations of Chart.js ADR 0030 have no such key. The controller
 * writes it (:96), and the filler plugin of phase 8 reads it
 * (plugin.filler/simpleArc.js:20).
 */
const pointAngles = named('pointAngles', (chart) =>
  chart.data.datasets.map((_, i) =>
    chart.getDatasetMeta(i).data.map((el) => el.angle),
  ),
);

/** A radar chart with the labels a to e and the datasets [datasets]. */
const five = (datasets, options) => ({
  type: 'radar',
  data: {labels: ['a', 'b', 'c', 'd', 'e'], datasets},
  ...(options ? {options} : {}),
});

/** The config of the hover case. */
const hoverConfig = five([
  {data: [10, 20, 5, 15, 8], label: 'one'},
  {
    data: [4, 12, 18, 6, 14],
    label: 'two',
    hoverRadius: 7,
    pointHoverBackgroundColor: 'red',
    pointHoverBorderWidth: 3,
  },
]);
const [hoverX, hoverY] = centerOf(hoverConfig, 1, 2);

// ---------------------------------------------------------------------------
// The 8 cases of Chart.js ADR 0030, section 7.

const cases = [
  runControllerCase(
    'default',
    five([
      {data: [10, 20, 5, 15], label: 'one'},
      {
        data: [5, 12, 18, 6, 14],
        label: 'two',
        backgroundColor: 'rgba(255, 0, 0, 0.2)',
        borderColor: '#0000ff',
        borderWidth: 2,
        pointRadius: 4,
      },
    ]),
    {
      scaleOptions: true,
      steps: [
        ['update'],
        ['setActive', [[1, 2]]],
        ['update', 'none'],
        ['update', 'resize'],
        ['push', 0, 9],
        ['splice', 1, 1, 1, 9, 8],
        ['reset'],
        ['update'],
      ],
      extras: {pointAngles},
    },
  ),
  runControllerCase(
    'spanGaps',
    five([
      {data: [10, null, 5, 15, null], spanGaps: true},
      {data: [4, 12, null, 6, 14], spanGaps: 2},
      {data: [null, 8, 16, null, 3]},
    ]),
  ),
  runControllerCase(
    'tension',
    five([
      {data: [10, 20, 5, 15, 8], tension: 0.4},
      {data: [4, 12, 18, 6, 14], tension: 0.2, borderWidth: 2},
    ]),
  ),
  runControllerCase(
    'a hidden dataset',
    five([
      {data: [10, 20, 5, 15, 8], hidden: true},
      {data: [4, 12, 18, 6, 14]},
      {data: [7, 3, 9, 11, 2]},
    ]),
    {
      steps: [
        ['setDatasetVisibility', 0, true],
        ['setDatasetVisibility', 2, false],
      ],
    },
  ),
  runControllerCase(
    'null items',
    five([
      {data: [10, null, 5, null, 8]},
      {data: [null, null, null, 6, 14]},
    ]),
  ),
  runControllerCase(
    'showLine false',
    five([
      {data: [10, 20, 5, 15, 8], showLine: false, borderWidth: 3},
      {data: [4, 12, 18, 6, 14]},
    ]),
  ),
  runControllerCase(
    'scale r options',
    five([{data: [10, 20, 5, 15, 8]}, {data: [4, 12, 18, 6, 14]}], {
      scales: {
        r: {
          min: 0,
          max: 30,
          startAngle: 30,
          reverse: true,
          beginAtZero: true,
          angleLines: {display: false},
          grid: {circular: true},
          pointLabels: {display: true, padding: 8},
          ticks: {stepSize: 5},
        },
      },
    }),
    {scaleOptions: true, extras: {pointAngles}},
  ),
  runControllerCase('the step hover', hoverConfig, {
    steps: [['hover', hoverX, hoverY], ['mouseout']],
  }),
];

if (cases.length !== 8) throw new Error(`${cases.length} cases; ADR 0030 gives 8.`);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0027 (parsed-data spec, section 7.3).

cases.push(
  runControllerCase('parsed: parsing false with numbers', {
    type: 'radar',
    data: {labels: ['a', 'b', 'c'], datasets: [{data: [5, 3, 1], parsing: false}]},
  }),
  runControllerCase('parsed: parsing false with a null item', {
    type: 'radar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [{data: [{r: 5}, null, {r: 1}], parsing: false}],
    },
  }),
  runControllerCase('parsed: a label index past the end', {
    type: 'radar',
    data: {labels: ['a'], datasets: [{data: [1, 2]}]},
  }),
  runControllerCase('parsed: object data with the default key and a parsing key', {
    type: 'radar',
    data: {
      labels: ['a', 'b', 'c'],
      datasets: [
        {data: [{r: 10}, {r: 20}, {r: 15}]},
        {data: [{v: 4}, {v: '12'}, {}], parsing: {key: 'v'}},
      ],
    },
  }),
);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0028 (interfaces spec, section 7.3).

for (const [label, labels] of [
  ['1', [['line 1', 'line 2'], 5, 0, 'd', undefined]],
  ['2', [['line 1', 'line 2'], 7, '', null, 'e']],
]) {
  cases.push(
    runControllerCase(`interfaces: the labels of getLabelAndValue, set ${label}`, {
      type: 'radar',
      data: {labels, datasets: [{data: [1, 2, 3, 4, 5, 6]}]},
    }),
  );
}
cases.push(
  runControllerCase('interfaces: an r scale that is not radial, no data', {
    type: 'radar',
    data: {labels: [], datasets: [{data: []}]},
    options: {scales: {r: {type: 'linear'}}},
  }),
  runControllerCase('interfaces: an r scale that is not radial, with data', {
    type: 'radar',
    data: {labels: ['a', 'b'], datasets: [{data: [1, 2]}]},
    options: {scales: {r: {type: 'linear'}}},
  }),
);

writeControllerReference(OUT, 'controllerRadar', cases, {title: 'radar controller'});
