// Original code, not ported from Chart.js: decimation plugin reference generator.
//
// It writes test/port/plugins/plugin_decimation_reference.dart, the data of
// test/port/plugins/plugin.decimation_test.dart: real charts with the
// decimation plugin of a build of the pinned Chart.js (Chart.js ADR 0041,
// section 3). See the headers of tool/reference/plugin_chart_common.mjs,
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the limits.
//
// The cases are the unit cases of Chart.js ADR 0041, section 3 item 7 (row
// `decimation`), and a mixed case:
// - `lttb` with `samples`, then the step `push` (the item goes into the
//   decimated array, and the next update decimates the raw data again) and
//   an `update`;
// - `min-max` on clustered x values: many items for each pixel column, so
//   the algorithm adds the min and max items with the average x;
// - a `threshold` above the count: no decimation, the keys do not change;
// - three early returns: a category index axis (plugin.decimation.js:231),
//   `parsing: true` (:236) and a dataset `indexAxis: 'y'` (:220);
// - a user `min` and `max` of the x scale (the visible range of :176-195);
// - the step `setOption` to `enabled: false` (the clean of :156-168);
// - a write of `dataset.data` after the decimation (the setter of
//   :261-263): an inline plugin `writer` writes new data in its
//   `beforeUpdate` hook when its option `write` is true, and the step
//   `setOption plugins.writer.write true` runs it;
// - a bar dataset and a line dataset: the bar controller has no
//   `supportsDecimation` (:225), the line dataset decimates.
//
// Each case sets `parsing: false` (except the parsing case) and
// `options.plugins` with unitPlugins(['decimation'], ...): the Dart test
// file registers only the decimation plugin until wave 4 (Chart.js ADR
// 0041, sections 4 and 7). The observation has the key
// `plugins.decimation` (the observer `observeDecimation` below and in the
// Dart test file). The Dart test file runs the cases again with the light
// preset (theming.md section 8 test 3).
//
// The named function `writeData` is the `beforeUpdate` hook of the inline
// plugin `writer`. The Dart test file has a function of the same name with
// the same body.
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js
// v24.12.0:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/plugin_decimation_reference.mjs
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
  new URL('../../test/port/plugins/plugin_decimation_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerBuiltins(C);

/**
 * The observer `plugins.decimation`: for each dataset of
 * `chart.data.datasets`, its keys in order, whether `_decimated` is a key,
 * whether `_data` is an own key, whether `data` is the `_decimated` array,
 * and the plain `data` (Chart.js ADR 0041, section 3 item 4). Upstream,
 * `data` is an accessor exactly when `_data` is an own key. The Dart test
 * file has the same observer.
 */
function observeDecimation(chart) {
  return chart.data.datasets.map((ds) => ({
    keys: Object.keys(ds),
    decimated: '_decimated' in ds,
    ownData: Object.hasOwn(ds, '_data'),
    dataIsDecimated: ds.data === ds._decimated,
    data: plain(ds.data),
  }));
}

/** [n] items `{x: i, y: f(i)}`. */
const series = (n, f) => Array.from({length: n}, (_, i) => ({x: i, y: f(i)}));

/** The y values of the cases: a fixed pattern with peaks. */
const wave = (i) => (i * 37) % 23;

/**
 * 64 items in 16 clusters of 4: the x values of a cluster are 0.25 apart,
 * and the clusters are 10 apart. On a canvas of 100 pixels, each cluster
 * is in one pixel column of minMaxDecimation (:95-97).
 */
const clustered = () =>
  Array.from({length: 64}, (_, i) => ({
    x: Math.floor(i / 4) * 10 + (i % 4) * 0.25,
    y: ((i * 37) % 23) - 5,
  }));

/**
 * The `beforeUpdate` hook of the inline plugin `writer`: when its option
 * `write` is true, it writes 80 new items into `data` of the dataset 0.
 * With the decimation accessor, the write is the setter of :261-263.
 */
const writeData = named('writeData', (chart, args, options) => {
  if (options.write) {
    chart.data.datasets[0].data = series(80, (i) => (i * 11) % 19);
  }
});

/** The `options` of a unit case: the decimation plugin with [decimation]. */
const decimationOn = (decimation, options = {}, pluginOptions = {}) => ({
  parsing: false,
  scales: {x: {type: 'linear'}},
  ...options,
  plugins: unitPlugins(['decimation'], {
    decimation: {enabled: true, ...decimation},
    ...pluginOptions,
  }),
});

/** A case with the observer of the decimation plugin. */
const decimationCase = (name, config, {steps = [], options = {}} = {}) =>
  runPluginCase(name, config, {
    options,
    steps,
    observers: {decimation: observeDecimation},
  });

/** A line config with one dataset of [data] and the [options]. */
const lineConfig = (data, options) => ({
  type: 'line',
  data: {datasets: [{label: 'd0', data}]},
  options,
});

const cases = [
  decimationCase(
    'lttb: samples, then push and update',
    lineConfig(series(60, wave), decimationOn({algorithm: 'lttb', samples: 12, threshold: 20})),
    {steps: [['push', 0, {x: 60, y: 3}], ['update']]},
  ),
  decimationCase(
    'min-max: clustered x values',
    lineConfig(clustered(), decimationOn({algorithm: 'min-max', threshold: 20})),
    {options: {canvas: {width: 100, height: 100}}},
  ),
  decimationCase(
    'threshold above the count',
    lineConfig(series(24, wave), decimationOn({algorithm: 'lttb', samples: 8, threshold: 100})),
  ),
  decimationCase('category index axis', {
    type: 'line',
    data: {
      labels: Array.from({length: 24}, (_, i) => `l${i}`),
      datasets: [{label: 'd0', data: series(24, wave)}],
    },
    options: decimationOn(
      {algorithm: 'lttb', samples: 8, threshold: 10},
      {scales: {x: {type: 'category'}}},
    ),
  }),
  decimationCase(
    'parsing: true',
    lineConfig(
      series(24, wave),
      decimationOn({algorithm: 'lttb', samples: 8, threshold: 10}, {parsing: true}),
    ),
  ),
  decimationCase('dataset indexAxis: y', {
    type: 'line',
    data: {
      datasets: [
        {label: 'd0', indexAxis: 'y', data: series(24, wave).map(({x, y}) => ({x: y, y: x}))},
      ],
    },
    options: decimationOn(
      {algorithm: 'lttb', samples: 8, threshold: 10},
      {scales: {x: {type: 'linear'}, y: {type: 'linear'}}},
    ),
  }),
  decimationCase(
    'a user min and max',
    lineConfig(
      series(60, wave),
      decimationOn(
        {algorithm: 'lttb', samples: 8, threshold: 10},
        {scales: {x: {type: 'linear', min: 10, max: 40}}},
      ),
    ),
  ),
  decimationCase(
    'setOption enabled: false cleans the dataset',
    lineConfig(series(60, wave), decimationOn({algorithm: 'min-max', threshold: 20})),
    {
      options: {canvas: {width: 30, height: 100}},
      steps: [['setOption', 'plugins.decimation.enabled', false]],
    },
  ),
  decimationCase(
    'a write of dataset.data after the decimation',
    {
      type: 'line',
      data: {datasets: [{label: 'd0', data: series(60, wave)}]},
      options: decimationOn(
        {algorithm: 'lttb', samples: 10, threshold: 20},
        {},
        {writer: {write: false}},
      ),
      plugins: [{id: 'writer', beforeUpdate: writeData}],
    },
    {steps: [['setOption', 'plugins.writer.write', true]]},
  ),
  decimationCase('a bar dataset and a line dataset', {
    type: 'line',
    data: {
      datasets: [
        {type: 'bar', label: 'd0', data: series(40, wave)},
        {label: 'd1', data: series(40, (i) => (i * 13) % 17)},
      ],
    },
    options: decimationOn({algorithm: 'lttb', samples: 6, threshold: 10}),
  }),
];

writeControllerReference(OUT, 'pluginDecimation', cases, {title: 'decimation plugin'});
