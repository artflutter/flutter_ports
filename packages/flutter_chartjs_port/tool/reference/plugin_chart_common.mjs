// Original code, not ported from Chart.js: shared code of the plugin reference generators.
//
// The shared code of the generators of the phase 8 plugin reference tests
// (tool/reference/plugin_<name>_reference.mjs, Chart.js ADR 0041, section
// 3). A plugin generator builds real charts with a build of the pinned
// Chart.js in Node.js, as the controller generators do, and records the
// controller observation without the hit matrix, the layout boxes
// (`boxes`) and the observation of its own plugin (`plugins.<id>`). The
// Dart side of this file is test/port/plugins/plugin_chart_harness.dart.
// Nothing in lib/ or test/ runs this code (porting-flow.md section 4).
//
// This file imports tool/reference/controller_chart_common.mjs. See its
// header and the header of scale_chart_common.mjs for the method, the
// build and the checks of loadChartJs.
//
// How to write a plugin generator: import this file, then call
// loadChartJs(), registerBuiltins(C) (the plugins of src/index.umd.ts:28,
// then `colors.enabled = false`, test/index.js:25-28), runPluginCase() for
// each case with the observer of the plugin, and
// writeControllerReference(). The config of a unit case sets
// `options.plugins` to unitPlugins(<the plugin set of the case>,
// <the plugin options of the case>) (Chart.js ADR 0041, section 4). A full
// case (wave 4) has the default plugin options.
//
// The observer of a plugin (`plugins.title`, `plugins.legend` and so on)
// lives in its generator and in its Dart test file, not here: the shared
// code needs no plugin class (Chart.js ADR 0041, section 3 item 2).

import {
  loadChartJs,
  plain,
  registerBuiltins,
  runControllerCase,
  writeControllerReference,
} from './controller_chart_common.mjs';

export {loadChartJs, plain, registerBuiltins, runControllerCase, writeControllerReference};

/** The plugin ids of src/plugins/index.js:1-7, in that order. */
export const PLUGIN_IDS = [
  'colors',
  'decimation',
  'filler',
  'legend',
  'subtitle',
  'title',
  'tooltip',
];

/**
 * The `options.plugins` part of a unit case: `false` for each plugin id
 * that is not in [registered], and the options of [pluginOptions] for the
 * others (Chart.js ADR 0041, section 4). [registered] is the registration
 * set of the Dart test file in its wave (Chart.js ADR 0041, section 7).
 *
 * `getOpts` gives `null` for the option `false`, and `createDescriptors`
 * then leaves the plugin out (core.plugins.js:146-163). Thus the chart of a
 * unit case is the chart with only the plugins of [registered] (Chart.js ADR
 * 0041, section 4 item 1). In waves 1-3 this was the registration set of the
 * Dart test file. From wave 4 the Dart test file registers all seven
 * plugins, and the `false` options keep the same chart.
 *
 * The keys come in the order of PLUGIN_IDS, then the keys of
 * [pluginOptions] that are not plugin ids (the options of an inline
 * plugin). An unknown id in [registered], or options other than `false`
 * for a plugin that is not in [registered], stop the generator.
 */
export function unitPlugins(registered, pluginOptions = {}) {
  for (const id of registered) {
    if (!PLUGIN_IDS.includes(id)) throw new Error(`Not a plugin id: ${id}`);
  }
  const out = {};
  for (const id of PLUGIN_IDS) {
    if (!registered.includes(id)) {
      if (id in pluginOptions && pluginOptions[id] !== false) {
        throw new Error(
          `The case sets options of the plugin ${id}, but the Dart test file ` +
            'does not register it.',
        );
      }
      out[id] = false;
    } else if (id in pluginOptions) {
      out[id] = pluginOptions[id];
    }
  }
  for (const [key, value] of Object.entries(pluginOptions)) {
    if (!PLUGIN_IDS.includes(key)) out[key] = value;
  }
  return out;
}

/**
 * The kind of the layout box [box] of [chart]: `legend` for
 * `chart.legend`, `title` for `chart.titleBlock`, the scale id for a scale
 * of `chart.scales`, and `subtitle` for each other box. No plugin case adds
 * a user box. The subtitle map is private on both sides
 * (plugin.subtitle.js:4), so each other box is the subtitle.
 */
function boxKind(chart, box) {
  if (box === chart.legend) return 'legend';
  if (box === chart.titleBlock) return 'title';
  for (const scale of Object.values(chart.scales)) {
    if (box === scale) return scale.id;
  }
  return 'subtitle';
}

/**
 * The `boxes` observation of Chart.js ADR 0041 section 3 item 4: each box
 * of `chart.boxes` in order, as `[kind, position, weight, fullSize, left,
 * top, right, bottom, width, height]`. The order is protected.
 */
export function observeBoxes(chart) {
  return chart.boxes.map((b) => [
    boxKind(chart, b),
    b.position,
    b.weight,
    b.fullSize,
    b.left,
    b.top,
    b.right,
    b.bottom,
    b.width,
    b.height,
  ]);
}

/**
 * The observation keys of a plugin case after `datasets`: `boxes`, and for
 * each entry `[id, observer]` of [observers] the key `plugins.<id>` with
 * the plain copy of `observer(chart)`.
 */
function pluginObservation(observers) {
  return (chart) => ({
    boxes: observeBoxes(chart),
    ...Object.fromEntries(
      Object.entries(observers).map(([id, observer]) => [`plugins.${id}`, plain(observer(chart))]),
    ),
  });
}

/**
 * runControllerCase with `hits: false`. The observation is the controller
 * observation without `hits`, with `boxes` and, for each entry of
 * [observers], the key `plugins.<id>` with its result. Each plugin
 * generator gives its own observer.
 */
export function runPluginCase(
  name,
  config,
  {options = {}, steps = [], extras = {}, observers = {}} = {},
) {
  return runControllerCase(name, config, {
    options,
    steps,
    extras,
    hits: false,
    observeExtra: pluginObservation(observers),
  });
}
