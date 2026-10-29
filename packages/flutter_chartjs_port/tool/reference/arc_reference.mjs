// Original code, not ported from Chart.js: ArcElement reference generator.
//
// It writes test/port/elements/arc_reference.dart, the data of
// test/port/elements/element.arc_test.dart: inRange results, getCenterPoint
// results and the calls that draw makes on the mock context, with the
// Node.js version, V8 version and architecture in the header. The cases are
// fixed, so a rerun on the same Node.js writes the same file. Nothing in lib/
// or test/ runs this script (porting-flow.md section 4).
//
// The script runs the pinned upstream source
// third_party/Chart.js/src/elements/element.arc.ts with the type stripping of
// Node.js. A resolve hook maps the upstream `./x.js` imports to the `.ts`
// files, and `@kurkle/color` to the pinned third_party/kurkle-color (the
// runtime dependency of Chart.js, which helpers/index.ts reaches through
// helpers.color.ts). The draw calls go to the upstream mock context,
// third_party/chartjs-test-utils/src/context.js, which the Dart MockContext
// ports. Check out the submodules first (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/arc_reference.mjs
//
// The reference is V8 13.6 on arm64 (Chart.js ADR 0045). The script does not
// stop on another architecture. The test compares each number with closeTo, but
// Chart.js ADR 0045 takes these reference data from one engine.

import {execFileSync} from 'node:child_process';
import {existsSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const SOURCE = new URL('Chart.js/src/elements/element.arc.ts', THIRD_PARTY);
const CONTEXT = new URL('chartjs-test-utils/src/context.js', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL('../../test/port/elements/arc_reference.dart', import.meta.url),
);

for (const file of [SOURCE, CONTEXT, KURKLE]) {
  if (!existsSync(fileURLToPath(file))) {
    console.error(
      `${fileURLToPath(file)} is missing. ` +
        'Check out the submodules with `dart run melos run upstream`.',
    );
    process.exit(1);
  }
}

// The upstream sources import `./helpers.math.js` and the other modules with
// a `.js` suffix; the files on disk are `.ts`. `@kurkle/color` is the pinned
// submodule. The mock context is an ES module in a package without a type.
registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === '@kurkle/color') {
      return nextResolve(KURKLE.href, context);
    }
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
    const resolved = nextResolve(specifier, context);
    return resolved.url === CONTEXT.href
      ? {...resolved, format: 'module'}
      : resolved;
  },
});

const {default: ArcElement} = await import(SOURCE.href);
const {default: Context} = await import(CONTEXT.href);

const TAU = Math.PI * 2;

/** The size of the canvas that clipSelf reads from `ctx.canvas`. */
const CANVAS_WIDTH = 300;
const CANVAS_HEIGHT = 150;

// The declared parameter counts of the Dart MockContext methods with
// optional parameters, and the value of an absent argument
// (harness-mock-optional-args): the mock records every declared parameter.
const PAD = {
  arc: [6, false],
  clip: [2, undefined],
  fill: [2, undefined],
  stroke: [1, undefined],
};

/** The Dart literal of a number. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return String(v);
}

/** The Dart literal of a string without quotes, `$` or backslashes. */
function str(v) {
  if (/['$\\]/.test(v)) throw new Error(`No Dart literal for ${v}`);
  return `'${v}'`;
}

/**
 * The Dart literal of a configuration value: `undefined` is the sentinel, an
 * array is a `List<Object?>` and an object is a `Map<String, Object?>`.
 */
function value(v) {
  if (v === undefined) return 'undefined';
  if (v === null) return 'null';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string') return str(v);
  if (Array.isArray(v)) return `<Object?>[${v.map(value).join(', ')}]`;
  if (typeof v === 'object') {
    const entries = Object.keys(v).map((k) => `${str(k)}: ${value(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${v}`);
}

/**
 * The Dart literal of a recorded argument: JS `undefined` is Dart `null`, as
 * the Dart mock records it (harness-mock-optional-args).
 */
function arg(v) {
  if (v === undefined || v === null) return 'null';
  if (Array.isArray(v)) return `[${v.map(arg).join(', ')}]`;
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string') return str(v);
  throw new Error(`No Dart literal for ${v}`);
}

/** The Dart literal of a `bool?` with `null` for `undefined`. */
function optBool(v) {
  return v === undefined ? 'null' : String(v);
}

/** The animations `{prop: [active, to]}` as `$animations`. */
function jsAnimations(anims) {
  const ret = {};
  for (const [prop, [active, to]] of Object.entries(anims)) {
    ret[prop] = {active: () => active, _to: to};
  }
  return ret;
}

/** The Dart literal of the animations `{prop: [active, to]}`. */
function dartAnimations(anims) {
  const entries = Object.entries(anims).map(
    ([prop, [active, to]]) => `${str(prop)}: (active: ${active}, to: ${value(to)})`,
  );
  return `{${entries.join(', ')}}`;
}

/** A new arc with [cfg] and the animations [anims]. */
function newArc(cfg, anims) {
  const arc = new ArcElement(cfg);
  if (Object.keys(anims).length) arc.$animations = jsAnimations(anims);
  return arc;
}

// inRange. The base arc: a quarter from angle 0 to PI / 2, radii 5 and 10,
// spacing 2 and border width 2, so the radius limits are 7 and 12.
const RANGE = {
  x: 0,
  y: 0,
  startAngle: 0,
  endAngle: Math.PI / 2,
  innerRadius: 5,
  outerRadius: 10,
};
const RANGE_OPTIONS = {spacing: 2, offset: 0, borderWidth: 2};

const inRange = [];
function addInRange(name, props, options, points, anims = {}, finals = [undefined]) {
  const cfg = {...RANGE, ...props, options};
  for (const useFinalPosition of finals) {
    for (const [chartX, chartY] of points) {
      const result = newArc(cfg, anims).inRange(chartX, chartY, useFinalPosition);
      inRange.push({
        name: `${name}: (${chartX}, ${chartY}), final ${useFinalPosition}`,
        cfg,
        anims,
        chartX,
        chartY,
        useFinalPosition,
        result,
      });
    }
  }
}

addInRange('quarter', {}, RANGE_OPTIONS, [
  [7, 0], [12, 0], [0, 7], [0, 12],
  [7 - 0.5e-6, 0], [7 - 2e-6, 0], [12 + 0.5e-6, 0], [12 + 2e-6, 0],
  [0, 7 - 2e-6], [0, 12 + 2e-6],
  [10, -0.01], [-0.01, 10], [0, 0], [6, 6], [-6, 6], [6, -6],
]);
addInRange('circumference TAU', {endAngle: 0.1, circumference: TAU}, RANGE_OPTIONS, [[-10, 0], [0, -10]]);
addInRange('circumference above TAU', {endAngle: 0.1, circumference: 7}, RANGE_OPTIONS, [[-10, 0]]);
addInRange('circumference below TAU', {endAngle: 0.1, circumference: TAU - 1e-9}, RANGE_OPTIONS, [[-10, 0], [10, 0.5]]);
addInRange('circumference undefined, sweep TAU', {endAngle: TAU}, RANGE_OPTIONS, [[-10, 0], [0, -10]]);
addInRange('circumference undefined, sweep 0.1', {endAngle: 0.1}, RANGE_OPTIONS, [[-10, 0], [10, 0.5]]);
addInRange('circumference NaN, sweep TAU', {endAngle: TAU, circumference: NaN}, RANGE_OPTIONS, [[-10, 0], [10, 0]]);
addInRange('circumference 0, sweep TAU', {endAngle: TAU, circumference: 0}, RANGE_OPTIONS, [[10, 0], [0, 10]]);
addInRange('same angles', {startAngle: 1, endAngle: 1}, RANGE_OPTIONS, [
  [10 * Math.cos(1), 10 * Math.sin(1)], [10, 0],
]);
addInRange('angles undefined', {startAngle: undefined, endAngle: undefined}, RANGE_OPTIONS, [[10, 0], [-10, 0]]);
addInRange('negative angles', {startAngle: -Math.PI / 2, endAngle: 0}, RANGE_OPTIONS, [
  [7, -7], [-7, -7], [0, -10], [10, 0],
]);
addInRange('angles above TAU', {startAngle: TAU, endAngle: TAU + Math.PI / 2}, RANGE_OPTIONS, [[7, 7], [-7, 7]]);
addInRange('radii undefined', {innerRadius: undefined, outerRadius: undefined}, RANGE_OPTIONS, [[10, 0]]);
addInRange('spacing absent', {}, {offset: 0, borderWidth: 0}, [[7, 0]]);
addInRange('spacing null', {}, {spacing: null, offset: 0, borderWidth: 0}, [[5, 0], [4.9, 0]]);
addInRange('x animation', {}, RANGE_OPTIONS, [[7, 0], [107, 0]], {x: [true, 100]}, [undefined, false, true]);
addInRange('inactive x animation', {}, RANGE_OPTIONS, [[7, 0], [107, 0]], {x: [false, 100]}, [true]);
addInRange('outerRadius animation', {}, RANGE_OPTIONS, [[20, 0]], {outerRadius: [true, 20]}, [false, true]);
addInRange('circumference animation to null', {endAngle: TAU}, RANGE_OPTIONS, [[-10, 0]], {circumference: [true, null]}, [false, true]);

// getCenterPoint and tooltipPosition.
const center = [];
function addCenter(name, cfg, anims = {}, finals = [undefined]) {
  for (const useFinalPosition of finals) {
    const {x, y} = newArc(cfg, anims).getCenterPoint(useFinalPosition);
    center.push({
      name: `${name}, final ${useFinalPosition}`,
      cfg,
      anims,
      useFinalPosition,
      x,
      y,
    });
  }
}

const QUARTER = {x: 0, y: 0, startAngle: 0, endAngle: Math.PI / 2, innerRadius: 0};
addCenter('quarter', {...QUARTER, outerRadius: Math.SQRT2, options: {spacing: 0, offset: 0, borderWidth: 0}});
addCenter('quarter, offset and spacing', {...QUARTER, outerRadius: Math.SQRT2, options: {spacing: 10, offset: 10, borderWidth: 0}});
const SECTOR = {x: 3, y: -2, startAngle: Math.PI / 4, endAngle: Math.PI, innerRadius: 5, outerRadius: 10};
addCenter('sector, offset 4 and spacing 2', {...SECTOR, options: {offset: 4, spacing: 2}});
addCenter('sector, offset 0 and spacing 3', {...SECTOR, options: {offset: 0, spacing: 3}});
addCenter('full circle', {x: 2, y: 2, startAngle: 0, endAngle: TAU, innerRadius: 0, outerRadius: 2, options: {spacing: 0, offset: 0, borderWidth: 0}});
addCenter('start angle undefined', {...SECTOR, startAngle: undefined, options: {offset: 0, spacing: 0}});
// The two half angles of the sin ties of phase 7 (Chart.js ADR 0045).
addCenter('half angle -pi/4 (the Windows CI tie)', {x: 256, y: 256, startAngle: -Math.PI / 2, endAngle: 0, innerRadius: 0, outerRadius: 382.5, options: {spacing: 0, offset: 0, borderWidth: 0}});
addCenter('half angle 7pi/6 (the U-pie tie)', {x: 0, y: 0, startAngle: Math.PI, endAngle: 4 * Math.PI / 3, innerRadius: 0, outerRadius: 2, options: {spacing: 0, offset: 0, borderWidth: 0}});
addCenter('offset absent', {...SECTOR, options: {spacing: 0}});
addCenter('offset null', {...SECTOR, options: {offset: null, spacing: 2}});
addCenter('animations', {...SECTOR, options: {offset: 4, spacing: 2}}, {startAngle: [true, 1], outerRadius: [false, 50], x: [true, 100]}, [undefined, false, true]);

// draw. The base arc: center (50, 40), angles 0.25 and 2, radii 10 and 30,
// with every option of ArcElement.defaults and two colors.
const BASE = {x: 50, y: 40, startAngle: 0.25, endAngle: 2, innerRadius: 10, outerRadius: 30};
const OPTIONS = {
  backgroundColor: 'red',
  borderColor: 'blue',
  borderAlign: 'center',
  borderDash: [],
  borderDashOffset: 0,
  borderJoinStyle: undefined,
  borderRadius: 0,
  borderWidth: 2,
  offset: 0,
  spacing: 0,
  spacingMode: 'angular',
  circular: true,
  selfJoin: false,
};

/** The canvas setters that the mock context records, with their value. */
const SETTERS = new Set([
  'setFillStyle',
  'setStrokeStyle',
  'setLineWidth',
  'setLineDashOffset',
  'setLineCap',
  'setLineJoin',
]);

/**
 * The value that the Dart MockContext records for the canvas setter `name`
 * when upstream assigns `v`. The port converts an option value as the DOM
 * setter does, with canvasStyle, canvasNumber and canvasKeyword of
 * lib/src/js/js_webidl.dart: JS `undefined` is Dart `null`, a number
 * setter applies `ToNumber`, and a keyword setter applies `ToString` to a
 * value other than `null`.
 */
function setterValue(name, v) {
  if (v === undefined) return null;
  switch (name) {
    case 'setLineWidth':
    case 'setLineDashOffset':
      return Number(v);
    case 'setLineCap':
    case 'setLineJoin':
      return v === null ? null : String(v);
    default:
      return v;
  }
}

/** The base arc with [props], the options with [options], without [drop]. */
function arcCfg(props = {}, options = {}, drop = []) {
  const o = {...OPTIONS, ...options};
  for (const key of drop) delete o[key];
  return {...BASE, ...props, options: o};
}

const draw = [];
function addDraw(name, cfg) {
  const arc = new ArcElement(cfg);
  const ctx = new Context();
  ctx.canvas = {width: CANVAS_WIDTH, height: CANVAS_HEIGHT};
  arc.draw(ctx);
  const calls = ctx.getCalls().map(({name: method, args}) => {
    const pad = PAD[method];
    const padded = [...args];
    if (pad) while (padded.length < pad[0]) padded.push(pad[1]);
    if (SETTERS.has(method)) padded[0] = setterValue(method, padded[0]);
    return [method, padded];
  });
  draw.push({
    name,
    cfg,
    calls,
    pixelMargin: arc.pixelMargin,
    fullCircles: arc.fullCircles,
  });
}

const SELF = {startAngle: 0, endAngle: 4};
const FULL = {startAngle: 0, endAngle: 2.5 * TAU, circumference: 2.5 * TAU};

addDraw('border at the center', arcCfg());
addDraw('no border', arcCfg({}, {borderWidth: 0}));
addDraw('circular false', arcCfg({}, {circular: false}));
addDraw('circular absent', arcCfg({}, {}, ['circular']));
addDraw('inner border', arcCfg({}, {borderAlign: 'inner'}));
addDraw('inner border, inner radius 0', arcCfg({innerRadius: 0}, {borderAlign: 'inner'}));
addDraw('inner border, inner radius below the pixel margin', arcCfg({innerRadius: 0.2}, {borderAlign: 'inner'}));
addDraw('inner border, join bevel', arcCfg({}, {borderAlign: 'inner', borderJoinStyle: 'bevel'}));
addDraw('join round', arcCfg({}, {borderJoinStyle: 'round'}));
addDraw('join miter', arcCfg({}, {borderJoinStyle: 'miter'}));
addDraw('self join, inner radius', arcCfg(SELF, {selfJoin: true}));
addDraw('self join, inner radius 0, join round', arcCfg({...SELF, innerRadius: 0}, {selfJoin: true, borderJoinStyle: 'round'}));
addDraw('self join, inner radius 0, join bevel', arcCfg({...SELF, innerRadius: 0}, {selfJoin: true, borderJoinStyle: 'bevel'}));
addDraw('self join, inner radius 0, join undefined', arcCfg({...SELF, innerRadius: 0}, {selfJoin: true}));
addDraw('self join, inner radius 0, join bevel, border width 6', arcCfg({...SELF, innerRadius: 0}, {selfJoin: true, borderJoinStyle: 'bevel', borderWidth: 6}));
addDraw('self join, inner radius 0, join round, border width 6, sweep 6.2', arcCfg({startAngle: 0, endAngle: 6.2, innerRadius: 0}, {selfJoin: true, borderJoinStyle: 'round', borderWidth: 6}));
addDraw('self join, inner radius, border width 6, sweep 6.2', arcCfg({startAngle: 0, endAngle: 6.2}, {selfJoin: true, borderWidth: 6}));
addDraw('self join, join miter', arcCfg(SELF, {selfJoin: true, borderJoinStyle: 'miter'}));
addDraw('self join, sweep below PI', arcCfg({startAngle: 0, endAngle: 3}, {selfJoin: true}));
addDraw('self join, sweep PI', arcCfg({startAngle: 0, endAngle: Math.PI}, {selfJoin: true}));
addDraw('self join, border radius 2', arcCfg(SELF, {selfJoin: true, borderRadius: 2}));
addDraw('self join, border radius absent', arcCfg(SELF, {selfJoin: true}, ['borderRadius']));
addDraw('self join, inner border', arcCfg(SELF, {selfJoin: true, borderAlign: 'inner'}));
addDraw('self join, full sweep, inner radius 0, join round', arcCfg({startAngle: 0, endAngle: TAU, circumference: TAU, innerRadius: 0}, {selfJoin: true, borderJoinStyle: 'round'}));
addDraw('spacing', arcCfg({}, {spacing: 4}));
addDraw('spacing, inner radius 0', arcCfg({innerRadius: 0}, {spacing: 4}));
addDraw('offset', arcCfg({}, {offset: 8}));
addDraw('offset, circumference 1.75', arcCfg({circumference: 1.75}, {offset: 8}));
addDraw('offset and spacing, circumference 1.75', arcCfg({circumference: 1.75}, {offset: 8, spacing: 4}));
addDraw('offset, circumference 5', arcCfg({startAngle: 0, endAngle: 5, circumference: 5}, {offset: 8}));
addDraw('border radius 4', arcCfg({}, {borderRadius: 4}));
addDraw('border radius object', arcCfg({}, {borderRadius: {outerStart: 2, outerEnd: 50, innerStart: 3, innerEnd: 100}}));
addDraw('border radius object, partial', arcCfg({}, {borderRadius: {outerEnd: 5, innerStart: 2}}));
addDraw('border radius 100', arcCfg({}, {borderRadius: 100}));
addDraw('border radius 6, sweep 0.05', arcCfg({startAngle: 0, endAngle: 0.05}, {borderRadius: 6}));
addDraw('border radius 4, inner radius 0', arcCfg({innerRadius: 0}, {borderRadius: 4}));
addDraw('border radius 4, circular false', arcCfg({}, {borderRadius: 4, circular: false}));
addDraw('border radius 4, spacing and offset', arcCfg({circumference: 1.75}, {borderRadius: 4, spacing: 4, offset: 8}));
addDraw('border dash', arcCfg({}, {borderDash: [5, 3], borderDashOffset: 2}));
addDraw('border dash and offset absent', arcCfg({}, {}, ['borderDash', 'borderDashOffset']));
addDraw('full circles', arcCfg(FULL));
addDraw('full circles, circumference 2 TAU', arcCfg({startAngle: 0.5, endAngle: 0.5 + 2 * TAU, circumference: 2 * TAU}));
addDraw('circumference TAU', arcCfg({startAngle: 0, endAngle: TAU, circumference: TAU}));
addDraw('full circles, inner border', arcCfg(FULL, {borderAlign: 'inner'}));
addDraw('full circles, self join', arcCfg(FULL, {selfJoin: true}));
addDraw('full circles, no border', arcCfg(FULL, {borderWidth: 0}));
addDraw('circumference 0', arcCfg({circumference: 0}));
addDraw('circumference 0, inner border', arcCfg({circumference: 0}, {borderAlign: 'inner'}));
addDraw('inner radius below 0', arcCfg({innerRadius: -0.1}));
addDraw('outer radius below 0', arcCfg({outerRadius: -1}));
addDraw('outer radius 0.1, inner border', arcCfg({innerRadius: 0, outerRadius: 0.1}, {borderAlign: 'inner'}));
addDraw('colors absent', arcCfg({}, {}, ['backgroundColor', 'borderColor']));
addDraw('angles undefined', arcCfg({startAngle: undefined, endAngle: undefined}));
addDraw('spec options, full circle', {x: 2, y: 2, startAngle: 0, endAngle: TAU, innerRadius: 0, outerRadius: 2, options: {spacing: 0, offset: 0, borderWidth: 0}});

// spacingMode (pathArc): the three modes, the default for an absent,
// null or unknown value, the trim limits for a large spacing and a small
// sweep, the raised root of 'parallel' for an inner radius of 0 and its
// limit below the outer radius, and an outer radius of 0, also after a
// negative spacing with an inner radius above 0.
addDraw('spacing, mode proportional', arcCfg({}, {spacing: 4, spacingMode: 'proportional'}));
addDraw('spacing, mode parallel', arcCfg({}, {spacing: 4, spacingMode: 'parallel'}));
addDraw('spacing, mode absent', arcCfg({}, {spacing: 4}, ['spacingMode']));
addDraw('spacing, mode null', arcCfg({}, {spacing: 4, spacingMode: null}));
addDraw('spacing, mode unknown', arcCfg({}, {spacing: 4, spacingMode: 'radial'}));
addDraw('spacing, mode proportional, inner radius 0', arcCfg({innerRadius: 0}, {spacing: 4, spacingMode: 'proportional'}));
addDraw('spacing, mode parallel, inner radius 0', arcCfg({innerRadius: 0}, {spacing: 4, spacingMode: 'parallel'}));
addDraw('spacing 40', arcCfg({}, {spacing: 40}));
addDraw('spacing 40, mode proportional', arcCfg({}, {spacing: 40, spacingMode: 'proportional'}));
addDraw('spacing 40, mode parallel', arcCfg({}, {spacing: 40, spacingMode: 'parallel'}));
addDraw('spacing 40, mode parallel, inner radius 0', arcCfg({innerRadius: 0}, {spacing: 40, spacingMode: 'parallel'}));
addDraw('spacing, sweep 0.05', arcCfg({startAngle: 0, endAngle: 0.05}, {spacing: 4}));
addDraw('spacing, mode parallel, sweep 0.05', arcCfg({startAngle: 0, endAngle: 0.05}, {spacing: 4, spacingMode: 'parallel'}));
addDraw('spacing, mode parallel, inner radius 0, sweep 0.002', arcCfg({startAngle: 0, endAngle: 0.002, innerRadius: 0}, {spacing: 4, spacingMode: 'parallel'}));
addDraw('spacing -4', arcCfg({}, {spacing: -4}));
addDraw('spacing -4, mode parallel', arcCfg({}, {spacing: -4, spacingMode: 'parallel'}));
addDraw('spacing -200', arcCfg({}, {spacing: -200}));
addDraw('spacing, mode parallel, border radius 4', arcCfg({}, {spacing: 4, spacingMode: 'parallel', borderRadius: 4}));
addDraw('spacing, mode parallel, border radius object', arcCfg({}, {spacing: 4, spacingMode: 'parallel', borderRadius: {outerStart: 2, outerEnd: 50, innerStart: 3, innerEnd: 100}}));
addDraw('spacing and offset, mode parallel, circumference 1.75', arcCfg({circumference: 1.75}, {spacing: 4, offset: 8, spacingMode: 'parallel'}));
addDraw('spacing, mode parallel, inner border', arcCfg({}, {spacing: 4, spacingMode: 'parallel', borderAlign: 'inner'}));
addDraw('spacing, mode parallel, circular false', arcCfg({}, {spacing: 4, spacingMode: 'parallel', circular: false}));
addDraw('outer radius 0', arcCfg({innerRadius: 0, outerRadius: 0}));
addDraw('outer radius 0, inner border, spacing 0.5, mode parallel', arcCfg({innerRadius: 0, outerRadius: 0}, {spacing: 0.5, spacingMode: 'parallel', borderAlign: 'inner'}));
addDraw('spacing, mode parallel, inner radius 0, sweep 0.05', arcCfg({startAngle: 0, endAngle: 0.05, innerRadius: 0}, {spacing: 4, spacingMode: 'parallel'}));
addDraw('spacing -4, mode parallel, radii 10 and 1', arcCfg({innerRadius: 10, outerRadius: 1}, {spacing: -4, spacingMode: 'parallel'}));
addDraw('full circle, spacing', arcCfg({startAngle: 0, endAngle: TAU}, {spacing: 4}));

// A full circle with selfJoin (pathFullCircle, and no clipSelf for a ring).
addDraw('self join, full circle', arcCfg({startAngle: 0, endAngle: TAU}, {selfJoin: true}));
addDraw('self join, full circle, inner radius 0', arcCfg({startAngle: 0, endAngle: TAU, innerRadius: 0}, {selfJoin: true}));
addDraw('self join, full circle, inner radius 0, join bevel', arcCfg({startAngle: 0, endAngle: TAU, innerRadius: 0}, {selfJoin: true, borderJoinStyle: 'bevel'}));
addDraw('self join, full circle, spacing and offset', arcCfg({startAngle: 0.5, endAngle: 0.5 + TAU}, {selfJoin: true, spacing: 4, offset: 8}));
addDraw('self join, full circle, spacing, mode parallel, inner radius 0', arcCfg({startAngle: 0, endAngle: TAU, innerRadius: 0}, {selfJoin: true, spacing: 4, spacingMode: 'parallel'}));
addDraw('self join, full circle, border radius 4', arcCfg({startAngle: 0, endAngle: TAU}, {selfJoin: true, borderRadius: 4}));
addDraw('self join, full circle, circular false', arcCfg({startAngle: 0, endAngle: TAU}, {selfJoin: true, circular: false}));
addDraw('self join, full circle, inner border', arcCfg({startAngle: 0, endAngle: TAU}, {selfJoin: true, borderAlign: 'inner'}));
addDraw('self join, full circle, join miter', arcCfg({startAngle: 0, endAngle: TAU}, {selfJoin: true, borderJoinStyle: 'miter'}));
addDraw('self join, sweep TAU - 1e-4', arcCfg({startAngle: 0, endAngle: TAU - 1e-4}, {selfJoin: true}));
addDraw('self join, sweep TAU - 2e-4', arcCfg({startAngle: 0, endAngle: TAU - 2e-4}, {selfJoin: true}));
addDraw('self join, sweep -TAU', arcCfg({startAngle: TAU, endAngle: 0}, {selfJoin: true}));
addDraw('self join, sweep -TAU, circumference 3 TAU + 4', arcCfg({startAngle: TAU, endAngle: 0, circumference: 3 * TAU + 4}, {selfJoin: true}));
addDraw('self join, full circle, angles undefined', arcCfg({startAngle: undefined, endAngle: undefined, circumference: TAU}, {selfJoin: true}));
addDraw('self join, circumference 3 TAU, inner radius 0', arcCfg({startAngle: 0, endAngle: 3 * TAU, circumference: 3 * TAU, innerRadius: 0}, {selfJoin: true}));

const inRangeBody = inRange
  .map(
    (c) => `  (
    name: ${str(c.name)},
    cfg: ${value(c.cfg)},
    animations: ${dartAnimations(c.anims)},
    chartX: ${num(c.chartX)},
    chartY: ${num(c.chartY)},
    useFinalPosition: ${optBool(c.useFinalPosition)},
    result: ${c.result},
  ),
`,
  )
  .join('');

const centerBody = center
  .map(
    (c) => `  (
    name: ${str(c.name)},
    cfg: ${value(c.cfg)},
    animations: ${dartAnimations(c.anims)},
    useFinalPosition: ${optBool(c.useFinalPosition)},
    x: ${num(c.x)},
    y: ${num(c.y)},
  ),
`,
  )
  .join('');

const drawBody = draw
  .map(
    (c) => `  (
    name: ${str(c.name)},
    cfg: ${value(c.cfg)},
    calls: [
${c.calls
  .map(([method, args]) => `      ('${method}', [${args.map(arg).join(', ')}]),\n`)
  .join('')}    ],
    pixelMargin: ${num(c.pixelMargin)},
    fullCircles: ${num(c.fullCircles)},
  ),
`,
  )
  .join('');

const count = inRange.length + center.length + draw.length;
const out = `// Original code, not ported from Chart.js: ArcElement reference data.

// Generated by tool/reference/arc_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/elements/element.arc.ts at the pinned Chart.js, with the mock context of
// chartjs-test-utils src/context.js. ${count} cases.

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// The Node.js version that generated the reference data.
const String arcReferenceNode = '${process.version}';

/// The V8 version that generated the reference data.
const String arcReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the reference data.
const String arcReferenceArch = '${process.arch}';

/// The \`width\` of \`ctx.canvas\` in [arcDrawReference].
const int arcReferenceCanvasWidth = ${CANVAS_WIDTH};

/// The \`height\` of \`ctx.canvas\` in [arcDrawReference].
const int arcReferenceCanvasHeight = ${CANVAS_HEIGHT};

/// An animation of \`$animations\`: \`{active: () => active, _to: to}\`.
typedef ArcReferenceAnimation = ({bool active, Object? to});

/// One inRange call on \`new ArcElement(cfg)\` with the animations.
typedef ArcInRangeReferenceCase = ({
  String name,
  Map<String, Object?> cfg,
  Map<String, ArcReferenceAnimation> animations,
  double chartX,
  double chartY,
  bool? useFinalPosition,
  bool result,
});

/// One getCenterPoint call on \`new ArcElement(cfg)\` with the animations.
typedef ArcCenterReferenceCase = ({
  String name,
  Map<String, Object?> cfg,
  Map<String, ArcReferenceAnimation> animations,
  bool? useFinalPosition,
  double x,
  double y,
});

/// One draw call on \`new ArcElement(cfg)\`: the calls on the mock context,
/// with the parameter lists of MockContext (harness-mock-optional-args), and
/// the pixelMargin and fullCircles after the draw.
typedef ArcDrawReferenceCase = ({
  String name,
  Map<String, Object?> cfg,
  List<(String, List<Object?>)> calls,
  double pixelMargin,
  double fullCircles,
});

/// The inRange cases.
const List<ArcInRangeReferenceCase> arcInRangeReference = [
${inRangeBody}];

/// The getCenterPoint cases.
const List<ArcCenterReferenceCase> arcCenterReference = [
${centerBody}];

/// The draw cases. The mock context has a canvas of
/// [arcReferenceCanvasWidth] x [arcReferenceCanvasHeight].
const List<ArcDrawReferenceCase> arcDrawReference = [
${drawBody}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${count} cases to ${OUT}`);
