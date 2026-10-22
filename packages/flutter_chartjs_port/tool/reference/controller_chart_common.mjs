// Original code, not ported from Chart.js: shared code of the controller reference generators.
//
// The shared code of the generators of the phase 7 controller reference
// tests (tool/reference/controller_*_reference.mjs, Chart.js ADR 0030). A
// generator builds real charts with a build of the pinned Chart.js in
// Node.js, runs the steps of each case, records the observations, the hit
// queries and the draw calls, and writes a Dart file of reference data for a
// test in test/port/controllers/. The Dart side of this file is
// test/port/controllers/controller_chart_harness.dart. Nothing in lib/ or
// test/ runs this code (porting-flow.md section 4).
//
// This file imports tool/reference/scale_chart_common.mjs: the checks of
// loadChartJs (an x64 Node.js, the build at the pinned commit, a clean
// checkout), the Liberation Sans mock context, makeChart, observe,
// drawCalls and writeReference. See its header for the method and the
// limits of the text measure.
//
// How to run a generator
// ----------------------
//
// Build Chart.js at the pinned commit as the header of
// scale_chart_common.mjs says. Then, from packages/flutter_chartjs_port, with an
// x64 build of Node.js v24.12.0 and with the Dart SDK on the PATH:
//
//   CHARTJS_DIST=<build>/dist/chart.js \
//     node tool/reference/controller_<name>_reference.mjs
//
// The first argument can also give the path of dist/chart.js. On Apple
// silicon, run the darwin-x64 build of Node.js under Rosetta:
//
//   /usr/bin/arch -x86_64 <node-v24.12.0-darwin-x64>/bin/node \
//     tool/reference/controller_<name>_reference.mjs <build>/dist/chart.js
//
// The bar generator also needs the moment packages
// (MOMENT_NODE_MODULES, see scale_time_common.mjs) and TZ=UTC.
//
// How to write a generator: import this file first, then call loadChartJs(),
// registerPhase7(C), runControllerCase() for each case, and
// writeControllerReference(). A plugin generator of phase 8 calls
// registerBuiltins(C) (re-exported from scale_chart_common.mjs) and the
// functions of tool/reference/plugin_chart_common.mjs (Chart.js ADR 0041).
//
// The recording Path2D
// --------------------
//
// element.line.js:233 reads `typeof Path2D === 'function'` when the module
// loads. Node.js has no Path2D. A browser has one, and the canvas interface
// of the port has one (element.line.dart, `_usePath2D`). Thus this file
// defines a recording Path2D on globalThis in its module body, before any
// generator calls loadChartJs(). A line without `segment` then strokes a
// cached Path2D, as in the port and in a browser (Chart.js ADR 0030,
// section 2). The draw calls write a Path2D argument as `{path, calls}`
// (jsonValue of scale_chart_common.mjs).

import {
  CallsText,
  drawCalls,
  jsonValue,
  loadChartJs as loadDist,
  makeChart,
  named,
  observe,
  registerBuiltins,
  writeReference,
} from './scale_chart_common.mjs';

export {CallsText, drawCalls, jsonValue, makeChart, named, registerBuiltins, writeReference};

/**
 * The Path2D of a browser, as a recorder of its path commands
 * (line_reference.mjs:96-105). The methods are the path commands that
 * element.line.js and helpers.segment.js reach through helpers.canvas.ts
 * (`moveTo`, `lineTo`, `bezierCurveTo`, `closePath`), and `quadraticCurveTo`
 * and `arc` of the canvas path interface.
 */
class Path2D {
  constructor() {
    this.calls = [];
  }
}
for (const name of ['moveTo', 'lineTo', 'bezierCurveTo', 'quadraticCurveTo', 'arc', 'closePath']) {
  Path2D.prototype[name] = function (...args) {
    this.calls.push([name, args]);
  };
}
globalThis.Path2D = Path2D;

/**
 * Registers the built-in components of the Dart registry after phase 7, and
 * then [extra]: `C.Chart.register(C.controllers, C.scales, C.elements)`.
 * flutter_test_config.dart registers the namespaces `controllers`, `scales`,
 * `elements` and `plugins` (`harness-register-builtins`). In phase 7,
 * `plugins` has no entry.
 */
export function registerPhase7(C, ...extra) {
  C.Chart.register(C.controllers, C.scales, C.elements, ...extra);
}

// ---------------------------------------------------------------------------
// The plain copies.

/**
 * A plain copy of [v] for the reference data: an object (also a resolver)
 * becomes an object with the keys of `Object.keys` and the plain copies of
 * the values; an array becomes an array of the plain copies; a function
 * becomes the string `'<fn>'`. Other values stay as they are. The Dart side
 * reads the keys with `jsObjectKeys` and the values with `jsGet`.
 */
export function plain(v, seen = new Set()) {
  if (typeof v === 'function') return '<fn>';
  if (Array.isArray(v)) return v.map((x) => plain(x, seen));
  if (v && typeof v === 'object') {
    if (seen.has(v)) throw new Error('A plain copy of an object with a cycle.');
    seen.add(v);
    const out = {};
    for (const key of Object.keys(v)) out[key] = plain(v[key], seen);
    seen.delete(v);
    return out;
  }
  return v;
}

/** The plain copy of the keys [keys] of [object]: absent keys stay absent. */
function plainKeys(object, keys) {
  const out = {};
  for (const key of keys) {
    const value = object[key];
    if (value !== undefined) out[key] = plain(value);
  }
  return out;
}

// ---------------------------------------------------------------------------
// The hit queries (Chart.js ADR 0030, section 5).

/** The modes of the hit queries. */
const MODES = ['index', 'dataset', 'point', 'nearest', 'x', 'y'];

/** The chart types whose hit queries also have the axis `r`. */
const RADIAL_TYPES = new Set(['polarArea', 'radar']);

/**
 * The hit queries of [chart]: `[mode, intersect, axis, includeInvisible]`
 * for each mode of MODES, `intersect` true and false, the axes `x`, `y` and
 * `xy` (and `r` when a dataset has the type `polarArea` or `radar`), and
 * `includeInvisible` false. When a dataset or an index is hidden, each query
 * also comes with `includeInvisible` true.
 */
export function hitQueries(chart) {
  const metas = chart.data.datasets.map((_, i) => chart.getDatasetMeta(i));
  const axes = ['x', 'y', 'xy'];
  if (metas.some((meta) => RADIAL_TYPES.has(meta.type))) axes.push('r');
  const hiddenDataset = metas.some((_, i) => !chart.isDatasetVisible(i));
  const hiddenIndex = Object.values(chart._hiddenIndices).some(Boolean);
  const invisible = hiddenDataset || hiddenIndex ? [false, true] : [false];
  const queries = [];
  for (const mode of MODES) {
    for (const intersect of [true, false]) {
      for (const axis of axes) {
        for (const includeInvisible of invisible) {
          queries.push([mode, intersect, axis, includeInvisible]);
        }
      }
    }
  }
  return queries;
}

/**
 * The integer query points of [chart]: the center (`Math.round` of
 * `getCenterPoint()`) of each data element of each dataset, the midpoint
 * (`Math.round`) of each two neighbor centers in a dataset, the four corners
 * of the chart area 1 px inside, and the point `[-5, -5]` outside the
 * canvas. A point with a coordinate that is not finite drops out. A point
 * that is in the list already drops out.
 */
export function hitPoints(chart) {
  const points = [];
  const seen = new Set();
  const add = (x, y) => {
    if (!Number.isFinite(x) || !Number.isFinite(y)) return;
    const key = `${x},${y}`;
    if (seen.has(key)) return;
    seen.add(key);
    points.push([x, y]);
  };
  chart.data.datasets.forEach((_, i) => {
    const centers = chart.getDatasetMeta(i).data.map((el) => el.getCenterPoint(false));
    centers.forEach((c) => add(Math.round(c.x), Math.round(c.y)));
    for (let k = 1; k < centers.length; k++) {
      const a = centers[k - 1];
      const b = centers[k];
      add(Math.round((a.x + b.x) / 2), Math.round((a.y + b.y) / 2));
    }
  });
  const {left, top, right, bottom} = chart.chartArea;
  const l = Math.ceil(left) + 1;
  const t = Math.ceil(top) + 1;
  const r = Math.floor(right) - 1;
  const b = Math.floor(bottom) - 1;
  add(l, t);
  add(r, t);
  add(l, b);
  add(r, b);
  add(-5, -5);
  return points;
}

/**
 * `{points, queries, items}` of [chart]: `items[p][q]` is the list
 * `[[datasetIndex, index], ...]` of
 * `chart.getElementsAtEventForMode(e, mode, {intersect, axis,
 * includeInvisible}, false)` for the point `p` and the query `q`. The event
 * is `{type: 'mousemove', native: null, x, y}`: getRelativePosition returns
 * it as it is (helpers.dom.ts:105-111).
 *
 * `items` is text, as the draw calls: one JSON line `items[p]` for each
 * point. A Dart literal of the lists takes about ten times the bytes. This
 * text differs from Chart.js ADR 0030 section 3 item 6 (one raw string of
 * the draw calls for each case): the phase lead decides (U0 report, Fixes,
 * R6).
 */
export function hits(chart) {
  const points = hitPoints(chart);
  const queries = hitQueries(chart);
  const lines = points.map(([x, y]) => {
    const e = {type: 'mousemove', native: null, x, y};
    return JSON.stringify(
      queries.map(([mode, intersect, axis, includeInvisible]) =>
        chart
          .getElementsAtEventForMode(e, mode, {intersect, axis, includeInvisible}, false)
          .map((item) => [item.datasetIndex, item.index]),
      ),
    );
  });
  return {points, queries, items: new CallsText(lines.join('\n'))};
}

// ---------------------------------------------------------------------------
// The observations (Chart.js ADR 0030, section 4).

/**
 * The keys of `controller.options` that `datasetOptions` copies, by the
 * dataset type (TS 1.5). Another type copies no key.
 */
export const DATASET_OPTION_KEYS = {
  bar: [
    'barThickness',
    'maxBarThickness',
    'categoryPercentage',
    'barPercentage',
    'grouped',
    'skipNull',
    'stacked',
    'minBarLength',
  ],
  line: ['showLine', 'spanGaps', 'segment', 'drawActiveElementsOnTop'],
  scatter: ['showLine', 'spanGaps', 'segment', 'drawActiveElementsOnTop'],
  doughnut: [
    'cutout',
    'rotation',
    'circumference',
    'radius',
    'offset',
    'spacing',
    'spacingMode',
    'borderAlign',
    'animateRotate',
    'animateScale',
  ],
  pie: [
    'cutout',
    'rotation',
    'circumference',
    'radius',
    'offset',
    'spacing',
    'spacingMode',
    'borderAlign',
    'animateRotate',
    'animateScale',
  ],
  polarArea: ['spacing', 'spacingMode', 'startAngle'],
  radar: ['showLine', 'spanGaps'],
  bubble: ['radius'],
};

/** The keys of the scale options that `scaleOptions` copies. */
const SCALE_OPTION_KEYS = ['grid', 'border', 'ticks', 'title'];

/** The extra keys of the scale options of a `radialLinear` scale. */
const RADIAL_SCALE_OPTION_KEYS = ['angleLines', 'pointLabels'];

/**
 * The `options` of a scale for `scaleOptions`: the plain copy of `grid`,
 * `border`, `ticks` without `callback` and `title`, and for `radialLinear`
 * also `angleLines` and `pointLabels`.
 */
function scaleOptionsOf(scale) {
  const options = scale.options;
  const keys = [...SCALE_OPTION_KEYS];
  if (scale.type === 'radialLinear') keys.push(...RADIAL_SCALE_OPTION_KEYS);
  const out = {};
  for (const key of keys) {
    const value = plain(options[key]);
    if (key === 'ticks' && value && typeof value === 'object') delete value.callback;
    out[key] = value;
  }
  return out;
}

/** The properties of a data element of each element class. */
function elementProperties(C, el) {
  if (el instanceof C.PointElement) return ['x', 'y', 'skip', 'stop'];
  if (el instanceof C.BarElement) return ['x', 'y', 'base', 'horizontal', 'width', 'height'];
  if (el instanceof C.ArcElement) {
    return [
      'x',
      'y',
      'startAngle',
      'endAngle',
      'innerRadius',
      'outerRadius',
      'circumference',
      'fullCircles',
      'pixelMargin',
    ];
  }
  throw new Error(`No properties for the element ${el?.constructor?.name}.`);
}

/** `[x, y]` of a point `{x, y}`. */
const xy = (p) => [p.x, p.y];

/** The plain copy of a parsed item: `_stacks` as its keys only. */
function parsedItem(item) {
  if (!item || typeof item !== 'object' || Array.isArray(item)) return plain(item);
  const out = {};
  for (const key of Object.keys(item)) {
    out[key] = key === '_stacks' ? Object.keys(item._stacks) : plain(item[key]);
  }
  return out;
}

/** The line element of a dataset, or null. */
function datasetElement(line) {
  if (!line) return null;
  return {
    _loop: line._loop,
    _fullLoop: line._fullLoop,
    pointCount: line.points.length,
    segments: line.segments.map((s) => [s.start, s.end, s.loop]),
    options: plain(line.options),
  };
}

/** The `datasets` observation of the dataset [i] of [chart]. */
function observeDataset(C, chart, i) {
  const meta = chart.getDatasetMeta(i);
  const controller = meta.controller;
  const out = {
    type: meta.type,
    indexAxis: meta.indexAxis,
    xAxisID: meta.xAxisID,
    yAxisID: meta.yAxisID,
    rAxisID: meta.rAxisID,
    stack: meta.stack,
    order: meta.order,
    visible: chart.isDatasetVisible(i),
    hidden: meta.hidden,
    _clip: plain(meta._clip),
  };
  if (meta.total !== undefined) out.total = meta.total;
  if (controller._drawStart !== undefined) out._drawStart = controller._drawStart;
  if (controller._drawCount !== undefined) out._drawCount = controller._drawCount;
  out.maxOverflow = controller.getMaxOverflow();
  out.datasetOptions = plainKeys(controller.options, DATASET_OPTION_KEYS[meta.type] ?? []);
  out.parsed = meta._parsed.map(parsedItem);
  out.dataset = datasetElement(meta.dataset);
  out.data = meta.data.map((el) => {
    const props = {};
    for (const key of elementProperties(C, el)) props[key] = el[key];
    props.active = el.active;
    props.hidden = el.hidden;
    props.center = xy(el.getCenterPoint(false));
    props.tooltipPosition = xy(el.tooltipPosition(false));
    return props;
  });
  out.options = meta.data.map((el) => plain(el.options));
  out.active = meta.data.map((_, index) =>
    plain(controller.resolveDataElementOptions(index, 'active')),
  );
  out.labelAndValue = meta.data.map((_, index) => {
    const {label, value} = controller.getLabelAndValue(index);
    return {label: plain(label), value};
  });
  return out;
}

/**
 * One observation of [chart] (Chart.js ADR 0030, section 4):
 * `{chartArea, scales, stacks, datasets, hits}`. `chartArea` and `scales`
 * are the keys of `observe` of scale_chart_common.mjs. With [scaleOptions],
 * each scale also has `options` (scaleOptionsOf). `stacks` is the plain
 * copy of `chart._stacks`.
 *
 * Two options of the plugin reference tests (Chart.js ADR 0041, section 3
 * item 3): [observeExtra] is a function `(chart) => object` whose keys go
 * into the observation after `datasets`, and `hits: false` leaves out the
 * hit matrix. Without them, the observation is as before.
 */
export function observeControllers(
  chart,
  {scaleOptions = false, hits: withHits = true, observeExtra} = {},
) {
  const C = chartModule;
  const {chartArea, scales} = observe(
    chart,
    scaleOptions ? (scale) => ({options: scaleOptionsOf(scale)}) : undefined,
  );
  return {
    ...jsonValue({
      chartArea,
      scales,
      stacks: chart._stacks === undefined ? undefined : plain(chart._stacks),
      datasets: chart.data.datasets.map((_, i) => observeDataset(C, chart, i)),
    }),
    ...(observeExtra ? jsonValue(observeExtra(chart)) : {}),
    // After jsonValue: `items` is a CallsText.
    ...(withHits ? {hits: hits(chart)} : {}),
  };
}

/** The module of the dist, after loadChartJs(). */
let chartModule = null;

/**
 * Loads the dist with the checks of loadChartJs of scale_chart_common.mjs,
 * and keeps its module for the element classes of the observations. The
 * recording Path2D exists before the dist loads (the module body above).
 */
export async function loadChartJs() {
  chartModule = await loadDist();
  return chartModule;
}

// ---------------------------------------------------------------------------
// The steps (Chart.js ADR 0030, section 6).

/**
 * Applies the step [step] to [chart]. [state] keeps the last point of a
 * `hover` step: the step `['mouseout']` gets that point, and the function
 * returns the step as the Dart test runs it.
 */
export function applyStep(chart, step, state = {}) {
  const [action, ...args] = step;
  const data = (d) => chart.data.datasets[d].data;
  switch (action) {
    case 'update':
      chart.update(...args);
      return step;
    case 'setDatasetVisibility':
      chart.setDatasetVisibility(args[0], args[1]);
      chart.update();
      return step;
    case 'toggleDataVisibility':
      chart.toggleDataVisibility(args[0]);
      chart.update();
      return step;
    case 'setActive':
      chart.setActiveElements(args[0].map(([datasetIndex, index]) => ({datasetIndex, index})));
      chart.update();
      return step;
    case 'push':
      data(args[0]).push(...args.slice(1));
      chart.update();
      return step;
    case 'splice':
      data(args[0]).splice(args[1], args[2], ...args.slice(3));
      chart.update();
      return step;
    case 'reset':
      chart.reset();
      return step;
    case 'hover': {
      const [x, y] = args;
      state.last = [x, y];
      chart._eventHandler({type: 'mousemove', chart, native: {type: 'mousemove'}, x, y});
      return step;
    }
    case 'mouseout': {
      if (!state.last) throw new Error('A mouseout step needs a hover step before it.');
      const [x, y] = state.last;
      chart._eventHandler({type: 'mouseout', chart, native: {type: 'mouseout'}, x, y});
      return ['mouseout', x, y];
    }
    case 'setOption': {
      // ['setOption', path, value]: the write `chart.options.<path> = value`
      // through the `set` trap of the resolver, then chart.update()
      // (Chart.js ADR 0041, section 3 item 6). path: 'plugins.title.display'.
      const [path, value] = args;
      const keys = path.split('.');
      let target = chart.options;
      for (const k of keys.slice(0, -1)) target = target[k];
      target[keys.at(-1)] = value;
      chart.update();
      return step;
    }
    default:
      throw new Error(`Not a reference step: ${JSON.stringify(step)}`);
  }
}

/** The name of the class of the thrown value [e]. */
function errorName(e) {
  return e?.name ?? e?.constructor?.name ?? typeof e;
}

/**
 * A copy of a config before the chart writes into it: the chart adds the
 * harness defaults to the options and listens to the data arrays. A
 * function stays the same function.
 */
function copy(v) {
  if (Array.isArray(v)) return v.map(copy);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.keys(v).map((k) => [k, copy(v[k])]));
  }
  return v;
}

/**
 * One case: makeChart(config, options), `initial`, each step with its
 * observations, then drawCalls(chart), then the probes of [extras].
 * Returns {name, config, options, expected: {initial, steps: [{do,
 * observations}], drawCalls, extra?, error?}, probes}. A throw records
 * `error: {at, name}` (`at`: 'initial', 'step <k>' or 'draw'; `name`: the
 * name of the error class) and ends the case (Chart.js ADR 0030, section
 * 4). A step that throws stands in `steps` as `{do}` without
 * observations, so that the Dart test runs the same step. A throw of an
 * observation or of a probe stops the generator.
 *
 * [extras] maps a probe name to a function `(chart) => value`. `probes`
 * has the source text of each probe: writeControllerReference writes it in
 * a comment of the data file.
 *
 * [hits] and [observeExtra] go to each observeControllers call (Chart.js
 * ADR 0041, section 3 item 3).
 */
export function runControllerCase(
  name,
  config,
  {options = {}, steps = [], scaleOptions = false, extras = {}, hits = true, observeExtra} = {},
) {
  const observeOptions = {scaleOptions, hits, observeExtra};
  if (!chartModule) throw new Error('Call loadChartJs() first.');
  const literal = copy(config);
  const optionsLiteral = copy(options);
  const probes = Object.fromEntries(Object.entries(extras).map(([k, fn]) => [k, String(fn)]));
  const expected = {};
  let chart = null;
  try {
    try {
      chart = makeChart(config, copy(options));
    } catch (e) {
      expected.error = {at: 'initial', name: errorName(e)};
      return {name, config: literal, options: optionsLiteral, expected, probes};
    }
    expected.initial = observeControllers(chart, observeOptions);
    expected.steps = [];
    const state = {};
    for (let k = 0; k < steps.length; k++) {
      let done;
      try {
        done = applyStep(chart, steps[k], state);
      } catch (e) {
        // The step that throws stands in `steps` without observations.
        expected.steps.push({do: steps[k]});
        expected.error = {at: `step ${k}`, name: errorName(e)};
        return {name, config: literal, options: optionsLiteral, expected, probes};
      }
      expected.steps.push({do: done, observations: observeControllers(chart, observeOptions)});
    }
    try {
      expected.drawCalls = drawCalls(chart);
    } catch (e) {
      expected.error = {at: 'draw', name: errorName(e)};
      return {name, config: literal, options: optionsLiteral, expected, probes};
    }
    if (Object.keys(extras).length) {
      expected.extra = jsonValue(
        Object.fromEntries(Object.entries(extras).map(([k, fn]) => [k, plain(fn(chart))])),
      );
    }
    return {name, config: literal, options: optionsLiteral, expected, probes};
  } finally {
    chart?.destroy();
  }
}

/**
 * Writes the Dart file [outPath] with the [cases] of runControllerCase()
 * (writeReference of scale_chart_common.mjs). The source text of each probe
 * goes in a comment after the header, so that the Dart test gives a
 * function of the same name with the same body. A probe line of more than
 * 75 characters gives a comment line of more than 80, and writeReference
 * stops: write the probe with shorter lines.
 */
export function writeControllerReference(outPath, name, cases, {title = name} = {}) {
  const notes = [];
  const sources = new Map();
  for (const c of cases) {
    for (const [probe, source] of Object.entries(c.probes ?? {})) {
      const known = sources.get(probe);
      if (known !== undefined && known !== source) {
        throw new Error(`The probe ${probe} has two bodies.`);
      }
      sources.set(probe, source);
    }
  }
  for (const [probe, source] of sources) {
    notes.push(`The probe ${probe}:`, ...source.split('\n').map((line) => `  ${line}`));
  }
  writeReference(outPath, name, cases, {title, notes});
}
