// Original code, not ported from Chart.js: tooltip plugin reference generator.
//
// It writes test/port/plugins/plugin_tooltip_reference.dart and
// test/port/plugins/plugin_tooltip_more_reference.dart, the data of
// test/port/plugins/plugin.tooltip_test.dart: real charts with the tooltip
// plugin of a build of the pinned Chart.js (Chart.js ADR 0041, section 3).
// See the headers of tool/reference/plugin_chart_common.mjs,
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases are the unit cases of Chart.js ADR 0041, section 3 item 7 (row
// `tooltip`): the modes `index`, `nearest`, `point`, `dataset`, `x` and `y`
// with `intersect`, the positioners `average`, `nearest` and a custom one,
// the callbacks of each text part, `xAlign` and `yAlign`, a caret near each
// edge, `rtl`, `textDirection`, `displayColors: false`, `usePointStyle`,
// `boxPadding`, `padding`, `filter`, `itemSort`, `footer`, `external`,
// `enabled: false`, the steps `hover`, `mouseout`, `setTooltip` and `click`
// with `events: ['click']`. More cases cover the chart types of Chart.js
// ADR 0039, section 15 (bar, pie, polar area, scatter), a label color with
// a border radius, a dash and a border width object, and the tooltip border
// with a corner radius object. The more cases and the full case are in the
// second data file. The draw calls come after the last step, so each case
// ends on the state under test.
//
// The case `textDirection rtl` writes the `direction` of `canvas.style`
// (`overrideTextDirection`, helpers.rtl.ts:55-73): the fake canvas has the
// style of `domStyle` (scale_chart_common.mjs). The draw calls do not show
// the calls of the style.
//
// The full case `full: title, filler and clickLegend` (Chart.js ADR 0041,
// section 4 item 3) has the default plugin options with a title, a fill
// and a tooltip in the mode `index`: the step `clickLegend` hides the
// dataset 1, and the tooltip items of the next `hover` leave it out.
//
// Each unit case sets `options.plugins` with unitPlugins(['legend',
// 'tooltip']): the plugin set of the Dart test file in wave 3 (Chart.js ADR
// 0041, sections 4 and 7). The observation has the key
// `plugins.tooltip` (the observer `observeTooltip` below and in the Dart
// test file). The test file runs the cases again with the light preset
// (theming.md section 8 test 3).
//
// A `hover` or `click` step needs the pixel position of a data element. The
// generator builds the chart of the case once without steps, reads the
// center point of the element (`getCenterPoint`: the point, the middle of a
// bar, the middle of an arc) and rounds it (pointStep below), as the Dart
// harness rounds the offsets of an event. Thus the step has integers.
//
// The custom positioner is the key `custom` of `Tooltip.positioners`: the
// generator writes it before the cases, and the Dart test file writes the
// same function in its `main()`.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/plugin_tooltip_reference.mjs
//
// The path can also be the first argument.

import {fileURLToPath} from 'node:url';

import {
  loadChartJs,
  plain,
  registerBuiltins,
  runPluginCase,
  unitPlugins,
  writeControllerReference,
} from './plugin_chart_common.mjs';
import {makeChart, named} from './controller_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/plugins/plugin_tooltip_reference.dart', import.meta.url),
);
const OUT_MORE = fileURLToPath(
  new URL('../../test/port/plugins/plugin_tooltip_more_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerBuiltins(C);

/** The log of each chart: the calls of the callback `external`. */
const logs = new WeakMap();

/** Adds [entry] to the log of [chart]. */
function log(chart, entry) {
  if (!logs.has(chart)) logs.set(chart, []);
  logs.get(chart).push(entry);
}

// The custom positioner (Chart.js ADR 0039, section 4): it reads `this`,
// the tooltip, and gives the alignment. The Dart test file writes the same
// function into `Tooltip.positioners`.
C.Tooltip.positioners.custom = function (items, eventPosition) {
  if (!items.length) {
    return false;
  }
  const area = this.chart.chartArea;
  return {x: area.left + 20, y: eventPosition.y, xAlign: 'left', yAlign: 'top'};
};

/** callbacks.title: a list of two lines. */
const cbTitle = named('cbTitle', () => ['Title A', 'Title B']);
/** callbacks.afterTitle: a text with a newline. */
const cbAfterTitle = named('cbAfterTitle', () => 'After 1\nAfter 2');
/** callbacks.beforeBody: a number, a line that is not a string. */
const cbBeforeBody = named('cbBeforeBody', () => 5);
/** callbacks.beforeLabel: the dataset index and the data index. */
const cbBeforeLabel = named(
  'cbBeforeLabel',
  (item) => 'Item ' + item.datasetIndex + '.' + item.dataIndex,
);
/** callbacks.label: two lines for the dataset 0, else the default. */
const cbLabel = named('cbLabel', (item) =>
  item.datasetIndex === 0 ? ['Line 1', 'Line 2'] : undefined,
);
/** callbacks.afterLabel: null, which skips the default. */
const cbAfterLabel = named('cbAfterLabel', () => null);
/** callbacks.afterBody: a text with a newline. */
const cbAfterBody = named('cbAfterBody', () => 'End 1\nEnd 2');
/** callbacks.beforeFooter: a text. */
const cbBeforeFooter = named('cbBeforeFooter', () => 'Before footer');
/** callbacks.footer: the count of the items. */
const cbFooter = named('cbFooter', (items) => 'Count: ' + items.length);
/** callbacks.afterFooter: an empty text, which pushes nothing. */
const cbAfterFooter = named('cbAfterFooter', () => '');
/** callbacks.labelTextColor: a color for each dataset. */
const cbLabelTextColor = named('cbLabelTextColor', (item) =>
  item.datasetIndex === 0 ? 'red' : 'blue',
);

/** filter: leaves out the dataset 1. */
const tooltipFilter = named('tooltipFilter', (item) => item.datasetIndex !== 1);
/** itemSort: the items in the reverse order of their dataset index. */
const tooltipSort = named('tooltipSort', (a, b) => b.datasetIndex - a.datasetIndex);

/** external: logs `replay`, the identity of `this` and the keys. */
const tooltipExternal = named('tooltipExternal', function (context) {
  log(
    this.chart,
    'external ' +
      String(context.replay) +
      ' ' +
      String(context.tooltip === this) +
      ' ' +
      Object.keys(context).join(','),
  );
});

/** labelColor: a border width object, a dash and a border radius. */
const roundLabelColor = named('roundLabelColor', (item) => ({
  borderColor: item.datasetIndex === 0 ? 'red' : 'green',
  backgroundColor: 'blue',
  borderWidth: {top: 1, left: 2},
  borderDash: [2, 1],
  borderDashOffset: 1,
  borderRadius: 3,
}));

/**
 * The observer `plugins.tooltip` (Chart.js ADR 0041, section 3 item 4):
 * `null` without a tooltip, else the members of the model, the plain
 * `dataPoints` without `chart`, `dataset` and `element`, the active items
 * `[datasetIndex, index]` and the log of the `external` callback.
 */
function observeTooltip(chart) {
  const t = chart.tooltip;
  if (!t) return null;
  return {
    opacity: t.opacity,
    x: t.x,
    y: t.y,
    width: t.width,
    height: t.height,
    caretX: t.caretX,
    caretY: t.caretY,
    xAlign: t.xAlign,
    yAlign: t.yAlign,
    title: plain(t.title),
    beforeBody: plain(t.beforeBody),
    body: plain(t.body),
    afterBody: plain(t.afterBody),
    footer: plain(t.footer),
    labelColors: plain(t.labelColors),
    labelPointStyles: plain(t.labelPointStyles),
    labelTextColors: plain(t.labelTextColors),
    dataPoints:
      t.dataPoints === undefined
        ? undefined
        : t.dataPoints.map((p) => ({
            datasetIndex: p.datasetIndex,
            dataIndex: p.dataIndex,
            label: p.label,
            formattedValue: p.formattedValue,
            parsed: plain(p.parsed),
            raw: plain(p.raw),
          })),
    active: t.getActiveElements().map((a) => [a.datasetIndex, a.index]),
    log: [...(logs.get(chart) ?? [])],
  };
}

/** A copy of a config that keeps the functions, for the probe chart. */
function copy(v) {
  if (Array.isArray(v)) return v.map(copy);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.keys(v).map((k) => [k, copy(v[k])]));
  }
  return v;
}

/** The canvas of the case: 400 x 300 unless the case gives one. */
const canvas = (width = 400, height = 300) => ({canvas: {width, height}});

/**
 * The step `[action, x, y]` at the rounded center point of the element [index]
 * of the dataset [datasetIndex] of the chart of [config], with the offsets
 * [dx] and [dy]. A `y` of `'top'` is the top of the chart area plus [dy].
 */
function pointStep(action, config, datasetIndex, index, {dx = 0, dy = 0, y, options} = {}) {
  const chart = makeChart(copy(config), copy(options ?? canvas()));
  try {
    const el = chart.getDatasetMeta(datasetIndex).data[index].getCenterPoint();
    const px = Math.round(el.x + dx);
    const py = y === 'top' ? Math.round(chart.chartArea.top + dy) : Math.round(el.y + dy);
    return [action, px, py];
  } finally {
    chart.destroy();
  }
}

const DATASETS = [
  {label: 'Dataset 1', data: [10, 30, 20, 40], borderColor: 'blue', backgroundColor: 'red'},
  {label: 'Dataset 2', data: [25, 5, 35, 15], borderColor: 'green', pointStyle: 'rectRot'},
  {label: 'Dataset 3', data: [5, 15, 10, 30], borderDash: [4, 2], pointStyle: 'triangle'},
];

/**
 * A chart of the type [type] with the three datasets of DATASETS (each with
 * the options [extra]), the labels `Jan` to `Apr`, the tooltip options
 * [tooltipOptions] and the legend options [legend]. [chartOptions] go into
 * the chart options.
 */
function chart(
  tooltipOptions,
  {type = 'line', extra = {}, chartOptions = {}, count = 3, legend} = {},
) {
  const datasets = DATASETS.slice(0, count).map((d) => ({...d, data: [...d.data], ...extra}));
  return {
    type,
    data: {labels: ['Jan', 'Feb', 'Mar', 'Apr'], datasets},
    options: {
      ...chartOptions,
      plugins: unitPlugins(['legend', 'tooltip'], {
        ...(legend === undefined ? {} : {legend}),
        ...(tooltipOptions === undefined ? {} : {tooltip: tooltipOptions}),
      }),
    },
  };
}

/** runPluginCase with the observer of the tooltip. */
const tooltipCase = (name, config, opts = {}) =>
  runPluginCase(name, config, {options: canvas(), ...opts, observers: {tooltip: observeTooltip}});

/** A case with one `hover` at the element [index] of the dataset [d]. */
function hoverCase(name, config, d, index, pointOptions = {}, opts = {}) {
  return tooltipCase(name, config, {
    ...opts,
    steps: [pointStep('hover', config, d, index, {...pointOptions, options: opts.options})],
  });
}

const pie = (tooltipOptions, type = 'pie') => ({
  type,
  data: {
    labels: ['Red', 'Green', 'Blue'],
    datasets: [
      {label: 'Votes', data: [12, 19, 7], backgroundColor: ['red', 'green', 'blue']},
    ],
  },
  options: {
    plugins: unitPlugins(
      ['legend', 'tooltip'],
      tooltipOptions === undefined ? {} : {tooltip: tooltipOptions},
    ),
  },
});

const scatter = (tooltipOptions) => ({
  type: 'scatter',
  data: {
    datasets: [
      {label: 'A', data: [{x: 1, y: 2}, {x: 3, y: 5}, {x: 6, y: 1}], backgroundColor: 'red'},
      {label: 'B', data: [{x: 2, y: 4}, {x: 5, y: 3}], backgroundColor: 'blue'},
    ],
  },
  options: {
    plugins: unitPlugins(
      ['legend', 'tooltip'],
      tooltipOptions === undefined ? {} : {tooltip: tooltipOptions},
    ),
  },
});

const indexChart = chart({mode: 'index', intersect: false});
const callbacksChart = chart({
  mode: 'index',
  intersect: false,
  callbacks: {
    title: cbTitle,
    afterTitle: cbAfterTitle,
    beforeBody: cbBeforeBody,
    beforeLabel: cbBeforeLabel,
    label: cbLabel,
    afterLabel: cbAfterLabel,
    afterBody: cbAfterBody,
    beforeFooter: cbBeforeFooter,
    footer: cbFooter,
    afterFooter: cbAfterFooter,
    labelTextColor: cbLabelTextColor,
  },
});
const externalChart = chart({mode: 'index', intersect: false, external: tooltipExternal});
const clickChart = chart({mode: 'nearest', intersect: true, events: ['click']});
const mouseoutChart = chart({mode: 'nearest', intersect: true});

const cases = [
  hoverCase('mode index with intersect false', indexChart, 0, 1, {y: 'top', dy: 10}),
  hoverCase('mode nearest with intersect true', chart({mode: 'nearest', intersect: true}), 0, 1),
  hoverCase('mode point', chart({mode: 'point', intersect: true}), 1, 2),
  hoverCase('mode dataset', chart({mode: 'dataset', intersect: true}), 2, 2),
  hoverCase('mode x with intersect false', chart({mode: 'x', intersect: false}), 0, 2, {dx: 3}),
  hoverCase('mode y with intersect false', chart({mode: 'y', intersect: false}), 1, 0, {dx: 40}),
  hoverCase(
    'position nearest',
    chart({mode: 'index', intersect: false, position: 'nearest'}),
    1,
    2,
    {dy: -12},
  ),
  hoverCase(
    'a custom positioner',
    chart({mode: 'index', intersect: false, position: 'custom'}),
    0,
    2,
  ),
  hoverCase('the callbacks of each text part', callbacksChart, 0, 1, {y: 'top', dy: 10}),
  hoverCase(
    'the options xAlign and yAlign',
    chart({mode: 'nearest', intersect: true, xAlign: 'right', yAlign: 'bottom'}),
    0,
    2,
  ),
  hoverCase('a caret near the left edge', chart({mode: 'index', intersect: false}), 0, 0),
  hoverCase('a caret near the right edge', chart({mode: 'index', intersect: false}), 0, 3),
  hoverCase(
    'a caret near the top edge',
    chart({mode: 'nearest', intersect: true}, {legend: false}),
    0,
    3,
  ),
  hoverCase(
    'a caret near the bottom edge',
    chart({mode: 'nearest', intersect: true, callbacks: {footer: cbFooter}}, {legend: false}),
    1,
    1,
  ),
  hoverCase('rtl', chart({mode: 'index', intersect: false, rtl: true}), 0, 1, {y: 'top', dy: 10}),
  hoverCase(
    'textDirection rtl',
    chart({mode: 'index', intersect: false, rtl: true, textDirection: 'rtl'}),
    0,
    1,
    {y: 'top', dy: 10},
  ),
  hoverCase(
    'displayColors false',
    chart({mode: 'index', intersect: false, displayColors: false}),
    0,
    1,
  ),
  hoverCase(
    'usePointStyle',
    chart(
      {mode: 'index', intersect: false, usePointStyle: true, boxWidth: 10, boxHeight: 8},
      {extra: {pointRotation: 30}},
    ),
    0,
    1,
  ),
  hoverCase(
    'boxPadding and padding',
    chart({
      mode: 'index',
      intersect: false,
      boxPadding: 4,
      padding: {left: 10, top: 4, right: 8, bottom: 6},
    }),
    0,
    2,
  ),
  hoverCase('filter', chart({mode: 'index', intersect: false, filter: tooltipFilter}), 0, 1),
  hoverCase('itemSort', chart({mode: 'index', intersect: false, itemSort: tooltipSort}), 0, 1),
  hoverCase(
    'footer and the text aligns',
    chart({
      mode: 'index',
      intersect: false,
      titleAlign: 'center',
      bodyAlign: 'right',
      footerAlign: 'center',
      callbacks: {footer: cbFooter},
    }),
    0,
    2,
  ),
  tooltipCase('external', externalChart, {
    steps: [
      pointStep('hover', externalChart, 0, 1),
      ['update'],
      ['setTooltip', [[1, 2]], 120, 80],
    ],
  }),
  hoverCase('enabled false', chart({mode: 'index', intersect: false, enabled: false}), 0, 1),
  tooltipCase('hover then mouseout', mouseoutChart, {
    steps: [pointStep('hover', mouseoutChart, 0, 1), ['mouseout']],
  }),
  tooltipCase('setTooltip on a bar chart', chart(undefined, {type: 'bar'}), {
    steps: [['setTooltip', [[0, 1], [2, 1]], 150, 120]],
  }),
  tooltipCase('click with events click', clickChart, {
    steps: [pointStep('hover', clickChart, 0, 1), pointStep('click', clickChart, 0, 1)],
  }),
];

// The more cases go into their own data file, plugin_tooltip_more_reference.dart:
// one file of all cases is above the limit of 2,500,000 bytes for each data
// file (Chart.js ADR 0041, section 4 item 4; Chart.js ADR 0030, section 3
// item 6). The Dart test file runs the cases of both files.
const moreCases = [
  hoverCase('a bar chart in mode index', chart({mode: 'index'}, {type: 'bar'}), 1, 2),
  hoverCase('a pie chart', pie(), 0, 1),
  hoverCase('a polar area chart', pie(undefined, 'polarArea'), 0, 0),
  hoverCase(
    'a scatter chart with the positioner nearest',
    scatter({mode: 'nearest', intersect: false, position: 'nearest'}),
    0,
    1,
    {dx: 6, dy: 4},
  ),
  hoverCase(
    'a label color with a border radius',
    chart({mode: 'index', intersect: false, callbacks: {labelColor: roundLabelColor}}, {count: 2}),
    0,
    1,
  ),
  hoverCase(
    'a corner radius object and a border',
    chart({
      mode: 'nearest',
      intersect: true,
      cornerRadius: {topLeft: 2, topRight: 8, bottomLeft: 0, bottomRight: 4},
      caretSize: 8,
      borderWidth: 2,
      borderColor: 'orange',
    }),
    2,
    1,
  ),
];

// ---------------------------------------------------------------------------
// The full cases of Chart.js ADR 0041, section 4 item 2 (wave 4): the
// default plugin options, so each registered plugin runs (no unitPlugins).
// A full case exists only where another plugin changes the result (section
// 4 item 3).

/** A line chart with the three datasets, a title, a fill and a tooltip. */
const fullChart = {
  type: 'line',
  data: {
    labels: ['Jan', 'Feb', 'Mar', 'Apr'],
    datasets: DATASETS.map((d, i) => ({
      ...d,
      data: [...d.data],
      ...(i === 0 ? {fill: 'origin'} : {}),
    })),
  },
  options: {
    plugins: {
      title: {display: true, text: 'Chart title'},
      tooltip: {mode: 'index', intersect: false},
    },
  },
};

moreCases.push(
  tooltipCase('full: title, filler and clickLegend', fullChart, {
    steps: [['clickLegend', 1], pointStep('hover', fullChart, 0, 1, {y: 'top', dy: 10})],
  }),
);

writeControllerReference(OUT, 'pluginTooltip', cases, {title: 'tooltip plugin'});
writeControllerReference(OUT_MORE, 'pluginTooltipMore', moreCases, {
  title: 'more tooltip plugin',
});
