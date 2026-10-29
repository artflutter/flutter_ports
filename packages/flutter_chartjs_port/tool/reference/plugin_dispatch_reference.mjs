// Original code, not ported from Chart.js: plugin dispatch reference generator.
//
// It writes test/port/plugins/plugin_dispatch_reference.dart, the data of
// test/port/plugins/index_test.dart (Chart.js ADR 0038, section 11): the
// plugin hook dispatch of real charts with the seven plugins of a build of
// the pinned Chart.js. See the header of tool/reference/scale_chart_common.mjs
// for the method, the build and the checks of loadChartJs.
//
// The generator registers the built-in components as
// test/flutter_test_config.dart does (registerBuiltins: src/index.umd.ts:28,
// then `colors.enabled = false` of test/index.js:25-28, Chart.js ADR 0041,
// section 1). Then it records, for each case:
//
// - `plugins`: for each plugin object of the namespace `plugins`
//   (src/plugins/index.js:1-7), its id and its keys in order. A key with a
//   function value is `<key>(<length>)`, with the `length` of the function
//   (its count of parameters). The class value `_element` is
//   `<key>: class`. Each other key is the key alone.
// - `registry`: the plugin ids of `Chart.registry.plugins.items`, in order.
// - `steps`: for each step, `do`, `calls` and `notifies`. `calls` are the
//   calls of the real plugin hooks, as `<plugin id>.<hook>`: the generator
//   replaces each hook of each plugin object with a recording function. The
//   functions are the same in each chart. `notifies` are the hooks that the
//   inline plugin `recorder` of the chart gets. The recorder has a function
//   for each hook name of the interfaces `Plugin` (src/types/index.d.ts:856-
//   1164) and `ExtendedPlugin` (:2764-2787), and it is the last plugin of
//   each notify (core.plugins.js:125-144). Thus `notifies` are the notifies of
//   the plugin service in order, also `install`, `start`, `stop` and
//   `uninstall` (core.plugins.js:35-54, :113-119).
//
// A hook gets a detail after a colon (see detail()): the dataset index of
// the dataset hooks, the scale id of the scale hooks, the event type of the
// event hooks and the update mode of the update hooks.
//
// The steps:
// - `['construct']`: `new Chart(ctx, config)` through makeChart (the
//   `_acquireChart` of chartjs-test-utils).
// - `['draw']`, `['render']`, `['reset']`, `['update']` and
//   `['update', mode]`: the call of the method.
// - `['hover', x, y]` and `['mouseout', x, y]`: `chart._eventHandler` with
//   the chart event `{type, chart, native: {type}, x, y}`, as the step
//   `hover` of tool/reference/controller_chart_common.mjs. The point is the
//   rounded position of the data element 2 of the dataset 0, because the
//   harness rounds the offsets of an event (triggerMouseEvent).
// - `['destroy']`: `chart.destroy()`.
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045):
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/plugin_dispatch_reference.mjs
//
// The path can also be the first argument.

import {fileURLToPath} from 'node:url';

import {
  loadChartJs,
  makeChart,
  registerBuiltins,
  writeReference,
} from './scale_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/plugins/plugin_dispatch_reference.dart', import.meta.url),
);

const C = await loadChartJs();
registerBuiltins(C);

/**
 * The hook names of the interface `Plugin` (src/types/index.d.ts:856-1164)
 * in source order, then the two hooks of `ExtendedPlugin`
 * (src/types/index.d.ts:2764-2787). The Dart test has the same list.
 */
const HOOKS = [
  'install',
  'start',
  'stop',
  'beforeInit',
  'afterInit',
  'beforeUpdate',
  'afterUpdate',
  'beforeElementsUpdate',
  'reset',
  'beforeDatasetsUpdate',
  'afterDatasetsUpdate',
  'beforeDatasetUpdate',
  'afterDatasetUpdate',
  'beforeLayout',
  'beforeDataLimits',
  'afterDataLimits',
  'beforeBuildTicks',
  'afterBuildTicks',
  'afterLayout',
  'beforeRender',
  'afterRender',
  'beforeDraw',
  'afterDraw',
  'beforeDatasetsDraw',
  'afterDatasetsDraw',
  'beforeDatasetDraw',
  'afterDatasetDraw',
  'beforeEvent',
  'afterEvent',
  'resize',
  'beforeDestroy',
  'afterDestroy',
  'uninstall',
  'beforeTooltipDraw',
  'afterTooltipDraw',
];

/** The hooks whose args have the dataset `index`. */
const INDEX_HOOKS = new Set([
  'beforeDatasetUpdate',
  'afterDatasetUpdate',
  'beforeDatasetDraw',
  'afterDatasetDraw',
]);

/** The hooks whose args are the context of a scale (core.scale.js:534-537). */
const SCALE_HOOKS = new Set([
  'beforeDataLimits',
  'afterDataLimits',
  'beforeBuildTicks',
  'afterBuildTicks',
]);

/** The hooks whose args have the `event`. */
const EVENT_HOOKS = new Set(['beforeEvent', 'afterEvent']);

/** The hooks whose args have the update `mode`. */
const MODE_HOOKS = new Set([
  'beforeUpdate',
  'afterUpdate',
  'beforeDatasetsUpdate',
  'afterDatasetsUpdate',
  'beforeDatasetUpdate',
  'afterDatasetUpdate',
]);

/**
 * The text of a hook call: [hook], then `:<detail>` for each detail of the
 * args. The details are the `index` of a dataset hook, the `id` of the
 * `scale` of a scale hook, the `type` of the `event` of an event hook and
 * the `String` of the `mode` of an update hook (`undefined` for no mode).
 */
function detail(hook, args) {
  let text = hook;
  if (INDEX_HOOKS.has(hook)) text += `:${args.index}`;
  if (SCALE_HOOKS.has(hook)) text += `:${args.scale.id}`;
  if (EVENT_HOOKS.has(hook)) text += `:${args.event.type}`;
  if (MODE_HOOKS.has(hook)) text += `:${String(args.mode)}`;
  return text;
}

/** Whether [v] is a class: `typeof` gives 'function' for a class too. */
const isClass = (v) => /^class[\s{]/.test(Function.prototype.toString.call(v));

/** The text of the key [key] of the plugin object [plugin]. */
function keyText(plugin, key) {
  const v = plugin[key];
  if (typeof v !== 'function') return key;
  return isClass(v) ? `${key}: class` : `${key}(${v.length})`;
}

// The keys of each plugin object, before the recording functions replace
// the hooks.
const plugins = Object.keys(C.plugins).map((name) => {
  const plugin = C.plugins[name];
  if (C.Chart.registry.getPlugin(plugin.id) !== plugin) {
    throw new Error(`The registry has another object for ${plugin.id}.`);
  }
  return {id: plugin.id, keys: Object.keys(plugin).map((k) => keyText(plugin, k))};
});
const registryIds = Object.keys(C.Chart.registry.plugins.items);

/** The calls of the real plugin hooks of the current step. */
const calls = [];

/** The notifies of the current step. */
const notifies = [];

// Replace each hook of each plugin object with a recording function. The
// call keeps `this` and all the arguments (core.plugins.js:62-65). The
// detail reads the args only for a hook with the parameter `args`: the
// Dart recording closure has the parameters of the hook, so a hook with
// one parameter does not get the args. It then gives the detail of `{}`.
for (const name of Object.keys(C.plugins)) {
  const plugin = C.plugins[name];
  for (const key of Object.keys(plugin)) {
    const f = plugin[key];
    if (typeof f !== 'function' || isClass(f)) continue;
    plugin[key] = function (...args) {
      calls.push(`${plugin.id}.${detail(key, f.length >= 2 ? args[1] : {})}`);
      return f.apply(this, args);
    };
  }
}

/** The inline plugin `recorder`: a recording function for each of HOOKS. */
function recorder() {
  const plugin = {id: 'recorder'};
  for (const hook of HOOKS) {
    plugin[hook] = (_chart, args) => {
      notifies.push(detail(hook, args));
    };
  }
  return plugin;
}

/** The config of the chart of the case `three datasets`. */
function lineConfig() {
  const datasets = [];
  for (let i = 0; i < 3; i++) {
    datasets.push({label: `d${i}`, data: [1 + i, 3, 2, 5, 4], fill: i === 0 ? 'origin' : false});
  }
  return {
    type: 'line',
    data: {labels: ['a', 'b', 'c', 'd', 'e'], datasets},
    options: {plugins: {title: {display: true, text: 'T'}, colors: {enabled: false}}},
  };
}

/** A deep copy of a JSON value. */
const copy = (v) => JSON.parse(JSON.stringify(v));

/**
 * Runs the case [name]: the chart of [config] with the recorder, then each
 * of [steps]. A step `['hover']` gets the point of the data element 2 of
 * the dataset 0, and `['mouseout']` the point of the last hover. The chart
 * is destroyed at the end unless a step destroys it.
 */
function runCase(name, config, steps) {
  const literal = copy(config);
  let chart = null;
  let point = null;
  let destroyed = false;
  const recorded = [];
  for (const step of steps) {
    calls.length = 0;
    notifies.length = 0;
    let done = step;
    const event = (type) => {
      const [x, y] = point;
      chart._eventHandler({type, chart, native: {type}, x, y});
    };
    switch (step[0]) {
      case 'construct':
        chart = makeChart({...copy(config), plugins: [recorder()]});
        break;
      case 'draw':
        chart.draw();
        break;
      case 'render':
        chart.render();
        break;
      case 'reset':
        chart.reset();
        break;
      case 'update':
        chart.update(...step.slice(1));
        break;
      case 'hover': {
        const element = chart.getDatasetMeta(0).data[2];
        point = [Math.round(element.x), Math.round(element.y)];
        done = ['hover', ...point];
        event('mousemove');
        break;
      }
      case 'mouseout':
        done = ['mouseout', ...point];
        event('mouseout');
        break;
      case 'destroy':
        chart.destroy();
        destroyed = true;
        break;
      default:
        throw new Error(`No step ${step[0]}`);
    }
    recorded.push({do: done, calls: [...calls], notifies: [...notifies]});
  }
  if (!destroyed) chart.destroy();
  return {
    name,
    config: literal,
    options: {},
    expected: {plugins, registry: registryIds, steps: recorded},
  };
}

const cases = [
  runCase('three datasets, a title and a fill', lineConfig(), [
    ['construct'],
    ['draw'],
    ['render'],
    ['update', 'none'],
    ['update'],
    ['hover'],
    ['hover'],
    ['draw'],
    ['mouseout'],
    ['reset'],
    ['destroy'],
  ]),
  runCase(
    'plugins false',
    {...lineConfig(), options: {plugins: false}},
    [['construct'], ['draw'], ['update'], ['hover'], ['mouseout'], ['destroy']],
  ),
];

// The keys of `expected` are not the keys of runCase of
// scale_chart_common.mjs. A note in the data file gives them.
const notes = [
  'The `expected` of a case has the keys `plugins` (the id and the keys of',
  'each plugin object of the namespace `plugins`), `registry` (the plugin',
  'ids of the registry) and `steps` (`do`, `calls` and `notifies` of each',
  'step). See the header of tool/reference/plugin_dispatch_reference.mjs.',
];

writeReference(OUT, 'pluginDispatch', cases, {title: 'plugin dispatch', notes});
