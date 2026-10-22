// Original code, not ported from Chart.js: polar area controller reference generator.
//
// It writes test/port/controllers/controller_polar_area_reference.dart, the
// data of test/port/controllers/controller.polarArea_test.dart: real polar
// area charts of a build of the pinned Chart.js (Chart.js ADR 0030). See the
// headers of tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases:
// - The 9 cases of Chart.js ADR 0030, section 7 (the row `polarArea`). The
//   first case is `default`, with the options of the scales. The test file
//   runs them again with the light preset (theming.md section 8 test 3).
// - The pin cases of Chart.js ADR 0036, section 9 (names that start with
//   `parsed:`, the polar area rows of the parsed-data spec, section 7.3) and
//   of Chart.js ADR 0028, section 8 (names that start with `interfaces:`,
//   the polar area rows of the interfaces spec, section 7.3). The themed run
//   does not run them.
// - The cases `interfaces: sharing, ...` use the type `polarAreaSharing`: a
//   subclass of PolarAreaController with `enableOptionSharing = true` and
//   its own id. This generator registers it before these cases and
//   unregisters it after them. The test file does the same in a group.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/controller_polar_area_reference.mjs
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
  new URL('../../test/port/controllers/controller_polar_area_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerPhase7(C);

// ---------------------------------------------------------------------------
// The named functions of the configs ('fn:<name>' in the data).

/** A scriptable `angle`: 30 degrees more for each data index. */
const angleByIndex = named('angleByIndex', (ctx) => ctx.dataIndex * 30 + 30);

/** A scriptable option that gives 0. */
const zero = named('zero', () => 0);

// ---------------------------------------------------------------------------
// The probes of the key `extra`.

/**
 * The probe `polarState`: for each dataset, the values of the controller
 * that the observations do not have: countVisibleElements(), the range of
 * getMinMax() (the `ToNumber` of each end, as core.scale.js:315 and :318
 * apply), innerRadius and outerRadius of _updateRadius, and whether the
 * options of each arc are frozen.
 */
const polarState = named('polarState', (chart) =>
  chart.data.datasets.map((_, i) => {
    const c = chart.getDatasetMeta(i).controller;
    const {min, max} = c.getMinMax();
    return {
      count: c.countVisibleElements(),
      minMax: [Number(min), Number(max)],
      radii: [c.innerRadius, c.outerRadius],
      frozen: c._cachedMeta.data.map((a) => Object.isFrozen(a.options)),
    };
  }),
);

/**
 * The probe `legend`: the two legend functions of
 * `overrides.polarArea.plugins.legend` (Chart.js ADR 0028, section 6).
 * `noLegend` is the result of generateLabels without `chart.legend`, or the
 * name of its error. Then the probe puts a test legend in `chart.legend`:
 * `items` and `keys` (the keys of each item in order) of generateLabels,
 * then onClick({}, {index: 1}, legend), then `visible1`
 * (getDataVisibility(1)), `hidden` (the `hidden` of each new item) and
 * `outer` (the outerRadius of each arc of the dataset 0). At its end, the
 * chart has no legend again.
 */
const legend = named('legend', (chart) => {
  const fns = C.Chart.overrides.polarArea.plugins.legend;
  const out = {};
  try {
    out.noLegend = fns.labels.generateLabels(chart);
  } catch (e) {
    out.noLegend = e.name;
  }
  chart.legend = {
    chart,
    options: {
      labels: {
        pointStyle: 'circle',
        textAlign: 'left',
        color: '#666',
        useBorderRadius: true,
        borderRadius: 0,
      },
    },
  };
  out.items = fns.labels.generateLabels(chart);
  out.keys = out.items.map((item) => Object.keys(item));
  fns.onClick({}, {index: 1}, chart.legend);
  out.visible1 = chart.getDataVisibility(1);
  out.hidden = fns.labels.generateLabels(chart).map((item) => item.hidden);
  out.outer = chart.getDatasetMeta(0).data.map((a) => a.outerRadius);
  delete chart.legend;
  return out;
});

/**
 * Runs [fn] with the `updateConfig` of BasePlatform on BasicPlatform.
 * BasicPlatform, the platform of Node.js, writes `animation: false` into
 * the options (platform.basic.js:20-22). The DOM platform of a browser and
 * the platform of the port (platform.flutter.dart) keep the option: they
 * have the no-op of platform.base.js:80-82. The case `reset` needs the
 * option for the branches `animateScale` and `animateRotate` of
 * controller.polarArea.js:185-192. Its `duration: 0` sets each value at
 * once (core.animations.js `_createAnimations`).
 */
function withBasePlatformConfig(fn) {
  const proto = C.BasicPlatform.prototype;
  const updateConfig = proto.updateConfig;
  proto.updateConfig = C.BasePlatform.prototype.updateConfig;
  try {
    return fn();
  } finally {
    proto.updateConfig = updateConfig;
  }
}

/** A polar area chart with the labels [labels] and one dataset [extra]. */
const one = (extra, labels = ['a', 'b', 'c', 'd']) => ({
  type: 'polarArea',
  data: {labels, datasets: [{data: [10, 15, 0, -4], ...extra}]},
});

// ---------------------------------------------------------------------------
// The 9 cases of Chart.js ADR 0030, section 7.

const cases = [
  runControllerCase(
    'default',
    {
      type: 'polarArea',
      data: {
        labels: ['a', 'b', 'c', 'd', 'e'],
        datasets: [
          {data: [10, 20, 5, 15], label: 'one'},
          {
            data: [5, 12, 8, 3],
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
      extras: {polarState},
    },
  ),
  runControllerCase('startAngle', {
    ...one({label: 'dataset2'}),
    options: {scales: {r: {startAngle: 90}}},
  }),
  runControllerCase(
    'angle',
    {
      type: 'polarArea',
      data: {
        labels: ['a', 'b', 'c', 'd'],
        datasets: [
          {data: [10, 15, 7, 4], angle: [120, 60, 0, null]},
          {data: [3, 9, 12, 6], angle: angleByIndex},
        ],
      },
    },
    {steps: [['setActive', [[0, 1]]]], extras: {polarState}},
  ),
  runControllerCase(
    'toggleDataVisibility',
    {
      type: 'polarArea',
      data: {labels: ['a', 'b', 'c', 'd'], datasets: [{data: [10, 20, 30, 40]}]},
    },
    {
      steps: [
        ['toggleDataVisibility', 1],
        ['toggleDataVisibility', 3],
        ['toggleDataVisibility', 1],
      ],
      extras: {polarState},
    },
  ),
  runControllerCase('spacing with the default spacingMode', {
    ...one({spacing: 6, borderWidth: 1}),
  }),
  runControllerCase('spacing with the chart-level spacingMode override', {
    ...one({}),
    options: {spacing: 12, spacingMode: 'parallel'},
  }),
  runControllerCase(
    'scale r min and max',
    {
      type: 'polarArea',
      data: {labels: ['a', 'b', 'c', 'd'], datasets: [{data: [2, 10, 30, 18]}]},
      options: {scales: {r: {min: 5, max: 25}}},
    },
    {extras: {polarState}},
  ),
  withBasePlatformConfig(() =>
    runControllerCase(
      'reset',
      {
        ...one({}),
        options: {animation: {duration: 0, animateRotate: true, animateScale: true}},
      },
      {steps: [['reset'], ['update']], extras: {polarState}},
    ),
  ),
  runControllerCase('point labels', {
    type: 'polarArea',
    data: {
      labels: ['North', 'East', 'South', 'West'],
      datasets: [{data: [8, 4, 6, 2]}],
    },
    options: {scales: {r: {pointLabels: {display: true}}}},
  }),
];

if (cases.length !== 9) throw new Error(`${cases.length} cases; ADR 0030 gives 9.`);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0036 (parsed-data spec, section 7.3).

/** A polar area chart with `parsing: false` and the data [data]. */
const unparsed = (data) => ({
  type: 'polarArea',
  data: {labels: ['a', 'b', 'c'], datasets: [{data, parsing: false}]},
});

for (const [label, data] of [
  ['an absent r', [{r: 1}, {}, {r: 3}]],
  ['a null r', [{r: 1}, {r: null}, {r: 3}]],
  ['numbers', [5, 3]],
  ['Lists', [[5], [3]]],
  ['string r values', [{r: '10'}, {r: '9'}, {r: '30'}]],
  ['number r values', [{r: 10}, {r: 9}, {r: 30}]],
]) {
  cases.push(
    runControllerCase(`parsed: parsing false, ${label}`, unparsed(data), {
      extras: {polarState},
    }),
  );
}
cases.push(
  runControllerCase('parsed: parsing false, a null item', unparsed([{r: 1}, null, {r: 3}])),
);

// ---------------------------------------------------------------------------
// The pin cases of Chart.js ADR 0028 (interfaces spec, section 7.3).

cases.push(
  runControllerCase('interfaces: an rScale that is not radial', {
    ...one({}),
    options: {scales: {r: {type: 'linear'}}},
  }),
);

for (const [label, labels] of [
  ['1', [['line 1', 'line 2'], 5, 0, 'd', undefined]],
  ['2', [['line 1', 'line 2'], 7, '', null, 'e']],
]) {
  cases.push(
    runControllerCase(`interfaces: the labels of getLabelAndValue, set ${label}`, {
      type: 'polarArea',
      data: {labels, datasets: [{data: [1, 2, 3, 4, 5, 6]}]},
    }),
  );
}

/**
 * The 11 rows of the ADR 0028 table (Measurements, question 5): the
 * dataset keys and the chart options of each row.
 */
const SPACING_ROWS = [
  ['no options', {}, {}],
  ['chart spacing 12, spacingMode parallel', {}, {spacing: 12, spacingMode: 'parallel'}],
  ['dataset spacing 5, spacingMode parallel', {spacing: 5, spacingMode: 'parallel'}, {}],
  [
    'datasets.polarArea spacing 4, parallel',
    {},
    {datasets: {polarArea: {spacing: 4, spacingMode: 'parallel'}}},
  ],
  [
    'elements.arc spacing 3, parallel',
    {},
    {elements: {arc: {spacing: 3, spacingMode: 'parallel'}}},
  ],
  [
    'elements.arc spacing 0, angular',
    {},
    {elements: {arc: {spacing: 0, spacingMode: 'angular'}}},
  ],
  ['chart spacing 12, elements.arc spacing 0', {}, {spacing: 12, elements: {arc: {spacing: 0}}}],
  [
    'chart spacing 7, elements.arc spacing fn 0',
    {},
    {spacing: 7, elements: {arc: {spacing: zero}}},
  ],
  [
    'chart spacing 7, elements.arc parallel',
    {},
    {spacing: 7, elements: {arc: {spacingMode: 'parallel'}}},
  ],
  ['dataset spacing 0, chart spacing 7', {spacing: 0}, {spacing: 7}],
  [
    'dataset angular, chart parallel',
    {spacingMode: 'angular'},
    {spacingMode: 'parallel'},
  ],
];

/**
 * A copy of [v]: the chart writes into its config, and the rows serve two
 * charts. A function stays the same function.
 */
const fresh = (v) => {
  if (Array.isArray(v)) return v.map(fresh);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.keys(v).map((k) => [k, fresh(v[k])]));
  }
  return v;
};

/**
 * The chart of a spacing row of the type [type]. The key `polarArea` of
 * `options.datasets` becomes [type]: the row of the ADR table names the
 * dataset defaults of the chart type.
 */
const spacingChart = (type, dataset, options) => {
  const chartOptions = fresh(options);
  if (chartOptions.datasets) {
    chartOptions.datasets = {[type]: chartOptions.datasets.polarArea};
  }
  return {
    type,
    data: {labels: ['a', 'b'], datasets: [{data: [10, 20], ...fresh(dataset)}]},
    options: chartOptions,
  };
};

for (const [label, dataset, options] of SPACING_ROWS) {
  cases.push(
    runControllerCase(
      `interfaces: spacing, ${label}`,
      spacingChart('polarArea', dataset, options),
      {steps: [['update']], extras: {polarState}},
    ),
  );
}
cases.push(
  runControllerCase(
    'interfaces: spacing hover, elements.arc angular',
    spacingChart('polarArea', {}, {elements: {arc: {spacing: 0, spacingMode: 'angular'}}}),
    {steps: [['setActive', [[0, 0]]], ['update']], extras: {polarState}},
  ),
);

/**
 * The test subclass of Chart.js ADR 0028, section 5: the pinned controller
 * with `enableOptionSharing = true` and its own id.
 */
class PolarAreaSharing extends C.PolarAreaController {
  static id = 'polarAreaSharing';

  initialize() {
    this.enableOptionSharing = true;
    super.initialize();
  }
}

C.Chart.register(PolarAreaSharing);
for (const [label, dataset, options] of SPACING_ROWS) {
  cases.push(
    runControllerCase(
      `interfaces: sharing, ${label}`,
      spacingChart('polarAreaSharing', dataset, options),
      {steps: [['update']], extras: {polarState}},
    ),
  );
}
C.Chart.unregister(PolarAreaSharing);

for (const [label, labels] of [
  ['with labels', ['a', ['b1', 'b2'], 'c']],
  ['without labels', []],
]) {
  cases.push(
    runControllerCase(
      `interfaces: the legend functions, ${label}`,
      {
        type: 'polarArea',
        data: {
          labels,
          datasets: [
            {
              data: [1, 2, 3],
              backgroundColor: ['red', 'green', 'blue'],
              borderRadius: 3,
            },
          ],
        },
      },
      {extras: {legend}},
    ),
  );
}

writeControllerReference(OUT, 'controllerPolarArea', cases, {title: 'polar area'});
