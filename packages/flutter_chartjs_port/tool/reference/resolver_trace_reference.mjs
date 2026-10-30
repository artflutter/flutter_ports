// Original code, not ported from Chart.js: resolver trace reference generator.
//
// It writes test/port/core/resolver_trace_reference.dart, the data of
// test/port/core/resolver_trace_test.dart: the D2 reference trace of
// Chart.js ADR 0053 (judge-r.md section 4.0 of phase 10). Real charts of a
// build of the pinned Chart.js record, after each step, the resolved options
// of each element with their key order, the ordered calls of the user
// functions of the config, and for the animation cases the `$animations` of
// each element and of its options. See the headers of
// tool/reference/controller_chart_common.mjs and
// tool/reference/scale_chart_common.mjs for the method and the build.
//
// The cases cover the paths of the option resolver that a fast path of
// Chart.js ADR 0053 can change: a scriptable option on each scope level,
// indexable arrays, the hover prefixes, object options and arrays of
// objects, `_fallback` as a string, as `true` and as a function, user
// `_scriptable` and `_indexable` functions, the recursion throw, writes of
// `ctx.parsed` and through the sub-resolver, a new key of
// `defaults.elements.point` during an update, duplicate names and a slot
// name in a direct `resolveNamedOptions` call, and the animation options of
// an update in the default mode, of `hide` and of `show`.
//
// The cases after them come from B0 of the typed core (Chart.js ADR 0054):
// a plugin that writes the dataset colors in `beforeLayout`, a scriptable
// option that writes the Map of another dataset, a write of
// `chart.options.plugins.legend.position` before an update, a change of
// `Chart.defaults.borderColor` between two updates (element, scale and
// legend items), a scriptable grid `lineWidth` with a context for each tick,
// a scriptable legend label color, a string `pointRadius` with a hit test,
// the write through the sub-resolver in the active mode, a user scale class,
// a user element class as the data element of the bar controller, and a
// delete of `defaults.elements.point.rotation`. The cases that change the
// global scopes for the cases after them come last, and each step that
// writes `Chart.defaults` puts the old value back after its case.
//
// The user functions. Each function of a config is a named function (the
// string 'fn:<name>' in the data). The Dart test has a function of the same
// name with the same body. Each call records one trace entry: `fn` (the
// name); `ctx` (the keys `type`, `index`, `dataIndex`, `datasetIndex`,
// `mode` and `active` of the first argument, when it is an object) or `arg0`
// (the first argument); and `arg1`, the kind of the second argument:
// 'absent' (undefined), 'resolver' (a resolver proxy) or 'value'.
//
// The observations of a step (optionsOf, valueOf, nestedOf):
// - `datasets`: for each dataset, `dataset` (the options of the dataset
//   element, or null) and `data` (the options of each data element). An
//   options object is a plain copy with the keys of `Object.keys` in their
//   order. `$animations` stands as '<animations>'. A function is '<fn>'. An
//   object option (depth 1) has its keys in order, with the values of the
//   keys of NESTED_KEYS and '<skipped>' for the other keys: the test reads
//   no other key, so the reads stay the same on both sides. An object at
//   depth 2 is '<object>'.
// - `animations` (the animation cases): for each element, `element` and
//   `options`, the `$animations` of the element and of its options: 'none'
//   when absent, else each animation with `from`, `to`, `duration`,
//   `start`, `loop` and `easing` (the key of `effects` of helpers.easing).
// - `trace`: the calls of the step. `observeTrace`: the calls of the
//   observation (the reads of object options can run scriptable options).
//
// Date.now() is NOW for each case. The animator gets a requestAnimationFrame
// that keeps its callbacks and never calls them: no frame ticks, as in the
// Dart test, which pumps no frame.
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045):
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/resolver_trace_reference.mjs
//
// The path can also be the first argument.

import {writeFileSync} from 'node:fs';
import {relative} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {execFileSync} from 'node:child_process';
import {types} from 'node:util';

import {loadChartJs, makeChart, named, registerBuiltins} from './controller_chart_common.mjs';
import {dartLiteral, referenceBuild} from './scale_chart_common.mjs';

const OUT = fileURLToPath(
  new URL('../../test/port/core/resolver_trace_reference.dart', import.meta.url),
);
const PACKAGE_ROOT = fileURLToPath(new URL('../../', import.meta.url));

/** The fixed Date.now() of each case: 2026-01-01T00:00:00Z. */
const NOW = 1767225600000;
Date.now = () => NOW;

// The frames of the animator: kept, never called. requestAnimFrame of
// helpers.extras.ts:14-20 reads window.requestAnimationFrame when the dist
// loads, and core.animator.js:44 calls it with `window` as `this`.
const frames = [];
globalThis.window = globalThis;
globalThis.requestAnimationFrame = (callback) => frames.push(callback);

const C = await loadChartJs();
registerBuiltins(C);
const {effects} = await import(new URL('helpers.js', pathToFileURL(
  process.argv[2] ?? process.env.CHARTJS_DIST,
)).href).then((helpers) => ({effects: helpers.easingEffects}));
if (!effects || typeof effects.linear !== 'function') {
  throw new Error('dist/helpers.js gives no easingEffects.');
}

// The platform of the charts: the no-op updateConfig of platform.base.js:80
// on BasicPlatform, as in controller_doughnut_reference.mjs. A case with an
// animation object keeps it, as a chart of the Dart harness does. Each
// other case gets `animation: false` from makeChart.
C.BasicPlatform.prototype.updateConfig = C.BasePlatform.prototype.updateConfig;

const {defaults} = C;

// ---------------------------------------------------------------------------
// The trace.

/** The calls of the user functions of the current case. */
let trace = [];

/** The kind of the second argument of a user function. */
function kindOf(b) {
  if (b === undefined) return 'absent';
  return types.isProxy(b) ? 'resolver' : 'value';
}

/** Records the call of the user function [name] with [a] and [b]. */
function record(name, a, b) {
  const entry = {fn: name};
  if (a !== null && typeof a === 'object' && !Array.isArray(a)) {
    entry.ctx = {
      type: a.type,
      index: a.index,
      dataIndex: a.dataIndex,
      datasetIndex: a.datasetIndex,
      mode: a.mode,
      active: a.active,
    };
  } else {
    entry.arg0 = a;
  }
  entry.arg1 = kindOf(b);
  trace.push(entry);
}

/**
 * A named user function: it records each call, then returns [body](a, b).
 * The Dart test has a function of the same name.
 */
function fn(name, body) {
  return named(name, (a, b) => {
    record(name, a, b);
    return body(a, b);
  });
}

// The user functions of the cases. resolver_trace_test.dart has the same
// bodies in `_functions`.
const F = {
  dsColor: fn('dsColor', (ctx) => (ctx.dataIndex % 2 === 0 ? 'red' : 'blue')),
  lineBorderColor: fn('lineBorderColor', () => 'green'),
  elementHitRadius: fn('elementHitRadius', (ctx) => ctx.dataIndex + 1),
  optionRotation: fn('optionRotation', () => 15),
  defBorderWidth: fn('defBorderWidth', () => 2),
  hoverColor: fn('hoverColor', (ctx, options) => (options.radius > 5 ? 'black' : 'white')),
  barRadius: fn('barRadius', (ctx) => ctx.dataIndex),
  arcRadius: fn('arcRadius', (ctx) => ctx.dataIndex + 1),
  listItem: fn('listItem', () => 3),
  fallbackFn: fn('fallbackFn', () => 'radiusFallback'),
  userScriptable: fn('userScriptable', (name) => name !== 'radius'),
  userIndexable: fn('userIndexable', (name) => name !== 'hitRadius'),
  radiusFn: fn('radiusFn', () => 5),
  selfRadius: fn('selfRadius', (ctx, options) => options.radius),
  writeParsed: fn('writeParsed', (ctx) => {
    ctx.parsed = {x: ctx.parsed.x, y: 99};
    return 1;
  }),
  readParsed: fn('readParsed', (ctx) => (ctx.parsed.y === 99 ? 7 : 3)),
  writeRadius: fn('writeRadius', (ctx, options) => {
    if (ctx.dataIndex === 2) options.radius = 9;
    return 1;
  }),
  addDefaultKey: fn('addDefaultKey', (ctx) => {
    if (ctx.dataIndex === 1) defaults.elements.point.extraKey = 5;
    return 'red';
  }),
  namedRadius: fn('namedRadius', () => 4),
  animDelay: fn('animDelay', (ctx) => (ctx.type === 'data' ? ctx.dataIndex * 10 : 0)),
  animDuration: fn('animDuration', (ctx) =>
    ctx.type === 'data' ? 500 + 100 * ctx.dataIndex : 700,
  ),
  numbersDuration: fn('numbersDuration', () => 400),
  animationFallback: fn('animationFallback', () => false),
  deleteEasing: fn('deleteEasing', (ctx) => {
    if (ctx.dataIndex === 1) delete defaults.animation.easing;
    return 'red';
  }),
  writeOtherDataset: fn('writeOtherDataset', (ctx) => {
    if (ctx.dataIndex === 0) ctx.chart.data.datasets[1].pointRadius = 8;
    return 'red';
  }),
  gridWidth: fn('gridWidth', (ctx) => (ctx.index % 2 === 0 ? 2 : 1)),
  legendColor: fn('legendColor', () => '#00ff00'),
  writeRadiusActive: fn('writeRadiusActive', (ctx, options) => {
    if (ctx.active && ctx.dataIndex === 2) options.radius = 9;
    return 2;
  }),
  // A plugin hook: it records no call. The Dart test has the same body.
  writeColors: named('writeColors', (chart) => {
    chart.data.datasets[0].backgroundColor = 'green';
    chart.data.datasets[0].borderColor = 'blue';
  }),
};

// ---------------------------------------------------------------------------
// The setups. Each setup returns its cleanup. resolver_trace_test.dart has
// the same setups in `_setups`; the defaults restore of the harness cleans
// up after each Dart test.

/**
 * `Chart.defaults.describe(scope, values)` of a scope under `elements`, and
 * its cleanup: the keys of [values] leave the scope, and a scope that the
 * setup made leaves `elements`.
 */
function describeElement(element, values) {
  const elements = defaults.describe('elements', {});
  const had = Object.hasOwn(elements, element);
  const scope = defaults.describe(`elements.${element}`, values);
  return () => {
    for (const key of Object.keys(values)) delete scope[key];
    if (!had) delete elements[element];
  };
}

const SETUPS = {
  defBorderWidth() {
    const point = defaults.elements.point;
    const old = point.borderWidth;
    point.borderWidth = F.defBorderWidth;
    return () => {
      point.borderWidth = old;
    };
  },
  fallbackString: () => describeElement('bar', {_fallback: 'radiusFallback'}),
  fallbackTrue: () => describeElement('bar', {_fallback: true}),
  fallbackFunction: () => describeElement('bar', {_fallback: F.fallbackFn}),
  userDescriptors: () =>
    describeElement('point', {_scriptable: F.userScriptable, _indexable: F.userIndexable}),
  extraKey() {
    return () => {
      delete defaults.elements.point.extraKey;
    };
  },
  animationFallback() {
    const scope = defaults.describe('animation', {});
    const old = scope._fallback;
    scope._fallback = F.animationFallback;
    return () => {
      scope._fallback = old;
    };
  },
  userScale() {
    // A user scale class (Chart.js ADR 0054, B0): a subclass of LinearScale
    // with its own id and one more default key.
    class MyScale extends C.LinearScale {
      static id = 'myScale';
      static defaults = {myScaleOption: 3};
    }
    C.Chart.register(MyScale);
    return () => C.Chart.unregister(MyScale);
  },
  userBar() {
    // A user element class (Chart.js ADR 0054, B0): a subclass of BarElement
    // with its own id, as the data element of the bar controller. Its
    // defaults merge over the defaults of elements.bar (registerDefaults).
    class MyBar extends C.BarElement {
      static id = 'myBar';
      static defaults = {borderWidth: 2, myOption: 7};
    }
    C.Chart.register(MyBar);
    const bar = defaults.datasets.bar;
    const old = bar.dataElementType;
    bar.dataElementType = 'myBar';
    return () => {
      bar.dataElementType = old;
      C.Chart.unregister(MyBar);
    };
  },
  deleteEasing() {
    // The cleanup puts back each key of defaults.animation in its order.
    const entries = Object.entries(defaults.animation);
    return () => {
      for (const key of Object.keys(defaults.animation)) delete defaults.animation[key];
      for (const [key, value] of entries) defaults.animation[key] = value;
    };
  },
};

// ---------------------------------------------------------------------------
// The observations.

/** The keys of an object option whose values the observation reads. */
const NESTED_KEYS = new Set([
  'topLeft',
  'topRight',
  'bottomLeft',
  'bottomRight',
  'outerStart',
  'outerEnd',
  'innerStart',
  'innerEnd',
  'a',
]);

/** The observation of the option value [v] at the depth [depth]. */
function valueOf(v, depth) {
  if (typeof v === 'function') return '<fn>';
  if (Array.isArray(v)) return v.map((x) => valueOf(x, depth + 1));
  if (v !== null && typeof v === 'object') {
    return depth >= 2 ? '<object>' : nestedOf(v, depth);
  }
  return v;
}

/** The observation of the object option [v]: its keys, NESTED_KEYS read. */
function nestedOf(v, depth) {
  const out = {};
  for (const key of Object.keys(v)) {
    out[key] = NESTED_KEYS.has(key) ? valueOf(v[key], depth + 1) : '<skipped>';
  }
  return out;
}

/** The observation of the options object [o], or null. */
function optionsOf(o) {
  if (o === undefined || o === null) return null;
  const out = {};
  for (const key of Object.keys(o)) {
    out[key] = key === '$animations' ? '<animations>' : valueOf(o[key], 1);
  }
  return out;
}

/** The name of [easing] in `effects`. */
function easingName(easing) {
  const name = Object.keys(effects).find((key) => effects[key] === easing);
  if (name === undefined) throw new Error('An easing function that is not an effect.');
  return name;
}

/** The observation of the `$animations` object [anims]. */
function animationsOf(anims) {
  if (anims === undefined) return 'none';
  const out = {};
  for (const key of Object.keys(anims)) {
    const a = anims[key];
    out[key] = {
      from: a._from,
      to: a._to,
      duration: a._duration,
      start: a._start,
      loop: a._loop,
      easing: easingName(a._easing),
    };
  }
  return out;
}

/** The elements of the dataset [i]: the dataset element, then the data. */
function elementsOf(chart, i) {
  const meta = chart.getDatasetMeta(i);
  return meta.dataset ? [meta.dataset, ...meta.data] : [...meta.data];
}

/** The `datasets` observation of [chart]. */
function datasetsOf(chart) {
  return chart.data.datasets.map((_, i) => {
    const meta = chart.getDatasetMeta(i);
    return {
      dataset: meta.dataset ? optionsOf(meta.dataset.options) : null,
      data: meta.data.map((el) => optionsOf(el.options)),
    };
  });
}

/** The `animations` observation of [chart]. */
function animationsOfChart(chart) {
  return chart.data.datasets.map((_, i) =>
    elementsOf(chart, i).map((el) => ({
      element: animationsOf(el.$animations),
      options: animationsOf(el.options ? el.options.$animations : undefined),
    })),
  );
}

// ---------------------------------------------------------------------------
// The steps.

/**
 * Applies [step] to [chart]. Returns the result of a step that gives one
 * (`resolveNamed`, `readOption`), else undefined.
 */
function applyStep(chart, step) {
  const [action, ...args] = step;
  switch (action) {
    case 'update':
      chart.update(...args);
      return undefined;
    case 'setActive':
      chart.setActiveElements(args[0].map(([datasetIndex, index]) => ({datasetIndex, index})));
      chart.update();
      return undefined;
    case 'hide':
      chart.hide(args[0]);
      return undefined;
    case 'show':
      chart.show(args[0]);
      return undefined;
    case 'resolveNamed': {
      // config.resolveNamedOptions with the scopes and the context of the
      // data element 0 of dataset 0 (core.datasetController.js:802-834).
      const [names] = args;
      const controller = chart.getDatasetMeta(0).controller;
      const config = chart.config;
      const scopeKeys = config.datasetElementScopeKeys(controller._type, 'point');
      const scopes = config.getOptionScopes(controller.getDataset(), scopeKeys);
      const result = config.resolveNamedOptions(
        scopes,
        names,
        () => controller.getContext(0, false, 'default'),
        ['point', ''],
      );
      return optionsOf(result);
    }
    case 'readOption':
      return valueOf(chart.options[args[0]], 0);
    case 'setOption': {
      // chart.options.<path> = value: the set trap of the resolver.
      const [path, value] = args;
      const {object, key} = parentOf(chart.options, path);
      object[key] = value;
      return undefined;
    }
    case 'setDefault': {
      // Chart.defaults.<path> = value; the old value comes back after the
      // case.
      const [path, value] = args;
      const {object, key} = parentOf(defaults, path);
      const had = Object.hasOwn(object, key);
      const old = object[key];
      undo.push(() => {
        if (had) object[key] = old;
        else delete object[key];
      });
      object[key] = value;
      return undefined;
    }
    case 'deleteDefault': {
      // delete Chart.defaults.<path>; the key comes back at the end of the
      // keys after the case (the case is the last one).
      const {object, key} = parentOf(defaults, args[0]);
      const old = object[key];
      undo.push(() => {
        object[key] = old;
      });
      delete object[key];
      return undefined;
    }
    case 'readScale':
      return valueOf(readPath(chart.scales[args[0]].options, args[1]), 0);
    case 'readLegend':
      return valueOf(readPath(chart.legend.options, args[0]), 0);
    case 'legendItems':
      return chart.legend.legendItems.map((item) => valueOf(item[args[0]], 1));
    case 'hitNear': {
      // The items of the mode 'point' at the data element [d, i] moved by
      // (dx, dy), with the event of the hit queries of the controller
      // generators.
      const [d, i, dx, dy] = args;
      const element = chart.getDatasetMeta(d).data[i];
      const e = {type: 'mousemove', native: null, x: element.x + dx, y: element.y + dy};
      return chart
        .getElementsAtEventForMode(e, 'point', {intersect: true}, false)
        .map((item) => [item.datasetIndex, item.index]);
    }
    default:
      throw new Error(`Not a step: ${JSON.stringify(step)}`);
  }
}

/** The value at the dotted [path] under [root], read key by key. */
function readPath(root, path) {
  let value = root;
  for (const key of path.split('.')) value = value[key];
  return value;
}

/** The object that holds the last key of the dotted [path] under [root]. */
function parentOf(root, path) {
  const keys = path.split('.');
  const key = keys.pop();
  return {object: keys.length ? readPath(root, keys.join('.')) : root, key};
}

/** The undo functions of the steps of the current case, in step order. */
let undo = [];

/** The name of the class of the thrown value [e]. */
function errorName(e) {
  return e?.name ?? e?.constructor?.name ?? typeof e;
}

/** A copy of a config before the chart writes into it. */
function copy(v) {
  if (Array.isArray(v)) return v.map(copy);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.keys(v).map((k) => [k, copy(v[k])]));
  }
  return v;
}

/**
 * One case: the setup, the chart of [config] (the step `['init']`), then
 * each of [steps]. After each step: its trace, the observations and the
 * observation trace. A throw records `error: {at, name, message}` and ends
 * the case; the step that throws keeps its `do` and its trace.
 */
function runCase(name, config, {setup = null, steps = [], animations = false} = {}) {
  const literal = copy(config);
  const cleanup = setup ? SETUPS[setup]() : null;
  const expected = {steps: []};
  let chart = null;
  try {
    const all = [['init'], ...steps];
    for (let k = 0; k < all.length; k++) {
      const step = all[k];
      trace = [];
      let result;
      try {
        if (k === 0) {
          chart = makeChart(config);
        } else {
          result = applyStep(chart, step);
        }
      } catch (e) {
        expected.steps.push({do: step, trace});
        expected.error = {at: k, name: errorName(e), message: String(e.message)};
        break;
      }
      const observed = {do: step, trace};
      trace = [];
      if (result !== undefined) observed.result = result;
      observed.datasets = datasetsOf(chart);
      if (animations) observed.animations = animationsOfChart(chart);
      observed.observeTrace = trace;
      expected.steps.push(observed);
    }
  } finally {
    chart?.destroy();
    for (const f of undo.reverse()) f();
    undo = [];
    cleanup?.();
    trace = [];
  }
  return {name, setup, config: literal, expected};
}

// ---------------------------------------------------------------------------
// The configs.

/**
 * The options of each chart: no legend, no tooltip, and hidden scales with
 * hidden ticks, so that no case measures a text (stressHiddenScale of the
 * gallery: `ticks.display: false` skips the label sizes).
 */
function baseOptions(extra = {}, {scales = true} = {}) {
  const hidden = () => ({display: false, ticks: {display: false}});
  return {
    plugins: {legend: false, tooltip: false},
    ...(scales ? {scales: {x: hidden(), y: hidden()}} : {}),
    ...extra,
  };
}

const LABELS = ['a', 'b', 'c', 'd', 'e'];
const VALUES = [1, 3, 2, 4, 3];

/** A line chart of [n] points with the dataset keys [dataset]. */
function line(dataset = {}, options = {}, n = 4) {
  return {
    type: 'line',
    data: {
      labels: LABELS.slice(0, n),
      datasets: [{data: VALUES.slice(0, n), ...dataset}],
    },
    options: baseOptions(options),
  };
}

/** A bar chart of 3 bars with the dataset keys [dataset]. */
function bar(dataset = {}, options = {}) {
  return {
    type: 'bar',
    data: {
      labels: LABELS.slice(0, 3),
      datasets: [{data: VALUES.slice(0, 3), ...dataset}],
    },
    options: baseOptions(options),
  };
}

/** A doughnut chart of 3 arcs with the dataset keys [dataset]. */
function doughnut(dataset = {}) {
  return {
    type: 'doughnut',
    data: {
      labels: LABELS.slice(0, 3),
      datasets: [{data: VALUES.slice(0, 3), ...dataset}],
    },
    options: baseOptions({}, {scales: false}),
  };
}

/** The animation options of the animation cases. */
const ANIMATION = {duration: 1000};

const cases = [
  runCase(
    'levels: a scriptable option on each scope level',
    line(
      {pointBackgroundColor: F.dsColor},
      {
        datasets: {line: {pointBorderColor: F.lineBorderColor}},
        elements: {point: {hitRadius: F.elementHitRadius}},
        rotation: F.optionRotation,
      },
    ),
    {setup: 'defBorderWidth', steps: [['update'], ['update', 'none']]},
  ),
  runCase(
    'indexable: line arrays',
    line({pointRadius: [2, 4, 6], pointBackgroundColor: ['red', 'green'], borderDash: [4, 2]}, {}, 5),
    {steps: [['update']]},
  ),
  runCase('indexable: bar arrays', bar({backgroundColor: ['red', 'green'], borderWidth: [1, 2, 3]}), {
    steps: [['update']],
  }),
  runCase(
    'hover: prefixes and a hover option that reads its second argument',
    line({pointHoverRadius: 7, pointHoverBackgroundColor: F.hoverColor}),
    {steps: [['setActive', [[0, 1]]], ['update']]},
  ),
  runCase(
    'object: bar borderRadius with a scriptable key',
    bar({borderRadius: {topLeft: 4, topRight: F.barRadius}, borderSkipped: false}),
    {steps: [['update']]},
  ),
  runCase(
    'object: arc borderRadius with a scriptable key',
    doughnut({borderRadius: {outerStart: 2, outerEnd: F.arcRadius, innerStart: 0, innerEnd: 0}}),
    {steps: [['update']]},
  ),
  runCase(
    'array of objects: indexable bar borderRadius and a chart option',
    bar(
      {borderRadius: [{topLeft: 2}, {topLeft: F.barRadius}], borderSkipped: false},
      {myList: [{a: F.listItem}, {a: 2}]},
    ),
    {steps: [['update'], ['readOption', 'myList']]},
  ),
  runCase(
    'fallback: a string _fallback of elements.bar',
    bar({borderRadius: {topLeft: 4}, borderSkipped: false}, {radiusFallback: {topRight: 6}}),
    {setup: 'fallbackString', steps: [['update']]},
  ),
  runCase(
    'fallback: _fallback true of elements.bar',
    bar({borderRadius: {topLeft: 4}, borderSkipped: false}),
    {setup: 'fallbackTrue', steps: [['update']]},
  ),
  runCase(
    'fallback: a counted _fallback function of elements.bar',
    bar({borderRadius: {topLeft: 4}, borderSkipped: false}, {radiusFallback: {topRight: 6}}),
    {setup: 'fallbackFunction', steps: [['update']]},
  ),
  runCase(
    'descriptors: user _scriptable and _indexable of elements.point',
    line({pointRadius: F.radiusFn, pointHitRadius: [3, 6], pointBackgroundColor: F.dsColor}),
    {setup: 'userDescriptors', steps: [['update']]},
  ),
  runCase(
    'recursion: a scriptable option that reads itself',
    line({pointRadius: F.selfRadius}, {}, 3),
  ),
  runCase(
    'write: a scriptable option that writes ctx.parsed',
    line({pointBorderWidth: F.writeParsed, pointRadius: F.readParsed}),
    {steps: [['update'], ['update', 'none']]},
  ),
  runCase(
    'write: a scriptable option writes radius through the sub-resolver',
    line({pointBorderWidth: F.writeRadius}, {}, 5),
    {steps: [['update']]},
  ),
  runCase(
    'defaults: a new key of defaults.elements.point during an update',
    line({pointBackgroundColor: F.addDefaultKey}),
    {setup: 'extraKey', steps: [['update']]},
  ),
  runCase(
    'resolveNamed: duplicate names and slot names',
    line({pointRadius: F.namedRadius}, {}, 3),
    {steps: [['resolveNamed', ['radius', 'radius', 'override', 'setContext', 'backgroundColor']]]},
  ),
  runCase('animation: default', line({}, {animation: {...ANIMATION}}), {
    animations: true,
    steps: [['update'], ['update', 'none']],
  }),
  runCase(
    'animation: scriptable delay',
    line({}, {animation: {...ANIMATION, delay: F.animDelay}}),
    {animations: true, steps: [['update']]},
  ),
  runCase(
    'animation: scriptable duration',
    line({}, {animation: {duration: F.animDuration}}),
    {animations: true, steps: [['update']]},
  ),
  runCase('animation: hide and show', line({}, {animation: {...ANIMATION}}), {
    animations: true,
    steps: [['hide', 0], ['show', 0]],
  }),
  runCase('animation: false', line({}, {animation: false}), {
    animations: true,
    steps: [['update']],
  }),
  runCase(
    'animation: a scriptable entry of animations',
    line({}, {animation: {...ANIMATION}, animations: {numbers: {duration: F.numbersDuration}}}),
    {animations: true, steps: [['update']]},
  ),
  runCase(
    'animation: a properties override',
    line(
      {},
      {animation: {...ANIMATION}, animations: {x: {properties: ['x'], duration: 300, easing: 'linear'}}},
    ),
    {animations: true, steps: [['update']]},
  ),
  runCase(
    'animation: a counted _fallback function of animation',
    line({}, {animation: {...ANIMATION}}),
    {setup: 'animationFallback', animations: true, steps: [['update']]},
  ),
  runCase(
    'animation: a scriptable data option deletes defaults.animation.easing',
    line({pointBackgroundColor: F.deleteEasing}, {animation: {...ANIMATION}}),
    {setup: 'deleteEasing', animations: true, steps: [['update']]},
  ),
  // The cases of B0 of the typed core (Chart.js ADR 0054).
  runCase(
    'plugin: an inline plugin writes the dataset colors in beforeLayout',
    {...bar(), plugins: [{id: 'writer', beforeLayout: F.writeColors}]},
    {steps: [['update']]},
  ),
  runCase(
    'write: a scriptable option writes the Map of another dataset',
    {
      type: 'line',
      data: {
        labels: LABELS.slice(0, 3),
        datasets: [
          {data: VALUES.slice(0, 3), pointBackgroundColor: F.writeOtherDataset},
          {data: VALUES.slice(1, 4)},
        ],
      },
      options: baseOptions(),
    },
    {steps: [['update']]},
  ),
  runCase(
    'options: a write of plugins.legend.position through chart.options',
    line({}, {plugins: {legend: {display: false}, tooltip: false}}),
    {
      steps: [
        ['readLegend', 'position'],
        ['setOption', 'plugins.legend.position', 'left'],
        ['readLegend', 'position'],
        ['update'],
        ['readLegend', 'position'],
      ],
    },
  ),
  runCase(
    'defaults: Chart.defaults.borderColor changes between two updates',
    bar({}, {plugins: {legend: {display: false}, tooltip: false}}),
    {
      steps: [
        ['readScale', 'x', 'grid.color'],
        ['legendItems', 'strokeStyle'],
        ['setDefault', 'borderColor', '#123456'],
        ['update'],
        ['readScale', 'x', 'grid.color'],
        ['legendItems', 'strokeStyle'],
      ],
    },
  ),
  runCase(
    'scale: a scriptable grid lineWidth with a context for each tick',
    line(
      {},
      {
        scales: {
          x: {display: true, ticks: {display: false}, grid: {lineWidth: F.gridWidth}},
          y: {display: false, ticks: {display: false}},
        },
      },
    ),
    {steps: [['update'], ['readScale', 'x', 'grid.lineWidth']]},
  ),
  runCase(
    'plugin: a scriptable legend label color',
    line({}, {plugins: {legend: {display: false, labels: {color: F.legendColor}}, tooltip: false}}),
    {steps: [['update'], ['readLegend', 'labels.color'], ['legendItems', 'fontColor']]},
  ),
  runCase('hit: a string pointRadius and the mode point', line({pointRadius: '5'}), {
    steps: [
      ['hitNear', 0, 1, 10, 0],
      ['hitNear', 0, 1, 20, 0],
    ],
  }),
  runCase(
    'write: a hover option writes radius in the active mode',
    line({pointHoverBorderWidth: F.writeRadiusActive}, {}, 5),
    {steps: [['setActive', [[0, 2]]], ['update']]},
  ),
  runCase(
    'scale: a user scale class as the value scale',
    line(
      {},
      {
        scales: {
          x: {display: false, ticks: {display: false}},
          y: {type: 'myScale', display: false, ticks: {display: false}},
        },
      },
    ),
    {
      setup: 'userScale',
      steps: [['update'], ['readScale', 'y', 'myScaleOption'], ['readScale', 'y', 'type']],
    },
  ),
  runCase(
    'element: a user element class as the bar data element',
    bar(),
    {setup: 'userBar', steps: [['update']]},
  ),
  // Last: the delete moves `rotation` to the end of the keys of
  // defaults.elements.point for the rest of the run.
  runCase('defaults: a delete of defaults.elements.point.rotation', line(), {
    steps: [['deleteDefault', 'elements.point.rotation'], ['update']],
  }),
];

// ---------------------------------------------------------------------------
// The output.

const build = referenceBuild();
if (build.measured !== 0) {
  throw new Error(`The cases measured ${build.measured} texts. Hide each text.`);
}
const state = {undefined: false};
const body = cases
  .map(
    (c) =>
      `  (name: ${dartLiteral(c.name, state)}, setup: ${dartLiteral(c.setup, state)}, ` +
      `config: ${dartLiteral(c.config, state)}, expected: ${dartLiteral(c.expected, state)}),\n`,
  )
  .join('');
const generator = relative(PACKAGE_ROOT, fileURLToPath(pathToFileURL(process.argv[1])));
const out = `// Original code, not ported from Chart.js: resolver trace reference data.

// Generated by ${generator}. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// a build of Chart.js v${build.version} at the commit
// ${build.commit}. ${cases.length} cases.
${state.undefined ? "\nimport 'package:flutter_chartjs_port/src/js/js_undefined.dart';\n" : ''}
/// The Node.js version that generated the data.
const String resolverTraceReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String resolverTraceReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String resolverTraceReferenceArch = '${process.arch}';

/// The Chart.js version of the build that generated the data: the pin
/// version of tool/port_sources.yaml, without its "v".
const String resolverTraceReferenceDist = '${build.version}';

/// The Chart.js commit of the build that generated the data.
const String resolverTraceReferenceCommit = '${build.commit}';

/// The \`Date.now()\` of each case, in milliseconds.
const double resolverTraceReferenceNow = ${NOW};

/// One chart of the generator (runCase of resolver_trace_reference.mjs).
///
/// - \`setup\`: the name of the setup of the case (\`_setups\` of the test),
///   or null.
/// - \`config\`: the chart config, before the harness defaults.
///   \`'fn:<name>'\` is a named user function of the test.
/// - \`expected\`: \`steps\`, one entry for each step (the first is
///   \`['init']\`, the construction): \`do\`, \`trace\`, \`result\` (a step
///   with a result), \`datasets\`, \`animations\` (the animation cases) and
///   \`observeTrace\`. \`error\` \`{at, name, message}\`: the step \`at\`
///   throws, and it has only \`do\` and \`trace\`.
typedef ResolverTraceReferenceCase = ({
  String name,
  String? setup,
  Map<String, Object?> config,
  Map<String, Object?> expected,
});

/// The cases.
const List<ResolverTraceReferenceCase> resolverTraceReference = [
${body}];
`;
writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${cases.length} cases to ${OUT} (${frames.length} frame requests kept).`);
