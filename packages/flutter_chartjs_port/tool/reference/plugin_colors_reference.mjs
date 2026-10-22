// Original code, not ported from Chart.js: colors plugin reference generator.
//
// It writes test/port/plugins/plugin_colors_reference.dart, the data of
// test/port/plugins/plugin.colors_test.dart: real charts of a build of the
// pinned Chart.js with the colors plugin of src/plugins/plugin.colors.ts
// (Chart.js ADR 0041, section 3). See the headers of
// tool/reference/plugin_chart_common.mjs,
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The generator registers the built-in components and the seven plugins
// (registerBuiltins: src/index.umd.ts:28, then
// `defaults.plugins.colors.enabled = false`, test/index.js:25-28). Each case
// is a unit case (Chart.js ADR 0041, section 4): `options.plugins` is
// unitPlugins(['colors'], ...), so each other plugin is `false`, and the
// case sets `colors.enabled: true`. The Dart test file registers only the
// colors plugin in wave 1.
//
// The observation of a case is the controller observation without the hit
// matrix, `boxes`, and `plugins.colors`: for each dataset of
// `chart.config.data.datasets`, its `backgroundColor` and `borderColor`
// after the hook `beforeLayout` (Chart.js ADR 0041, section 3 item 4).
//
// The cases (Chart.js ADR 0041, section 3 item 7, and a mixed-types case):
// - `enabled: true` on each chart type with its own colorizer path: bar
//   with 8 datasets (the wrap after the 7 colors), line, doughnut and pie
//   (the doughnut colorizer, one color for each data item; the pie wraps in
//   its data), polar area (the background palette), radar and bubble.
// - `dataset colors given`: one dataset has a `borderColor`, so the plugin
//   returns (plugin.colors.ts:119). The step `setOption
//   plugins.colors.forceOverride true` then colorizes over the dataset
//   colors.
// - `chart colors given`: a root `backgroundColor` option. No change.
// - `elements colors given`: an `elements.line.borderColor` option. No
//   change.
// - `string data`: a doughnut with a string `data` throws the TypeError of
//   `dataset.data.map` (plugin.colors.ts:43), and a bar with a string
//   `data` colorizes, because the default colorizer does not read `data`.
// - `mixed types`: the datasets of the upstream fixture
//   test/fixtures/plugin.colors/mixed.js (line, bar and pie, no chart
//   type) and a polar area dataset. The three colorizers share the one
//   counter `i` of getColorizer (plugin.colors.ts:55-66): the pie starts at
//   color 2, and the polar area starts at color 6 and wraps.
//
// The Dart test file runs the cases two times: unthemed, and with the
// light preset (theming.md section 8 test 3, Chart.js ADR 0042).
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/plugin_colors_reference.mjs
//
// The path can also be the first argument.

import {fileURLToPath} from 'node:url';

import {
  loadChartJs,
  registerBuiltins,
  runPluginCase,
  unitPlugins,
  writeControllerReference,
} from './plugin_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/plugins/plugin_colors_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerBuiltins(C);

/**
 * The observer `plugins.colors`: the colors of each dataset of
 * `chart.config.data.datasets` (Chart.js ADR 0041, section 3 item 4). The
 * Dart test file has the same observer.
 */
const observeColors = (chart) =>
  chart.config.data.datasets.map((ds) => ({
    backgroundColor: ds.backgroundColor,
    borderColor: ds.borderColor,
  }));

/** `options` of a unit case: the colors plugin on, with [colors]. */
const colorsOn = (colors = {}, options = {}) => ({
  ...options,
  plugins: unitPlugins(['colors'], {colors: {enabled: true, ...colors}}),
});

/** [n] datasets of [items] numbers each, without colors. */
function datasets(n, items, extra = () => ({})) {
  return Array.from({length: n}, (_, d) => ({
    label: `d${d}`,
    data: Array.from({length: items}, (_, i) => ((d * 7 + i * 3) % 11) + 1),
    ...extra(d),
  }));
}

/** [n] labels. */
const labels = (n) => Array.from({length: n}, (_, i) => `l${i}`);

/** A case with the observer of the colors plugin. */
const colorsCase = (name, config, {steps = []} = {}) =>
  runPluginCase(name, config, {steps, observers: {colors: observeColors}});

const cases = [
  colorsCase('bar: 8 datasets wrap the 7 colors', {
    type: 'bar',
    data: {labels: labels(3), datasets: datasets(8, 3)},
    options: colorsOn(),
  }),
  colorsCase('line', {
    type: 'line',
    data: {labels: labels(4), datasets: datasets(2, 4)},
    options: colorsOn(),
  }),
  colorsCase('doughnut: one color for each item', {
    type: 'doughnut',
    data: {labels: labels(3), datasets: datasets(2, 3)},
    options: colorsOn(),
  }),
  colorsCase('pie: 9 items wrap the 7 colors', {
    type: 'pie',
    data: {labels: labels(9), datasets: datasets(1, 9)},
    options: colorsOn(),
  }),
  colorsCase('polarArea: the background palette', {
    type: 'polarArea',
    data: {labels: labels(4), datasets: datasets(2, 4)},
    options: colorsOn(),
  }),
  colorsCase('radar', {
    type: 'radar',
    data: {labels: labels(5), datasets: datasets(2, 5)},
    options: colorsOn(),
  }),
  colorsCase('bubble', {
    type: 'bubble',
    data: {
      datasets: [
        {label: 'd0', data: [{x: 1, y: 2, r: 3}, {x: 2, y: 4, r: 5}]},
        {label: 'd1', data: [{x: 3, y: 1, r: 4}]},
      ],
    },
    options: colorsOn(),
  }),
  colorsCase(
    'dataset colors given, then forceOverride',
    {
      type: 'bar',
      data: {
        labels: labels(3),
        datasets: datasets(2, 3, (d) => (d === 0 ? {borderColor: 'rgb(1, 2, 3)'} : {})),
      },
      options: colorsOn(),
    },
    {steps: [['setOption', 'plugins.colors.forceOverride', true]]},
  ),
  colorsCase('chart colors given', {
    type: 'line',
    data: {labels: labels(3), datasets: datasets(2, 3)},
    options: colorsOn({}, {backgroundColor: 'rgb(9, 8, 7)'}),
  }),
  colorsCase('elements colors given', {
    type: 'line',
    data: {labels: labels(3), datasets: datasets(2, 3)},
    options: colorsOn({}, {elements: {line: {borderColor: 'rgb(9, 8, 7)'}}}),
  }),
  colorsCase('string data: doughnut throws', {
    type: 'doughnut',
    data: {labels: labels(3), datasets: [{label: 'd0', data: 'abc'}]},
    options: colorsOn(),
  }),
  colorsCase('string data: bar colorizes', {
    type: 'bar',
    data: {labels: labels(3), datasets: [{label: 'd0', data: '123'}]},
    options: colorsOn(),
  }),
  colorsCase('mixed types: one counter over the three colorizers', {
    data: {
      labels: [0, 1, 2, 3],
      datasets: [
        {type: 'line', data: [5, 20, 1, 10]},
        {type: 'bar', data: [6, 16, 3, 19]},
        {type: 'pie', data: [5, 20, 1, 10]},
        {type: 'polarArea', data: [3, 7, 2]},
      ],
    },
    options: colorsOn(),
  }),
];

writeControllerReference(OUT, 'pluginColors', cases, {title: 'colors plugin'});
