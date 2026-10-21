// Original code, not ported from Chart.js: Scale reference generator.
//
// It writes test/port/core/scale_reference.dart, the data of
// test/port/core/core.scale_test.dart: the pipeline of a scale with a fake
// chart and the recording mock context of chartjs-test-utils. For each case,
// the script runs `init` and `update` on a test subclass of Scale, puts the
// box at its place as `core.layouts` does, runs `configure`, reads the
// results of the public methods, and runs `draw`. It records the hook order,
// the ticks and labels, the sizes, the label items and the calls on the
// context. The header records the Node.js version, the V8 version and the
// architecture. The cases are fixed, so a rerun on the same Node.js writes
// the same file. Nothing in lib/ or test/ runs this script (porting-flow.md
// section 4).
//
// The script runs the pinned upstream sources
// third_party/Chart.js/src/core/core.scale.js, core.defaults.js,
// helpers/helpers.config.ts and helpers/helpers.options.ts with the type
// stripping of Node.js. A resolve hook maps the upstream `./x.js` imports to
// the `.ts` files, and `@kurkle/color` to
// third_party/kurkle-color/src/index.esm.js. The draw calls go to the pinned
// mock context third_party/chartjs-test-utils/src/context.js, which the Dart
// MockContext ports. Check out the submodules first
// (`dart run melos run upstream`).
//
// The options of a case are a resolver over the user options, `defaults.scale`
// and `descriptors.scale`, with the chart context: the form of a scale
// option object of a chart. A function in the options is a named function
// of FUNCTIONS. The Dart test has a function of the same name.
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/scale_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0032), and the script stops
// on any other architecture.

import {execFileSync} from 'node:child_process';
import {existsSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

if (process.arch !== 'x64') {
  console.error(
    `The reference is V8 on x64; this Node.js is ${process.arch}. ` +
      'Run an x64 build of Node.js.',
  );
  process.exit(1);
}

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const CHART = new URL('Chart.js/src/', THIRD_PARTY);
const SCALE = new URL('core/core.scale.js', CHART);
const DEFAULTS = new URL('core/core.defaults.js', CHART);
const CONFIG = new URL('helpers/helpers.config.ts', CHART);
const OPTIONS = new URL('helpers/helpers.options.ts', CHART);
const CONTEXT = new URL('chartjs-test-utils/src/context.js', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL('../../test/port/core/scale_reference.dart', import.meta.url),
);

for (const file of [SCALE, DEFAULTS, CONFIG, OPTIONS, CONTEXT, KURKLE]) {
  if (!existsSync(fileURLToPath(file))) {
    console.error(
      `${fileURLToPath(file)} is missing. ` +
        'Check out the submodules with `dart run melos run upstream`.',
    );
    process.exit(1);
  }
}

registerHooks({
  resolve(specifier, context, nextResolve) {
    // The chartjs-test-utils package.json has no "type"; its src/context.js
    // is an ES module.
    if (specifier === CONTEXT.href) {
      return {url: CONTEXT.href, format: 'module', shortCircuit: true};
    }
    if (
      specifier === '@kurkle/color' &&
      context.parentURL?.includes('/third_party/Chart.js/')
    ) {
      return nextResolve(KURKLE.href, context);
    }
    // The upstream sources import `./helpers.math.js` and the other modules
    // with a `.js` suffix; most files on disk are `.ts`.
    if (
      specifier.endsWith('.js') &&
      context.parentURL?.includes('/third_party/Chart.js/')
    ) {
      const js = new URL(specifier, context.parentURL);
      const ts = new URL(specifier.replace(/\.js$/, '.ts'), context.parentURL);
      if (!existsSync(fileURLToPath(js)) && existsSync(fileURLToPath(ts))) {
        return nextResolve(ts.href, context);
      }
    }
    return nextResolve(specifier, context);
  },
});

const {default: Scale} = await import(SCALE.href);
const {default: defaults, descriptors} = await import(DEFAULTS.href);
const {_createResolver, _attachContext} = await import(CONFIG.href);
const {createContext} = await import(OPTIONS.href);
const {default: Context} = await import(CONTEXT.href);

/** The log of the hooks of the current case. */
let log = [];

/** A named function. The Dart test has a function of the same name. */
function named(name, fn) {
  fn.dartName = name;
  return fn;
}

/** The names of the scale hooks that the options can give. */
const HOOK_NAMES = [
  'beforeUpdate',
  'beforeSetDimensions',
  'afterSetDimensions',
  'beforeDataLimits',
  'afterDataLimits',
  'beforeBuildTicks',
  'afterBuildTicks',
  'beforeTickToLabelConversion',
  'afterTickToLabelConversion',
  'beforeCalculateLabelRotation',
  'afterCalculateLabelRotation',
  'beforeFit',
  'afterFit',
  'afterUpdate',
];

/** The state of the ticks at a hook: their count, or 'null'. */
const tickState = (scale) =>
  scale.ticks === null ? 'null' : String(scale.ticks.length);

/** The hook options: each records its name and the tick state. */
function hooks() {
  const out = {};
  for (const name of HOOK_NAMES) {
    out[name] = named(`hook:${name}`, (scale) => {
      log.push(`cb:${name}:${tickState(scale)}`);
    });
  }
  return out;
}

/** The functions of the options, by name. */
const FUNCTIONS = {
  // Tick callbacks: (value, index, ticks), with the scale as this.
  nullOdd: named('nullOdd', function (value, index) {
    return index % 2 ? null : 'L' + value;
  }),
  undefinedLast: named('undefinedLast', function (value, index, ticks) {
    return index === ticks.length - 1 ? undefined : 'v' + value;
  }),
  arrayLabel: named('arrayLabel', function (value) {
    return ['a' + value, 'second line'];
  }),
  longLabel: named('longLabel', function (value) {
    return 'Label number ' + value;
  }),
  numberLabel: named('numberLabel', function (value) {
    return value * 10;
  }),
  thisType: named('thisType', function (value) {
    return this.type + value;
  }),
  // Scriptable options: (context, options).
  colorByIndex: named('colorByIndex', (ctx) =>
    ctx.index % 2 ? 'red' : 'blue',
  ),
  widthByIndex: named('widthByIndex', (ctx) =>
    ctx.type === 'tick' ? ctx.index + 1 : 5,
  ),
  undefinedOddWidth: named('undefinedOddWidth', (ctx) =>
    ctx.index % 2 ? undefined : 2,
  ),
  fontByIndex: named('fontByIndex', (ctx) => ({
    size: ctx.type === 'tick' ? 10 + 2 * ctx.index : 12,
  })),
  colorByMajor: named('colorByMajor', (ctx) =>
    ctx.tick && ctx.tick.major ? 'red' : 'grey',
  ),
  // afterBuildTicks: (scale).
  dropFirst: named('dropFirst', (scale) => {
    scale.ticks = scale.ticks.slice(1);
  }),
};

/**
 * The mock context of chartjs-test-utils, with the `ToString` of the text
 * argument of `measureText`, `fillText` and `strokeText`, as the DOM applies
 * it (a `DOMString`). The mock itself keeps the value: its `measureText` of
 * the number 10 gives the width NaN, because a number has no `length`. The
 * canvas interface of the port takes a `String`.
 */
function domContext() {
  const ctx = new Context();
  for (const name of ['measureText', 'fillText', 'strokeText']) {
    const method = ctx[name];
    ctx[name] = (text, ...rest) => method(String(text), ...rest);
  }
  return ctx;
}

/** The test subclass of Scale: ticks, data limits and a linear mapping. */
class TestScale extends Scale {
  constructor(cfg, spec) {
    super(cfg);
    this._spec = spec;
  }

  determineDataLimits() {
    log.push('determineDataLimits');
    this.min = this._spec.min;
    this.max = this._spec.max;
  }

  buildTicks() {
    log.push('buildTicks');
    return this._spec.ticks.map(([value, major]) =>
      major === undefined ? {value} : {value, major},
    );
  }

  getPixelForValue(value) {
    return this.getPixelForDecimal(
      (value - this.min) / (this.max - this.min),
    );
  }
}

/** A scale of `chart.scales` for an object position: a fixed mapping. */
const otherScale = (offset) => ({
  getPixelForValue: (value) => offset + value,
});

/** The fake chart of a case. */
function fakeChart(spec) {
  const [left, top, right, bottom] = spec.chartArea;
  const metas = (spec.metas || []).map((m) => ({
    type: m.type,
    xAxisID: m.xAxisID,
    yAxisID: m.yAxisID,
    controller: {
      getMinMax(scale, canStack) {
        log.push(`getMinMax:${scale.id}:${canStack}`);
        return {min: m.min, max: m.max};
      },
    },
  }));
  const scales = {};
  for (const [id, offset] of Object.entries(spec.otherScales || {})) {
    scales[id] = otherScale(offset);
  }
  const chart = {
    width: spec.width,
    height: spec.height,
    chartArea: {left, top, right, bottom, width: right - left, height: bottom - top},
    currentDevicePixelRatio: spec.dpr ?? 1,
    data: spec.data || {},
    options: {font: defaults.font},
    scales,
    notifyPlugins(hook, args) {
      log.push(`notify:${hook}:${args.type}`);
      return true;
    },
    getContext() {
      return this.$context || (this.$context = createContext(null, {chart: this, type: 'chart'}));
    },
    getSortedVisibleDatasetMetas() {
      return metas;
    },
  };
  return chart;
}

/** The Dart literal of a number. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return Number.isInteger(v) ? `${v}.0` : String(v);
}

/** The Dart literal of a JS value. A named function is `'fn:<name>'`. */
function dart(v) {
  if (v === null) return 'null';
  if (v === undefined) return 'undefined';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'function') {
    if (!v.dartName) throw new Error(`An unnamed function: ${String(v)}`);
    return dart(`fn:${v.dartName}`);
  }
  if (typeof v === 'string') {
    // Single quotes, or double quotes for a string with a single quote
    // (prefer_single_quotes, avoid_escaping_inner_quotes).
    const quote = v.includes("'") && !v.includes('"') ? '"' : "'";
    const escaped = v.replace(/[\\$]/g, '\\$&').replaceAll(quote, `\\${quote}`);
    return `${quote}${escaped}${quote}`;
  }
  if (v instanceof CallsText) {
    if (v.text.includes("'''")) throw new Error('A call with three quotes');
    if (v.text === '') return "''";
    const raw = /[\\$]/.test(v.text) ? 'r' : '';
    return `${raw}'''\n${v.text}\n'''`;
  }
  if (Array.isArray(v)) return `<Object?>[${v.map(dart).join(', ')}]`;
  if (typeof v === 'object') {
    const entries = Object.keys(v).map((k) => `${dart(k)}: ${dart(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

/**
 * The declared parameter counts of the Dart MockContext methods with
 * optional parameters, and the value of an absent argument
 * (harness-mock-optional-args): the mock records every declared parameter.
 */
const PAD = {clip: 2, fill: 2, stroke: 1, fillText: 4, strokeText: 4};

/**
 * The value that the Dart MockContext records for a canvas setter when
 * upstream assigns `v`: the conversions of lib/src/js/js_webidl.dart.
 */
function setterValue(name, v) {
  if (v === undefined) return null;
  switch (name) {
    case 'setLineWidth':
    case 'setLineDashOffset':
      return Number(v);
    default:
      return v;
  }
}

/** A JSON value with each number that JSON cannot hold as `{"num": s}`. */
function jsonValue(v) {
  if (typeof v === 'number' && (!Number.isFinite(v) || Object.is(v, -0))) {
    return {num: Object.is(v, -0) ? '-0' : String(v)};
  }
  if (Array.isArray(v)) return v.map(jsonValue);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, jsonValue(x)]));
  }
  return v;
}

/** The items of `list` as text: one JSON value for each line. */
function jsonLines(list) {
  return new CallsText(list.map((v) => JSON.stringify(jsonValue(v))).join('\n'));
}

/**
 * The calls that the Dart MockContext records for the upstream calls, as
 * text: one JSON array `[name, ...args]` for each line. A number that JSON
 * cannot hold is `{"num": "NaN"}`, `{"num": "Infinity"}`, `{"num":
 * "-Infinity"}` or `{"num": "-0"}`.
 */
function dartCalls(calls) {
  const lines = calls.map(({name, args}) => {
    const list = dartArgs(name, args);
    const pad = PAD[name];
    if (pad) while (list.length < pad) list.push(null);
    if (name.startsWith('set') && name !== 'setLineDash' && name !== 'setTransform') {
      list[0] = setterValue(name, args[0]);
    }
    if (name === 'setLineDash') list[0] = list[0].map(Number);
    return JSON.stringify([name, ...list.map(jsonValue)]);
  });
  return new CallsText(lines.join('\n'));
}

/**
 * The canvas methods whose parameters are all numbers (`unrestricted
 * double`). The DOM applies `ToNumber` to each argument. The port passes a
 * `double`, NaN for `undefined`.
 */
const NUMBER_METHODS = new Set([
  'moveTo',
  'lineTo',
  'translate',
  'rotate',
  'rect',
  'fillRect',
  'strokeRect',
  'clearRect',
]);

/**
 * The arguments that the Dart MockContext records for the upstream
 * arguments `args` of the method `name`: the WebIDL conversions of the
 * canvas interface. The text of `measureText`, `fillText` and `strokeText`
 * is a `DOMString`: `ToString`. Their `x` and `y` are numbers. An absent
 * optional argument (`undefined`) is `null`.
 */
function dartArgs(name, args) {
  if (NUMBER_METHODS.has(name)) return args.map(Number);
  if (name === 'measureText') return [String(args[0])];
  if (name === 'fillText' || name === 'strokeText') {
    return [
      String(args[0]),
      Number(args[1]),
      Number(args[2]),
      args[3] === undefined ? null : Number(args[3]),
    ];
  }
  return args.map((a) => (a === undefined ? null : a));
}

/** The calls of dartCalls, which `dart` writes as a raw string. */
class CallsText {
  constructor(text) {
    this.text = text;
  }
}

/**
 * The value of a number field of the port for the upstream value `v`.
 *
 * A raw option value that is a string joins the number of a `+`
 * (core.scale.js:649, :1166, :1210 and others): upstream can keep the
 * joined string, for example the `height` '80' of `tickLength: '8'`. The
 * port keeps the `ToNumber` in its `double` fields `width` and `height`
 * and in the translation of a label item (differences.md row
 * `adapt-scale-option-types`). The port fields `paddingTop` and
 * `paddingBottom` keep the joined string, as upstream does. The values of
 * `getPadding` are the `ToNumber` of `value || 0`, the numbers that
 * `Math.max` in core.layouts.js takes. Another value stays as it is.
 */
const numberField = (v) => (typeof v === 'string' ? Number(v) : v);

/** A label item as a plain object. */
function labelItem(item) {
  const o = item.options;
  return {
    label: item.label,
    font: item.font.string,
    lineHeight: item.font.lineHeight,
    textOffset: item.textOffset,
    rotation: o.rotation,
    color: o.color,
    strokeColor: o.strokeColor,
    strokeWidth: o.strokeWidth === undefined ? null : Number(o.strokeWidth),
    textAlign: o.textAlign === undefined ? null : o.textAlign,
    textBaseline: o.textBaseline,
    // `ToNumber`, as the canvas call `translate` applies it: undefined is
    // NaN, and a joined string is its number (numberField).
    translation: o.translation.map(Number),
    backdrop: o.backdrop
      ? {
          left: o.backdrop.left,
          top: o.backdrop.top,
          width: o.backdrop.width,
          height: o.backdrop.height,
          color: o.backdrop.color,
        }
      : null,
  };
}

const cases = [];

/**
 * Adds the case `name`.
 *
 * - `chart`: `{width, height, chartArea: [l, t, r, b], dpr?, data?, metas?,
 *   otherScales?}`.
 * - `scale`: `{ticks: [[value, major?]], min, max, maxWidth, maxHeight,
 *   margins?, box: [left, top], ticks2?}`. `box` is the place of the box
 *   after the update; its size is the width and height of the scale.
 *   `ticks2` gives a second update with other ticks.
 * - `options`: the user options of the scale.
 */
function add(name, {chart: chartSpec, scale: scaleSpec, options}) {
  log = [];
  const chart = fakeChart(chartSpec);
  const ctx = domContext();
  const scale = new TestScale(
    {id: options.id ?? 'x', type: 'test', ctx, chart},
    {...scaleSpec},
  );
  const resolver = _createResolver([options, defaults.scale, descriptors.scale]);
  const scaleOptions = _attachContext(resolver, chart.getContext());
  scale.init(scaleOptions, {});
  scale.update(scaleSpec.maxWidth, scaleSpec.maxHeight, scaleSpec.margins);
  const hookLog = log;
  log = [];
  const updateCalls = dartCalls(ctx.getCalls());
  ctx.resetCalls();

  const after = {
    ticks: scale.ticks.map((t) => [t.value, t.label === undefined ? null : t.label]),
    // The raw `minRotation` stays: the port field holds any JS value.
    labelRotation: scale.labelRotation,
    width: numberField(scale.width),
    height: numberField(scale.height),
    // The raw paddings: the port fields hold any JS value.
    paddingLeft: scale.paddingLeft,
    paddingTop: scale.paddingTop,
    paddingRight: scale.paddingRight,
    paddingBottom: scale.paddingBottom,
    length: scale._length,
    maxLength: scale._maxLength,
    startPixel: scale._startPixel,
    endPixel: scale._endPixel,
    reversePixels: !!scale._reversePixels,
  };

  // The place of the box, as setBoxDims writes it (core.layouts.js:209-215).
  const [boxLeft, boxTop] = scaleSpec.box;
  scale.left = boxLeft;
  scale.top = boxTop;
  // The sizes of the port are numbers (numberField). core.layouts.js:212-213
  // joins a string size: that difference is in core.layouts.
  scale.right = boxLeft + numberField(scale.width);
  scale.bottom = boxTop + numberField(scale.height);
  scale.configure();

  const userBounds = scale.getUserBounds();
  const minMax = scale.getMinMax(false);
  const padding = scale.getPadding();
  const tickCount = scale.ticks.length;
  const results = {
    isHorizontal: scale.isHorizontal(),
    isFullSize: !!scale.isFullSize(),
    userBounds: [userBounds.min, userBounds.max, userBounds.minDefined, userBounds.maxDefined],
    minMax: [minMax.min, minMax.max],
    padding: [padding.left, padding.top, padding.right, padding.bottom].map(numberField),
    baseValue: scale.getBaseValue(),
    basePixel: scale.getBasePixel(),
    pixels: [...scale.ticks.map((_, i) => scale.getPixelForTick(i)), scale.getPixelForTick(tickCount)],
    decimals: [0, 0.25, 1].map((d) => scale.getPixelForDecimal(d)),
    decimalForPixel: scale.getDecimalForPixel(boxLeft + 37),
    lineWidthForFirst: tickCount ? scale.getLineWidthForValue(scale.ticks[0].value) : 0,
    lineWidthForMissing: scale.getLineWidthForValue(-12345),
    labels: scale.getLabels(),
    tickSize: tickCount ? scale._tickSize() : 0,
    maxDigits: scale._maxDigits(),
    layers: scale._layers().map((l) => l.z),
    labelItems: jsonLines(scale.getLabelItems().map(labelItem)),
  };
  results.queryLog = log;
  log = [];
  ctx.resetCalls();
  scale.draw(chart.chartArea);
  const drawCalls = dartCalls(ctx.getCalls());
  const drawLog = log;

  let secondUpdate = null;
  if (scaleSpec.ticks2) {
    log = [];
    ctx.resetCalls();
    scale._spec.ticks = scaleSpec.ticks2;
    scale.update(scaleSpec.maxWidth, scaleSpec.maxHeight, scaleSpec.margins);
    secondUpdate = {
      hooks: log,
      calls: dartCalls(ctx.getCalls()),
      ticks: scale.ticks.map((t) => [t.value, t.label === undefined ? null : t.label]),
    };
  }

  cases.push({
    name,
    chart: chartSpec,
    scale: scaleSpec,
    options,
    expected: {
      hooks: hookLog,
      updateCalls,
      ...after,
      ...results,
      drawLog,
      drawCalls,
      secondUpdate,
    },
  });
}

/** `count` tick values from `start` with `step`. */
const range = (count, start = 0, step = 1) =>
  Array.from({length: count}, (_, i) => [start + i * step]);

const wide = {width: 500, height: 400, chartArea: [40, 30, 480, 350]};

// Horizontal scales.
add('bottom, the default options, with the hooks', {
  chart: wide,
  scale: {
    ticks: range(6, 0, 2),
    min: 0,
    max: 10,
    maxWidth: 440,
    maxHeight: 200,
    margins: {left: 10, top: 0, right: 20, bottom: 0},
    box: [40, 350],
  },
  options: {axis: 'x', position: 'bottom', ...hooks()},
});
add('top, rotated long labels', {
  chart: {width: 300, height: 300, chartArea: [20, 80, 280, 290]},
  scale: {
    ticks: range(12),
    min: 0,
    max: 11,
    maxWidth: 260,
    maxHeight: 150,
    box: [20, 0],
  },
  options: {axis: 'x', position: 'top', ticks: {callback: FUNCTIONS.longLabel}},
});
add('bottom, rotation limited by maxRotation, offset', {
  chart: {width: 300, height: 300, chartArea: [20, 10, 280, 220]},
  scale: {ticks: range(10), min: 0, max: 9, maxWidth: 260, maxHeight: 150, box: [20, 220]},
  options: {
    axis: 'x',
    position: 'bottom',
    offset: true,
    ticks: {callback: FUNCTIONS.longLabel, maxRotation: 30, minRotation: 5},
  },
});
add('bottom, minRotation 90', {
  chart: {width: 512, height: 512, chartArea: [0, 0, 512, 400]},
  scale: {ticks: range(6), min: 0, max: 5, maxWidth: 512, maxHeight: 256, box: [0, 400]},
  options: {axis: 'x', position: 'bottom', ticks: {minRotation: 90}},
});
add('bottom, align start, crossAlign far, labelOffset and padding', {
  chart: wide,
  scale: {ticks: range(5, 10, 10), min: 10, max: 50, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {
    axis: 'x',
    position: 'bottom',
    ticks: {align: 'start', crossAlign: 'far', labelOffset: 5, padding: 6},
  },
});
add('bottom, align end, crossAlign center, reverse', {
  chart: wide,
  scale: {ticks: range(5, 0, 25), min: 0, max: 100, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {
    axis: 'x',
    position: 'bottom',
    reverse: true,
    ticks: {align: 'end', crossAlign: 'center', callback: FUNCTIONS.arrayLabel},
  },
});
add('top, align inner, crossAlign center, backdrops', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 0]},
  options: {
    axis: 'x',
    position: 'top',
    ticks: {
      align: 'inner',
      crossAlign: 'center',
      showLabelBackdrop: true,
      backdropPadding: 3,
      backdropColor: 'yellow',
    },
  },
});
add('top, crossAlign far, reverse, inner', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 440, maxHeight: 200, box: [40, 0]},
  options: {
    axis: 'x',
    position: 'top',
    reverse: true,
    ticks: {align: 'inner', crossAlign: 'far', callback: FUNCTIONS.arrayLabel},
  },
});
add('bottom, mirror and text stroke', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 330]},
  options: {
    axis: 'x',
    position: 'bottom',
    ticks: {mirror: true, textStrokeWidth: 2, textStrokeColor: 'black', color: 'green'},
  },
});
add('bottom, a callback that drops the odd ticks', {
  chart: wide,
  scale: {ticks: range(9), min: 0, max: 8, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {callback: FUNCTIONS.nullOdd}},
});
add('bottom, a callback that drops the last tick, and afterBuildTicks', {
  chart: wide,
  scale: {ticks: range(6), min: 0, max: 5, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {
    axis: 'x',
    position: 'bottom',
    afterBuildTicks: FUNCTIONS.dropFirst,
    ticks: {callback: FUNCTIONS.undefinedLast},
  },
});
add('bottom, number labels and this in the callback', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {callback: FUNCTIONS.numberLabel}},
});
add('bottom, the scale as this of the callback', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {callback: FUNCTIONS.thisType}},
});
add('bottom, sampleSize 3 of 12 ticks', {
  chart: wide,
  scale: {ticks: range(12), min: 0, max: 11, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {sampleSize: 3, callback: FUNCTIONS.longLabel}},
});
add('bottom, autoSkip with major ticks', {
  chart: wide,
  scale: {
    ticks: Array.from({length: 40}, (_, i) => (i % 5 === 0 ? [i, true] : [i])),
    min: 0,
    max: 39,
    maxWidth: 440,
    maxHeight: 200,
    box: [40, 350],
  },
  options: {
    axis: 'x',
    position: 'bottom',
    ticks: {major: {enabled: true}, color: FUNCTIONS.colorByMajor},
  },
});
add('bottom, autoSkip off', {
  chart: wide,
  scale: {ticks: range(40), min: 0, max: 39, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {autoSkip: false}},
});
add('bottom, autoSkip off with source auto', {
  chart: wide,
  scale: {ticks: range(40), min: 0, max: 39, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {autoSkip: false, source: 'auto'}},
});
add('bottom, maxTicksLimit 4', {
  chart: wide,
  scale: {ticks: range(20), min: 0, max: 19, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {maxTicksLimit: 4, autoSkip: false}},
});
add('bottom, grid offset and offset', {
  chart: wide,
  scale: {ticks: range(5), min: -0.5, max: 4.5, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', offset: true, grid: {offset: true}},
});
add('bottom, grid offset with one tick', {
  chart: wide,
  scale: {ticks: [[0]], min: -1, max: 1, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', grid: {offset: true}},
});
add('bottom, title with align end', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 330]},
  options: {
    axis: 'x',
    position: 'bottom',
    title: {display: true, text: 'Time', align: 'end', color: 'purple', padding: {top: 2, bottom: 6}},
  },
});
add('top, title with two lines and reverse', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 0]},
  options: {
    axis: 'x',
    position: 'top',
    reverse: true,
    title: {display: true, text: ['Line one', 'Line two'], align: 'start'},
  },
});
add('center, x axis', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 180]},
  options: {axis: 'x', position: 'center', title: {display: true, text: 'Center'}},
});
add('object position, x axis', {
  chart: {...wide, otherScales: {y: 100}},
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 140]},
  options: {axis: 'x', position: {y: 40}, title: {display: true, text: 'At y'}},
});
add('chartArea position, x axis', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 440, maxHeight: 200, box: [40, 100]},
  options: {axis: 'x', position: 'chartArea'},
});

// Vertical scales.
add('left, the default options, with the hooks', {
  chart: wide,
  scale: {
    ticks: range(5, 0, 25),
    min: 0,
    max: 100,
    maxWidth: 250,
    maxHeight: 320,
    margins: {left: 0, top: 5, right: 0, bottom: 15},
    box: [0, 30],
  },
  options: {axis: 'y', position: 'left', ...hooks()},
});
add('right, mirror, crossAlign center', {
  chart: wide,
  scale: {ticks: range(5, -2, 1), min: -2, max: 2, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {axis: 'y', position: 'right', ticks: {mirror: true, crossAlign: 'center'}},
});
add('right, mirror, crossAlign far', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {axis: 'y', position: 'right', ticks: {mirror: true, crossAlign: 'far'}},
});
add('right, mirror, crossAlign near', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {axis: 'y', position: 'right', ticks: {mirror: true, crossAlign: 'near'}},
});
add('left, mirror, crossAlign center', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left', ticks: {mirror: true, crossAlign: 'center'}},
});
add('left, mirror, crossAlign far', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left', ticks: {mirror: true, crossAlign: 'far'}},
});
add('left, crossAlign center', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left', ticks: {crossAlign: 'center'}},
});
add('left, align start, backdrops', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {
    axis: 'y',
    position: 'left',
    ticks: {align: 'start', showLabelBackdrop: true, backdropPadding: 2},
  },
});
add('right, align end, backdrops', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {
    axis: 'y',
    position: 'right',
    ticks: {align: 'end', showLabelBackdrop: true, backdropPadding: 2},
  },
});
add('right, crossAlign far, align start', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {axis: 'y', position: 'right', ticks: {crossAlign: 'far', align: 'start'}},
});
add('right, crossAlign center, align end, backdrops', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {
    axis: 'y',
    position: 'right',
    ticks: {crossAlign: 'center', align: 'end', showLabelBackdrop: true},
  },
});
add('left, crossAlign far, align end, array labels', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {
    axis: 'y',
    position: 'left',
    ticks: {crossAlign: 'far', align: 'end', callback: FUNCTIONS.arrayLabel},
  },
});
add('left, mirror, crossAlign near, title', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {
    axis: 'y',
    position: 'left',
    ticks: {mirror: true},
    title: {display: true, text: 'Value', align: 'start'},
  },
});
add('right, title with align end', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {
    axis: 'y',
    position: 'right',
    title: {display: true, text: ['Two', 'lines'], align: 'end'},
  },
});
add('center, y axis', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [240, 30]},
  options: {axis: 'y', position: 'center', title: {display: true, text: 'Center'}},
});
add('object position, y axis', {
  chart: {...wide, otherScales: {x: 50}},
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [200, 30]},
  options: {axis: 'y', position: {x: 100}, title: {display: true, text: 'At x'}},
});

// The title stroke (core.scale.js:1618-1619, chartjs/Chart.js#12130).
// `renderText` strokes each line when `strokeWidth > 0` and `strokeColor !==
// ''` (helpers.canvas.ts:458). It sets `strokeStyle` only for a truthy
// `strokeColor` (:473-474). The string strokeWidth '2' is more than 0, and
// the setter `lineWidth` applies `ToNumber`.
add('bottom, title with a stroke', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 330]},
  options: {
    axis: 'x',
    position: 'bottom',
    title: {display: true, text: 'title-x', color: '#ddd', strokeWidth: 1, strokeColor: '#333'},
  },
});
add('left, title of two lines with a stroke', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {
    axis: 'y',
    position: 'left',
    title: {
      display: true,
      text: ['title', 'y'],
      color: '#ddd',
      strokeWidth: 2,
      strokeColor: '#222',
    },
  },
});
add('bottom, title with a string strokeWidth and no strokeColor', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 330]},
  options: {axis: 'x', position: 'bottom', title: {display: true, text: 'Time', strokeWidth: '2'}},
});
add('bottom, title with an empty strokeColor', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 330]},
  options: {
    axis: 'x',
    position: 'bottom',
    title: {display: true, text: 'Time', strokeWidth: 3, strokeColor: ''},
  },
});
add('right, title with strokeWidth 0', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {
    axis: 'y',
    position: 'right',
    title: {display: true, text: 'Value', strokeWidth: 0, strokeColor: 'red'},
  },
});

// Display, data limits and metas.
add('display false', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', display: false},
});
add('display auto without a dataset', {
  chart: {...wide, metas: [{type: 'line', xAxisID: 'other', yAxisID: 'y', min: 0, max: 1}]},
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', display: 'auto'},
});
add('display auto with a dataset', {
  chart: {
    ...wide,
    metas: [
      {type: 'line', xAxisID: 'x', yAxisID: 'y', min: -5, max: 7},
      {type: 'bar', xAxisID: 'x', yAxisID: 'y', min: 2, max: 30},
    ],
  },
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', display: 'auto'},
});
add('user bounds and suggested bounds', {
  chart: {...wide, metas: [{type: 'line', xAxisID: 'x', yAxisID: 'y', min: -5, max: 7}]},
  scale: {ticks: range(4), min: -2, max: 1, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', min: 3, suggestedMax: 20, suggestedMin: -9},
});
add('user min and max', {
  chart: {...wide, metas: [{type: 'line', xAxisID: 'x', yAxisID: 'y', min: -5, max: 7}]},
  scale: {ticks: range(4), min: -10, max: -3, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', min: -4, max: 8},
});
add('a max below the data', {
  chart: {...wide, metas: [{type: 'line', xAxisID: 'x', yAxisID: 'y', min: 5, max: 7}]},
  scale: {ticks: range(4), min: 2, max: 9, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', max: 3},
});
add('labels of the data', {
  chart: {...wide, data: {labels: ['a', 'b'], xLabels: ['x1', 'x2']}},
  scale: {ticks: range(2), min: 0, max: 1, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom'},
});
add('labels of the y data', {
  chart: {...wide, data: {labels: ['a', 'b'], xLabels: ['x1', 'x2']}},
  scale: {ticks: range(2), min: 0, max: 1, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left'},
});
add('labels of the options', {
  chart: {...wide, data: {labels: ['a', 'b']}},
  scale: {ticks: range(2), min: 0, max: 1, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', labels: ['o1', 'o2', 'o3']},
});

// Grid, border, background and layers.
add('scriptable grid, ticks and border', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {
    axis: 'x',
    position: 'bottom',
    backgroundColor: 'rgba(1, 2, 3, 0.5)',
    grid: {
      color: FUNCTIONS.colorByIndex,
      lineWidth: FUNCTIONS.widthByIndex,
      tickBorderDash: [2, 3],
      tickBorderDashOffset: 1,
      tickColor: 'orange',
    },
    border: {dash: [4, 4], dashOffset: 2, color: 'navy', width: 3},
  },
});
// `_alignPixel` tests `width !== 0` (helpers.canvas.ts:127): an undefined
// line width gives NaN coordinates. `drawLine` skips the grid line with the
// falsy width, and draws the tick mark of `tickWidth` at NaN.
add('a scriptable grid line width without a result', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {
    axis: 'x',
    position: 'bottom',
    grid: {lineWidth: FUNCTIONS.undefinedOddWidth, tickWidth: 1},
  },
});
add('indexable grid colors on a left scale', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {
    axis: 'y',
    position: 'left',
    grid: {color: ['red', 'green', 'blue'], tickLength: 4},
  },
});
add('alignToPixels with a device pixel ratio of 2', {
  chart: {...wide, dpr: 2},
  scale: {ticks: range(7), min: 0, max: 6, maxWidth: 437, maxHeight: 200, box: [40.3, 350.2]},
  options: {axis: 'x', position: 'bottom', alignToPixels: true},
});
add('border display false', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', border: {display: false}},
});
add('grid display false', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', grid: {display: false}},
});
add('no lines on the chart area and no ticks', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', grid: {drawOnChartArea: false, drawTicks: false}},
});
add('tick labels hidden', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {display: false}},
});
// Raw option values in a `+` (core.scale.js:649, :652, :720-721, :734-735,
// :987-988, :1045, :1057, :1070, :1155, :1166, :1178, :1182, :1210, :1255,
// :1355, :1363, :1389, :1401): a string option joins the number, and the
// next `-`, `*`, `Math.min`, `Math.max` or canvas call takes the `ToNumber`
// of the joined string. A `-` of the raw value takes its `ToNumber`
// (:612-613, :1036, :1048, :1074, :1162, :1187, :1374).
add('bottom, string padding, tickLength and labelOffset', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 150]},
  options: {
    axis: 'x',
    position: 'bottom',
    ticks: {padding: '3', labelOffset: '5'},
    grid: {tickLength: '8'},
  },
});
add('top, string padding and labelOffset, rotated labels', {
  chart: {width: 300, height: 300, chartArea: [20, 80, 280, 290]},
  scale: {ticks: range(12), min: 0, max: 11, maxWidth: 260, maxHeight: 150, box: [20, 0]},
  options: {
    axis: 'x',
    position: 'top',
    ticks: {callback: FUNCTIONS.longLabel, padding: '3', labelOffset: '2'},
  },
});
add('top, mirror, string padding', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 0]},
  options: {axis: 'x', position: 'top', ticks: {mirror: true, padding: '3'}},
});
add('center, x axis, string padding and tickLength', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 180]},
  options: {axis: 'x', position: 'center', ticks: {padding: '3'}, grid: {tickLength: '8'}},
});
add('object position, x axis, string padding', {
  chart: {...wide, otherScales: {y: 100}},
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 140]},
  options: {axis: 'x', position: {y: 40}, ticks: {padding: '3'}},
});
add('bottom, string tickLength, tick labels hidden', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {display: false}, grid: {tickLength: '8'}},
});
add('bottom, string autoSkipPadding', {
  chart: wide,
  scale: {ticks: range(40), min: 0, max: 39, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {autoSkipPadding: '3'}},
});
add('bottom, title with a string padding', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 330]},
  options: {
    axis: 'x',
    position: 'bottom',
    title: {display: true, text: 'Time', padding: '4'},
  },
});
add('left, string padding and tickLength', {
  chart: wide,
  scale: {ticks: range(5, 0, 25), min: 0, max: 100, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left', ticks: {padding: '3'}, grid: {tickLength: '8'}},
});
add('left, mirror, string padding, crossAlign center', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left', ticks: {mirror: true, crossAlign: 'center', padding: '3'}},
});
add('left, mirror, string padding, crossAlign far', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left', ticks: {mirror: true, crossAlign: 'far', padding: '3'}},
});
add('left, string padding, crossAlign center', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left', ticks: {crossAlign: 'center', padding: '3'}},
});
add('right, mirror, string padding, crossAlign center', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {axis: 'y', position: 'right', ticks: {mirror: true, crossAlign: 'center', padding: '3'}},
});
add('right, mirror, string padding, crossAlign far', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {axis: 'y', position: 'right', ticks: {mirror: true, crossAlign: 'far', padding: '3'}},
});
add('right, string padding and tickLength, crossAlign center', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [440, 30]},
  options: {
    axis: 'y',
    position: 'right',
    ticks: {crossAlign: 'center', padding: '3'},
    grid: {tickLength: '8'},
  },
});
add('center, y axis, string padding and tickLength', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [240, 30]},
  options: {axis: 'y', position: 'center', ticks: {padding: '3'}, grid: {tickLength: '8'}},
});
add('object position, y axis, string padding and tickLength', {
  chart: {...wide, otherScales: {x: 50}},
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 250, maxHeight: 320, box: [200, 30]},
  options: {axis: 'y', position: {x: 100}, ticks: {padding: '3'}, grid: {tickLength: '8'}},
});
add('left, string tickLength, tick labels hidden', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left', ticks: {display: false}, grid: {tickLength: '8'}},
});
// `Math.min` keeps the ToNumber of a joined size that is less than
// `maxHeight` or `maxWidth` (core.scale.js:666, :672). The tickLength '0'
// gives `'0' + 0`, the string '00'. The label height and the padding join
// it: the height is 14.4, where the sum of the numbers gives 20.4. The
// empty string gives `'' + 0`, the string '0': the width '0306' is more
// than `maxWidth`, where the sum of the numbers gives 36.
add('bottom, string tickLength 0', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', grid: {tickLength: '0'}},
});
add('left, empty string tickLength', {
  chart: wide,
  scale: {ticks: range(5, 0, 25), min: 0, max: 100, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left', grid: {tickLength: ''}},
});
// Without a rotation, `_tickSize` of a horizontal scale is `w / cos`
// (core.scale.js:987, :991-992). The widest label width 20 and the padding
// '3' give the string '203', where the sum of the numbers gives 23.
add('bottom, string autoSkipPadding, no rotation', {
  chart: wide,
  scale: {ticks: range(40), min: 0, max: 39, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {autoSkipPadding: '3', maxRotation: 0}},
});
// `paddingTop` and `paddingBottom` keep the joined padding (core.scale.js:734
// -735). `getPadding` returns `this.paddingTop || 0` (:340): the string
// '7.199999999999999x' is truthy, so its `ToNumber` is NaN, where a NaN
// number gives 0.
add('left, string padding that is not a number', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 250, maxHeight: 320, box: [0, 30]},
  options: {axis: 'y', position: 'left', ticks: {padding: 'x'}},
});

// The raw `minRotation` and `maxRotation` (core.scale.js:590-622): the
// string '0' stays the labelRotation, and `labelRotation !== 0` (:691) is
// true. Two strings compare by their code units: '5' >= '30'.
add('bottom, minRotation string 0', {
  chart: wide,
  scale: {ticks: range(5), min: 0, max: 4, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {minRotation: '0'}},
});
add('bottom, minRotation string 0, long labels', {
  chart: {width: 300, height: 300, chartArea: [20, 10, 280, 220]},
  scale: {ticks: range(10), min: 0, max: 9, maxWidth: 260, maxHeight: 150, box: [20, 220]},
  options: {axis: 'x', position: 'bottom', ticks: {callback: FUNCTIONS.longLabel, minRotation: '0'}},
});
add('bottom, string minRotation 5 and maxRotation 30, long labels', {
  chart: {width: 300, height: 300, chartArea: [20, 10, 280, 220]},
  scale: {ticks: range(10), min: 0, max: 9, maxWidth: 260, maxHeight: 150, box: [20, 220]},
  options: {
    axis: 'x',
    position: 'bottom',
    ticks: {callback: FUNCTIONS.longLabel, minRotation: '5', maxRotation: '30'},
  },
});
add('bottom, minRotation 5 and maxRotation 30, long labels', {
  chart: {width: 300, height: 300, chartArea: [20, 10, 280, 220]},
  scale: {ticks: range(10), min: 0, max: 9, maxWidth: 260, maxHeight: 150, box: [20, 220]},
  options: {
    axis: 'x',
    position: 'bottom',
    ticks: {callback: FUNCTIONS.longLabel, minRotation: 5, maxRotation: 30},
  },
});
add('custom z of the layers', {
  chart: wide,
  scale: {ticks: range(3), min: 0, max: 2, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {z: 5}, grid: {z: 2}, border: {z: 1}},
});
add('no ticks', {
  chart: wide,
  scale: {ticks: [], min: 0, max: 1, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', grid: {offset: true}},
});

// Fonts and the text cache.
add('a scriptable tick font', {
  chart: wide,
  scale: {ticks: range(4), min: 0, max: 3, maxWidth: 440, maxHeight: 200, box: [40, 350]},
  options: {axis: 'x', position: 'bottom', ticks: {font: FUNCTIONS.fontByIndex}},
});
add('a second update with other labels', {
  chart: wide,
  scale: {
    ticks: range(8),
    ticks2: range(2, 100),
    min: 0,
    max: 120,
    maxWidth: 440,
    maxHeight: 200,
    box: [40, 350],
  },
  options: {axis: 'x', position: 'bottom', ...hooks()},
});

const body = cases
  .map(
    (c) =>
      `  (name: ${dart(c.name)}, chart: ${dart(c.chart)}, ` +
      `scale: ${dart(c.scale)}, options: ${dart(c.options)}, ` +
      `expected: ${dart(c.expected)}),\n`,
  )
  .join('');

const usesUndefined = /\bundefined\b/.test(body);

const out = `// Original code, not ported from Chart.js: Scale reference data.

// Generated by tool/reference/scale_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/core/core.scale.js at the pinned Chart.js, with the mock context of
// chartjs-test-utils. ${cases.length} cases.
${usesUndefined ? "\nimport 'package:flutter_chartjs/src/js/js_undefined.dart';\n" : ''}
/// The Node.js version that generated the data.
const String scaleReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String scaleReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String scaleReferenceArch = '${process.arch}';

/// One case of the scale pipeline.
///
/// - \`chart\`: \`{width, height, chartArea: [left, top, right, bottom], dpr?,
///   data?, metas?, otherScales?}\`. A meta is \`{type, xAxisID, yAxisID,
///   min, max}\`, and its controller gives \`{min, max}\`. An entry of
///   \`otherScales\` is the offset of a scale with \`getPixelForValue(v) =
///   offset + v\`.
/// - \`scale\`: \`{ticks: [[value, major?]], min, max, maxWidth, maxHeight,
///   margins?, box: [left, top], ticks2?}\` of the test subclass of Scale.
/// - \`options\`: the user options. \`'fn:<name>'\` is a named function.
/// - \`expected\`: the results of upstream.
typedef ScaleReferenceCase = ({
  String name,
  Map<String, Object?> chart,
  Map<String, Object?> scale,
  Map<String, Object?> options,
  Map<String, Object?> expected,
});

/// The cases of the scale pipeline.
const List<ScaleReferenceCase> scaleReference = [
${body}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${cases.length} cases to ${OUT}`);
