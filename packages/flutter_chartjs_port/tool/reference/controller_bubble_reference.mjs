// Original code, not ported from Chart.js: bubble controller reference generator.
//
// It writes test/port/controllers/controller_bubble_reference.dart, the data
// of test/port/controllers/controller.bubble_test.dart: real bubble charts of
// a build of the pinned Chart.js (Chart.js ADR 0030). See the headers of
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases:
// - The 7 cases of Chart.js ADR 0030, section 7 (the row `bubble`). The
//   first case is `default` (`r` from the data), with the options of the
//   scales. The test file runs them again with the light preset (theming.md
//   section 8 test 3).
// - The pin cases of Chart.js ADR 0036, section 9 (names that start with
//   `parsed:`, the bubble rows of the parsed-data spec, section 7.3, and the
//   `&&` chain and the `+=` of controller.bubble.js:75 and :165) and of
//   Chart.js ADR 0028, section 8 (names that start with `interfaces:`, the
//   bubble rows of the interfaces spec, section 7.3). The themed run does
//   not run them.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/controller_bubble_reference.mjs
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
  new URL('../../test/port/controllers/controller_bubble_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerPhase7(C);

/**
 * The scriptable option `radius` of the case `a named radius function`:
 * 2 plus 3 times the data index. The Dart test has a function of the same
 * name with the same body.
 */
const radiusOfIndex = named('radiusOfIndex', (ctx) => 2 + ctx.dataIndex * 3);

/**
 * The scriptable option `radius` of the case `parsed: an insert below the
 * old length reads the old parsed item`: the raw data item. The Dart test
 * has a function of the same name with the same body.
 */
const rawRadius = named('rawRadius', (ctx) => ctx.raw);

/**
 * The integer center `[x, y]` (`Math.round` of `getCenterPoint()`) of the
 * element [i] of the dataset [d] of the chart of [config]: the point of a
 * `hover` step. The config has no function, so a JSON copy keeps it.
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

/** A bubble chart with one dataset [extra] with [data]. */
const one = (extra, data) => ({
  type: 'bubble',
  data: {datasets: [{data, ...extra}]},
});

// ---------------------------------------------------------------------------
// The 7 cases of Chart.js ADR 0030, section 7.

/** The config of the case `hoverRadius with the step hover`. */
const hoverConfig = {
  type: 'bubble',
  data: {
    datasets: [
      {
        data: [
          {x: 1, y: 2, r: 10},
          {x: 3, y: 5, r: 6},
          {x: 5, y: 1, r: 14},
        ],
        hoverRadius: 7,
        hoverBackgroundColor: 'rgb(200, 100, 150)',
        hoverBorderWidth: 3,
      },
      {
        data: [
          {x: 2, y: 4, r: 8},
          {x: 4, y: 3},
        ],
        radius: 5,
      },
    ],
  },
};

const cases = [
  runControllerCase(
    'default',
    {
      type: 'bubble',
      data: {
        labels: ['a', 'b', 'c', 'd'],
        datasets: [
          {
            data: [
              {x: 10, y: 10, r: 5},
              {x: -15, y: -10, r: 1},
              {x: 0, y: -9, r: 2},
              {x: -4, y: 10, r: 12},
            ],
            label: 'one',
          },
          {
            data: [
              {x: 4, y: 2, r: 8},
              {x: 12, y: -6},
              {x: -8, y: 5, r: 3.5},
            ],
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
        ['setActive', [[1, 0]]],
        ['update', 'none'],
        ['push', 0, {x: 6, y: -2, r: 9}],
        ['splice', 1, 1, 1, {x: 1, y: 1, r: 4}, {x: 2, y: 8}],
        ['reset'],
        ['update'],
      ],
    },
  ),
  runControllerCase('a named radius function', {
    type: 'bubble',
    data: {
      labels: [0, 1, 2, 3],
      datasets: [
        {
          data: [
            {x: 0, y: 1},
            {x: 1, y: 3},
            {x: 2, y: 2, r: 9},
            {x: 3, y: 4},
          ],
          radius: radiusOfIndex,
        },
        {data: [4, 2, 5, 1], radius: radiusOfIndex},
      ],
    },
  }),
  runControllerCase('hoverRadius with the step hover', hoverConfig, {
    steps: [
      ['hover', ...centerOf(hoverConfig, 0, 0)],
      ['hover', ...centerOf(hoverConfig, 1, 0)],
      ['mouseout'],
    ],
  }),
  runControllerCase('custom parsing keys', {
    type: 'bubble',
    data: {
      datasets: [
        {
          data: [
            {a: 1, b: 4, r: 6},
            {a: 2, b: 2},
            {a: 4, b: 5, r: 3},
          ],
          parsing: {xAxisKey: 'a', yAxisKey: 'b'},
        },
        {
          data: [
            {a: 3, n: {y: 1}, r: 7},
            {a: 5, n: {y: 3}, r: 2},
          ],
          parsing: {xAxisKey: 'a', yAxisKey: 'n.y'},
        },
      ],
    },
    options: {indexAxis: 'y'},
  }),
  // The items of the inserts below the old length have an `item[2]`: the
  // case `parsed: an insert below the old length reads the old parsed item`
  // pins the fallback radius of such an insert.
  runControllerCase(
    '[x, y, r] arrays',
    {
      type: 'bubble',
      data: {
        datasets: [
          {
            data: [
              [1, 2, 5],
              [2, 4],
              [3, 1, null],
              [4, 3, 0],
              [5, 5, 7],
            ],
          },
          {
            data: [
              [2, 3, 12],
              [4, 1, 2.5],
            ],
            radius: 6,
          },
        ],
      },
    },
    {
      steps: [
        ['update'],
        ['push', 0, [6, 2, 3], [7, 6]],
        ['splice', 0, 1, 1, [1, 1, 4], [2, 2, null], [3, 3, 0]],
        ['splice', 1, 2, 0, [5, 4], [6, 5, 1.5]],
        ['reset'],
        ['update'],
      ],
    },
  ),
  runControllerCase('getMaxOverflow', {
    type: 'bubble',
    data: {
      datasets: [
        {
          data: [
            {x: 0, y: 0, r: 30},
            {x: 10, y: 10, r: 20},
            {x: 5, y: 5, r: 2},
          ],
          borderWidth: 4,
        },
        {
          data: [
            {x: 2, y: 8, r: 0},
            {x: 8, y: 2, r: 0},
          ],
          borderWidth: 0,
        },
      ],
    },
    options: {scales: {x: {min: 0, max: 10}, y: {min: 0, max: 10}}},
  }),
  runControllerCase('clip', {
    type: 'bubble',
    data: {
      datasets: [
        {
          data: [
            {x: 1, y: 1, r: 25},
            {x: 4, y: 9, r: 18},
          ],
          clip: false,
        },
        {
          data: [
            {x: 2, y: 9.5, r: 20},
            {x: 5, y: 0.5, r: 15},
          ],
          clip: 10,
        },
        {
          data: [
            {x: 0.5, y: 5, r: 22},
            {x: 5.5, y: 6, r: 12},
          ],
          clip: {left: 5, top: false, right: -2, bottom: 0},
        },
      ],
    },
    options: {scales: {x: {min: 1, max: 5}, y: {min: 1, max: 9}}},
  }),
];

if (cases.length !== 7) throw new Error(`${cases.length} cases; ADR 0030 gives 7.`);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0036 (parsed-data spec, section 7.3) and of
// the `&&` chain and the `+=` of controller.bubble.js:75 and :165.

cases.push(
  runControllerCase(
    'parsed: parsing false, [x, y, r] arrays',
    one({parsing: false}, [
      [1, 2, 5],
      [3, 4, 6],
    ]),
  ),
  runControllerCase(
    'parsed: parsing false, a null item',
    one({parsing: false}, [{x: 1, y: 2, r: 3}, null]),
  ),
  runControllerCase(
    'parsed: object data with a null item',
    one({}, [{x: 1, y: 2, r: 3}, null]),
  ),
  runControllerCase(
    'parsed: the r values of object data',
    one({radius: 4}, [
      {x: 1, y: 1, r: '5'},
      {x: 2, y: 2, r: 0},
      {x: 3, y: 3, r: null},
      {x: 4, y: 4, r: true},
      {x: 5, y: 5, r: 'abc'},
      {x: 6, y: 6, r: -2},
      {x: 7, y: 7},
      {x: 8, y: 8, r: '0'},
    ]),
  ),
  runControllerCase(
    "parsed: radius '4' with primitive data",
    {
      type: 'bubble',
      data: {labels: [1, 2, 3], datasets: [{data: [3, 1, 2], radius: '4'}]},
    },
    {steps: [['update']]},
  ),
  runControllerCase(
    "parsed: radius '4' with object data",
    one({radius: '4'}, [
      {x: 1, y: 2, r: 3},
      {x: 2, y: 3},
    ]),
  ),
  runControllerCase(
    'parsed: a string r of an array',
    one({}, [
      [1, 2, 5],
      [5, 5, '7'],
    ]),
  ),
  // The parse of an insert reads getParsed (controller.bubble.js:49, :62,
  // :75, :152). Below the old length, the move of _parsed keeps the old
  // parsed items (core.datasetController.js:1000-1005). Thus the fallback
  // radius of a new item is the _custom of the old item at its index.
  runControllerCase(
    'parsed: an insert below the old length reads the old parsed item',
    {
      type: 'bubble',
      data: {
        labels: [1, 2, 3, 4],
        datasets: [
          {
            data: [
              {x: 1, y: 1, r: 5},
              {x: 2, y: 2, r: 6},
              {x: 3, y: 3, r: 7},
            ],
          },
          {
            data: [
              [1, 4, 8],
              [2, 3, 9],
            ],
          },
          {data: [3, 1, 2], radius: rawRadius},
        ],
      },
    },
    {
      steps: [
        ['splice', 0, 0, 0, {x: 9, y: 9}],
        ['splice', 1, 1, 0, [4, 1]],
        ['splice', 2, 1, 0, 4],
      ],
    },
  ),
  runControllerCase(
    'parsed: parsing false, object items with _custom',
    one({parsing: false}, [
      {x: 1, y: 2, _custom: 7},
      {x: 2, y: 3, _custom: 0},
      {x: 3, y: 1, _custom: '2'},
      {x: 4, y: 4},
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
      type: 'bubble',
      data: {
        labels,
        datasets: [
          {
            data: [1, 2, 3, 4, 5, 6].map((v) => ({x: v, y: 7 - v, r: v})),
          },
        ],
      },
    }),
  );
}

writeControllerReference(OUT, 'controllerBubble', cases, {title: 'bubble controller'});
