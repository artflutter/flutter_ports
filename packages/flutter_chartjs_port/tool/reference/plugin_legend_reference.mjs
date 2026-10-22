// Original code, not ported from Chart.js: legend plugin reference generator.
//
// It writes test/port/plugins/plugin_legend_reference.dart, the data of
// test/port/plugins/plugin.legend_test.dart: real charts with the legend
// plugin of a build of the pinned Chart.js (Chart.js ADR 0041, section 3).
// See the headers of tool/reference/plugin_chart_common.mjs,
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases are the unit cases of Chart.js ADR 0041, section 3 item 7 (row
// `legend`): each `position`, each `align`, `rtl`, `reverse`, `fullSize:
// false`, `maxWidth` and `maxHeight`, `usePointStyle`, `pointStyleWidth`,
// `boxWidth`, `boxHeight`, `padding`, `filter`, `sort`, `textAlign`, the
// title with `position`, rows that wrap, columns that overflow, a hidden
// dataset, `onHover` and `onLeave` with `hoverLegend`, `clickLegend` and
// `display: false`. Four more cases cover the rounded box of
// `useBorderRadius` (the `adapt-rounded-rect-path` translation of the Dart
// test), the doughnut override of `generateLabels` with multiline labels
// (the `_fitCols` heights of an array text) and its `onClick`, and the
// position `chartArea`. The draw calls come after the last step, so each
// case ends on the state under test.
//
// No case draws the point style `circle` with a `pointStyleWidth`: that
// path calls `ctx.ellipse`, which the mock context has not (Chart.js ADR
// 0041, Open 3). The `pointStyleWidth` case uses `rect` and `line`, which
// read the width too (helpers.canvas.ts:237-241, :289-293).
//
// Each case sets `options.plugins` with unitPlugins(['legend']): the Dart
// test file registers only the legend plugin until wave 4 (Chart.js ADR
// 0041, sections 4 and 7). The observation has the key `plugins.legend`
// (the observer `observeLegend` below and in the Dart test file). The test
// file runs the cases again with the light preset (theming.md section 8
// test 3).
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/plugin_legend_reference.mjs
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
import {named} from './controller_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/plugins/plugin_legend_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerBuiltins(C);

/** The callback log of each chart: `<callback> <event type> <item text>`. */
const logs = new WeakMap();

/** Adds the entry of the callback [name] to the log of the chart. */
function log(name, e, item, legend) {
  const chart = legend.chart;
  if (!logs.has(chart)) logs.set(chart, []);
  logs.get(chart).push(`${name} ${e.type} ${String(item.text)}`);
}

const logClick = named('logClick', (e, item, legend) => log('onClick', e, item, legend));
const logHover = named('logHover', (e, item, legend) => log('onHover', e, item, legend));
const logLeave = named('logLeave', (e, item, legend) => log('onLeave', e, item, legend));

/** labels.filter: leaves out the items whose text ends in `2`. */
const legendFilter = named('legendFilter', (item) => !String(item.text).endsWith('2'));

/** labels.sort: the items in the reverse order of their dataset index. */
const legendSort = named('legendSort', (a, b) => b.datasetIndex - a.datasetIndex);

/** The plain copy of [v] without the keys whose values are functions. */
function withoutFunctions(v) {
  if (Array.isArray(v)) return v.map(withoutFunctions);
  if (v && typeof v === 'object') {
    const out = {};
    for (const [key, value] of Object.entries(v)) {
      if (value !== '<fn>') out[key] = withoutFunctions(value);
    }
    return out;
  }
  return v;
}

/**
 * The observer `plugins.legend` (Chart.js ADR 0041, section 3 item 4):
 * `null` without a legend, else `legendItems` (each key of each item),
 * `legendHitBoxes`, `lineWidths`, `columnSizes`, the callback `log` of the
 * case and the plain `options.labels` without the function values.
 * `_hoveredItem` is private in the port (Chart.js ADR 0012): the log shows
 * its effect.
 */
function observeLegend(chart) {
  const legend = chart.legend;
  if (!legend) return null;
  return {
    legendItems: plain(legend.legendItems),
    legendHitBoxes: plain(legend.legendHitBoxes),
    lineWidths: plain(legend.lineWidths),
    columnSizes: plain(legend.columnSizes),
    log: [...(logs.get(chart) ?? [])],
    labels: withoutFunctions(plain(legend.options.labels)),
  };
}

const DATASETS = [
  {label: 'Dataset 1', data: [10, 30, 20, 40], borderColor: 'blue', backgroundColor: 'red'},
  {label: 'Dataset 2', data: [25, 5, 35, 15], borderColor: 'green', borderWidth: 6},
  {label: 'A longer dataset 3', data: [5, 15, 10, 30], borderDash: [4, 2], pointStyle: 'rectRot'},
];

/**
 * A line chart with [count] datasets (the first three of DATASETS, then
 * `Dataset <n>`), the dataset options [extra] for each dataset and the
 * legend options [legendOptions].
 */
function line(legendOptions, {count = 3, extra = {}, type = 'line'} = {}) {
  const datasets = [];
  for (let i = 0; i < count; i++) {
    const base = DATASETS[i] ?? {label: `Dataset ${i + 1}`, data: [i, 2 * i, i + 3, 1]};
    datasets.push({...base, data: [...base.data], ...extra});
  }
  return {
    type,
    data: {labels: ['January', 'February', 'March', 'April'], datasets},
    options: {
      plugins: unitPlugins(['legend'], legendOptions === undefined ? {} : {legend: legendOptions}),
    },
  };
}

/** The canvas of the case: 400 x 300 unless the case gives one. */
const canvas = (width = 400, height = 300) => ({canvas: {width, height}});

/** runPluginCase with the observer of the legend. */
const legendCase = (name, config, opts = {}) =>
  runPluginCase(name, config, {options: canvas(), ...opts, observers: {legend: observeLegend}});

const cases = [
  legendCase('position top (the default)', line()),
  legendCase('position bottom', line({position: 'bottom'})),
  legendCase('position left', line({position: 'left'})),
  legendCase('position right', line({position: 'right'})),
  legendCase('position chartArea', line({position: 'chartArea'})),
  legendCase('align start', line({align: 'start'})),
  legendCase('align end', line({align: 'end'})),
  legendCase('align start at the left', line({position: 'left', align: 'start'})),
  legendCase('align end at the right', line({position: 'right', align: 'end'})),
  legendCase('rtl', line({rtl: true, align: 'start'})),
  legendCase('rtl at the left', line({rtl: true, position: 'left'})),
  legendCase('reverse', line({reverse: true})),
  legendCase('fullSize false', line({position: 'left', fullSize: false})),
  legendCase('maxWidth', line({position: 'right', maxWidth: 60})),
  legendCase('maxHeight', line({maxHeight: 20}, {count: 9})),
  legendCase('usePointStyle', line({labels: {usePointStyle: true}}, {extra: {pointRotation: 30}})),
  legendCase(
    'pointStyleWidth',
    line({labels: {usePointStyle: true, pointStyle: 'rect', pointStyleWidth: 30}}),
    {steps: [['setOption', 'plugins.legend.labels.pointStyle', 'line']]},
  ),
  legendCase('boxWidth and boxHeight', line({labels: {boxWidth: 20, boxHeight: 6}})),
  legendCase('padding', line({position: 'left', labels: {padding: 25}})),
  legendCase('filter', line({labels: {filter: legendFilter}})),
  legendCase('sort', line({labels: {sort: legendSort}})),
  legendCase('textAlign', line({position: 'right', labels: {textAlign: 'right'}})),
  legendCase(
    'title with position start',
    line({title: {display: true, text: 'Legend title', position: 'start'}}),
  ),
  legendCase(
    'title with position end at the left',
    line({position: 'left', title: {display: true, text: 'Title', position: 'end', padding: 6}}),
  ),
  legendCase('rows that wrap', line({}, {count: 9}), {options: canvas(300, 300)}),
  legendCase('columns that overflow', line({position: 'left'}, {count: 9}), {
    options: canvas(400, 120),
  }),
  legendCase('a hidden dataset', line(), {
    steps: [['setDatasetVisibility', 1, false]],
  }),
  legendCase('hoverLegend with onHover and onLeave', line({onHover: logHover, onLeave: logLeave}), {
    steps: [['hoverLegend', 0], ['hoverLegend', 0], ['hoverLegend', 2], ['mouseout']],
  }),
  legendCase('clickLegend', line(), {
    steps: [['clickLegend', 1], ['clickLegend', 2], ['clickLegend', 1]],
  }),
  legendCase('clickLegend with onClick', line({onClick: logClick}), {
    steps: [['clickLegend', 0], ['click', 1, 1]],
  }),
  legendCase('display false', line({display: false}), {
    steps: [['setOption', 'plugins.legend.display', true]],
  }),
  legendCase(
    'useBorderRadius',
    line({labels: {useBorderRadius: true, borderRadius: 4}}, {type: 'bar', extra: {borderWidth: 2}}),
  ),
  legendCase(
    'doughnut with multiline labels',
    {
      type: 'doughnut',
      data: {
        labels: ['One', ['Two', 'lines'], ['Three', 'more', 'lines'], 'Four'],
        datasets: [{data: [4, 3, 2, 1], backgroundColor: ['red', 'green', 'blue', 'gray']}],
      },
      options: {plugins: unitPlugins(['legend'], {legend: {position: 'right'}})},
    },
    {steps: [['clickLegend', 1]]},
  ),
];

writeControllerReference(OUT, 'pluginLegend', cases, {title: 'legend plugin'});
