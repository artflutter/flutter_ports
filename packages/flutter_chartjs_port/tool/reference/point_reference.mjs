// Original code, not ported from Chart.js: PointElement reference generator.
//
// It writes test/port/elements/point_reference.dart, the data of
// test/port/elements/element.point_test.dart: the results of inRange,
// inXRange, inYRange and getCenterPoint at the edges of the hit radius, of
// size and getRange, and the calls that draw makes on the mock context of
// chartjs-test-utils. The header records the Node.js version, the V8 version
// and the architecture. The cases are fixed, so a rerun on the same Node.js
// writes the same file. Nothing in lib/ or test/ runs this script
// (porting-flow.md section 4).
//
// The script runs the pinned upstream source
// third_party/Chart.js/src/elements/element.point.ts with the type stripping
// of Node.js. A resolve hook maps the upstream `./x.js` imports to the `.ts`
// files. The draw calls go to the pinned mock context
// third_party/chartjs-test-utils/src/context.js, which the Dart MockContext
// ports. Check out the submodules first (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/point_reference.mjs
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

const SOURCE = new URL(
  '../../../../third_party/Chart.js/src/elements/element.point.ts',
  import.meta.url,
);
const CONTEXT = new URL(
  '../../../../third_party/chartjs-test-utils/src/context.js',
  import.meta.url,
);
const OUT = fileURLToPath(
  new URL('../../test/port/elements/point_reference.dart', import.meta.url),
);

for (const file of [SOURCE, CONTEXT]) {
  if (!existsSync(fileURLToPath(file))) {
    console.error(
      `${fileURLToPath(file)} is missing. ` +
        'Check out the submodules with `dart run melos run upstream`.',
    );
    process.exit(1);
  }
}

// The upstream sources import `../core/core.element.js` and the other
// modules with a `.js` suffix; the files on disk are `.ts`.
registerHooks({
  resolve(specifier, context, nextResolve) {
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
  // chartjs-test-utils has no "type" in its package.json. Its src/context.js
  // is an ES module.
  load(url, context, nextLoad) {
    if (url === CONTEXT.href) return nextLoad(url, {...context, format: 'module'});
    return nextLoad(url, context);
  },
});

const {default: PointElement} = await import(SOURCE.href);
const {default: Context} = await import(CONTEXT.href);

/** The next double above `x`. */
function nextUp(x) {
  const view = new DataView(new ArrayBuffer(8));
  view.setFloat64(0, x);
  const bits = view.getBigUint64(0);
  view.setBigUint64(0, x >= 0 ? bits + 1n : bits - 1n);
  return view.getFloat64(0);
}

/** The next double below `x`. */
function nextDown(x) {
  return -nextUp(-x);
}

/**
 * The test image: an 8 x 6 image, `pointImage` in the data. drawPoint tests
 * `style.toString()` for an image (helpers.canvas.ts:181-182).
 */
const IMAGE = {
  width: 8,
  height: 6,
  toString() {
    return '[object HTMLImageElement]';
  },
};

/** An absent key in `opts` and `cfg`. */
const ABSENT = Symbol('absent');

/** An absent optional argument that the Dart MockContext records as null. */
const PAD_NULL = Symbol('pad');

/** The Dart literal of a number. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return String(v);
}

/** The Dart literal of a JS value. */
function dart(v) {
  if (v === IMAGE) return 'pointImage';
  if (v === PAD_NULL || v === null) return 'null';
  if (v === undefined) return 'undefined';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string') {
    // Single quotes, or double quotes for a string with a single quote
    // (prefer_single_quotes, avoid_escaping_inner_quotes).
    const quote = v.includes("'") && !v.includes('"') ? '"' : "'";
    const escaped = v.replace(/[\\$]/g, '\\$&').replaceAll(quote, `\\${quote}`);
    return `${quote}${escaped}${quote}`;
  }
  if (typeof v === 'object') {
    const entries = Object.keys(v).map((k) => `${dart(k)}: ${dart(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

/** A copy of `object` without the keys whose value is ABSENT. */
function present(object) {
  const out = {};
  for (const key of Object.keys(object)) {
    if (object[key] !== ABSENT) out[key] = object[key];
  }
  return out;
}

/**
 * The declared parameter counts of the Dart MockContext methods with
 * optional parameters, and the value of an absent argument
 * (harness-mock-optional-args): the mock records every declared parameter.
 */
const PAD = {
  arc: [6, false],
  fill: [2, PAD_NULL],
  stroke: [1, PAD_NULL],
  drawImage: [5, PAD_NULL],
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

/**
 * The calls that the Dart MockContext records for the upstream calls.
 * A setter records its value as setterValue gives it.
 */
function dartCalls(calls) {
  return calls.map(({name, args}) => {
    const list = [...args];
    const pad = PAD[name];
    if (pad) while (list.length < pad[0]) list.push(pad[1]);
    if (SETTERS.has(name)) list[0] = setterValue(name, list[0]);
    return [name, list];
  });
}

/** The point element of `cfg`, with `$animations` from `anims`. */
function element(cfg, anims) {
  const point = new PointElement(present(cfg));
  if (anims) {
    point.$animations = {};
    for (const [prop, {active, to}] of Object.entries(anims)) {
      point.$animations[prop] = {active: () => active, _to: to};
    }
  }
  return point;
}

/** The Dart literal of the animations of a case. */
function dartAnims(anims) {
  if (!anims) return 'null';
  const entries = Object.entries(anims).map(
    ([prop, {active, to}]) =>
      `${dart(prop)}: (active: ${active}, to: ${dart(to)})`,
  );
  return `{${entries.join(', ')}}`;
}

// inRange, inXRange, inYRange and getCenterPoint.

const inRangeCases = [];
function addInRange(name, cfg, anims, mouseX, mouseY, useFinalPosition) {
  const point = element(cfg, anims);
  const center = point.getCenterPoint(useFinalPosition);
  inRangeCases.push({
    name,
    cfg: present(cfg),
    anims,
    mouseX,
    mouseY,
    useFinalPosition,
    inRange: point.inRange(mouseX, mouseY, useFinalPosition),
    inXRange: point.inXRange(mouseX, useFinalPosition),
    inYRange: point.inYRange(mouseY, useFinalPosition),
    // getCenterPoint copies x and y. ElementPoint gives the ToNumber of a
    // copied undefined, NaN.
    centerX: Number(center.x),
    centerY: Number(center.y),
  });
}

{
  // radius 2 + hitRadius 3: the hit radius is 5.
  const cfg = {options: {radius: 2, hitRadius: 3}, x: 10, y: 15};
  const at = (name, mx, my) => addInRange(name, cfg, null, mx, my, undefined);
  at('the center', 10, 15);
  at('distance 5 on a 3-4-5 triangle', 13, 19);
  at('just inside on a 3-4-5 triangle', 13, nextDown(19));
  at('just outside on a 3-4-5 triangle', 13, nextUp(19));
  at('just outside in x on a 3-4-5 triangle', nextUp(13), 19);
  at('distance 5 to the right', 15, 15);
  at('just inside to the right', nextDown(15), 15);
  at('just outside to the right', nextUp(15), 15);
  at('distance 5 to the left', 5, 15);
  at('just inside to the left', nextUp(5), 15);
  at('distance 5 below', 10, 20);
  at('just inside below', 10, nextDown(20));
  at('distance 5 above', 10, 10);
  at('just inside above', 10, nextUp(10));
  at('a NaN mouse position', NaN, NaN);
  at('an infinite mouse position', Infinity, -Infinity);
}
{
  // 0.1 + 0.2 and 0.4 - 0.1 round up to 0.30000000000000004.
  const cfg = {options: {radius: 0.2, hitRadius: 0.1}, x: 0.1, y: 0.2};
  addInRange('rounded sums at the edge', cfg, null, 0.4, 0.2, undefined);
  addInRange('rounded sums inside', cfg, null, 0.39, 0.2, undefined);
  addInRange('rounded sums on a diagonal', cfg, null, 0.3, 0.4, undefined);
}
addInRange(
  'no hitRadius',
  {options: {radius: 2}, x: 10, y: 15},
  null,
  10,
  15,
  undefined,
);
addInRange(
  'a hitRadius of undefined',
  {options: {radius: 2, hitRadius: undefined}, x: 10, y: 15},
  null,
  10,
  15,
  undefined,
);
addInRange(
  'a hitRadius of null, inside',
  {options: {radius: 2, hitRadius: null}, x: 10, y: 15},
  null,
  nextDown(12),
  15,
  undefined,
);
addInRange(
  'a hitRadius of null, at the edge',
  {options: {radius: 2, hitRadius: null}, x: 10, y: 15},
  null,
  12,
  15,
  undefined,
);
addInRange(
  'an infinite radius',
  {options: {radius: Infinity, hitRadius: 1}, x: 10, y: 15},
  null,
  1e300,
  -1e300,
  undefined,
);
addInRange(
  'no x',
  {options: {radius: 2, hitRadius: 3}, y: 15},
  null,
  10,
  15,
  undefined,
);
{
  // x animates from 10 to 20. The animation of y is not active.
  const cfg = {options: {radius: 2, hitRadius: 3}, x: 10, y: 15};
  const anims = {x: {active: true, to: 20}, y: {active: false, to: 99}};
  for (const ufp of [undefined, false, true]) {
    addInRange(
      `the target of x, useFinalPosition ${ufp}`,
      cfg,
      anims,
      20,
      15,
      ufp,
    );
    addInRange(
      `the current x, useFinalPosition ${ufp}`,
      cfg,
      anims,
      10,
      15,
      ufp,
    );
  }
  addInRange(
    'just outside the target of x, useFinalPosition true',
    cfg,
    anims,
    25,
    15,
    true,
  );
  addInRange(
    'just inside the target of x, useFinalPosition true',
    cfg,
    anims,
    nextDown(25),
    15,
    true,
  );
  addInRange(
    'a target of undefined, useFinalPosition true',
    cfg,
    {x: {active: true, to: undefined}},
    10,
    15,
    true,
  );
  addInRange(
    'the target of y, useFinalPosition true',
    cfg,
    {y: {active: true, to: 30}},
    10,
    nextUp(25),
    true,
  );
}

// size.

const sizeCases = [];
function addSize(name, elementOptions, options) {
  const cfg = elementOptions === ABSENT ? {} : {options: elementOptions};
  const point = new PointElement(cfg);
  const size = options === ABSENT ? point.size() : point.size(options);
  sizeCases.push({name, elementOptions, options, size});
}

addSize('radius 3, hoverRadius 4, borderWidth 1', ABSENT, {
  radius: 3,
  hoverRadius: 4,
  borderWidth: 1,
});
addSize('radius 5, hoverRadius 4, borderWidth 1', ABSENT, {
  radius: 5,
  hoverRadius: 4,
  borderWidth: 1,
});
addSize('radius 0, hoverRadius 4, borderWidth 1', ABSENT, {
  radius: 0,
  hoverRadius: 4,
  borderWidth: 1,
});
addSize('radius 3 alone', ABSENT, {radius: 3});
addSize('radius 3, borderWidth 2', ABSENT, {radius: 3, borderWidth: 2});
addSize('no radius', ABSENT, {hoverRadius: 4, borderWidth: 2});
addSize('radius NaN', ABSENT, {radius: NaN, hoverRadius: 4, borderWidth: 1});
addSize('radius null', ABSENT, {radius: null, hoverRadius: 4, borderWidth: 1});
addSize('radius undefined', ABSENT, {
  radius: undefined,
  hoverRadius: 4,
  borderWidth: 1,
});
addSize('radius -1', ABSENT, {radius: -1, hoverRadius: 4, borderWidth: 1});
addSize('negative hoverRadius and borderWidth', ABSENT, {
  radius: 3,
  hoverRadius: -5,
  borderWidth: -1,
});
addSize('hoverRadius and borderWidth NaN', ABSENT, {
  radius: 3,
  hoverRadius: NaN,
  borderWidth: NaN,
});
addSize('fractions', ABSENT, {radius: 0.1, hoverRadius: 0.05, borderWidth: 0.2});
addSize('an infinite radius', ABSENT, {
  radius: Infinity,
  hoverRadius: 4,
  borderWidth: 1,
});
addSize('an empty object', ABSENT, {});
addSize(
  'the options of the element',
  {radius: 3, hoverRadius: 4, borderWidth: 1},
  ABSENT,
);
addSize(
  'the argument before the options of the element',
  {radius: 3, hoverRadius: 4, borderWidth: 1},
  {radius: 2},
);
addSize('no options', ABSENT, ABSENT);

// getRange.

const getRangeCases = [];
function addGetRange(name, options) {
  const cfg = options === ABSENT ? {} : {options};
  getRangeCases.push({name, options, range: new PointElement(cfg).getRange()});
}

addGetRange('radius 3, hitRadius 1', {radius: 3, hitRadius: 1});
addGetRange('fractions', {radius: 0.1, hitRadius: 0.2});
addGetRange('a hitRadius of null', {radius: 3, hitRadius: null});
addGetRange('no hitRadius', {radius: 3});
addGetRange('an empty object', {});
addGetRange('no options', ABSENT);

// draw.

const drawCases = [];
const AREA = {left: 0, top: 0, right: 100, bottom: 100};
function addDraw(name, cfg, area = AREA) {
  const ctx = new Context();
  ctx.drawImage = (...args) => ctx.record('drawImage', args);
  const point = new PointElement(present(cfg));
  point.draw(ctx, area === ABSENT ? undefined : area);
  drawCases.push({name, cfg: present(cfg), area, calls: ctx.getCalls()});
}

/** The options of a drawn point, with the keys of `extra`. */
function opts(extra) {
  return present({
    radius: 5,
    hitRadius: 1,
    hoverRadius: 4,
    borderWidth: 2,
    borderColor: 'red',
    backgroundColor: 'blue',
    ...extra,
  });
}

const STYLES = [
  'circle', 'triangle', 'rectRounded', 'rect', 'rectRot', 'cross',
  'crossRot', 'star', 'line', 'dash', false, 'unknown', ABSENT,
];
for (const style of STYLES) {
  for (const rotation of [ABSENT, 30]) {
    const styleName = style === ABSENT ? 'no pointStyle' : `pointStyle ${dart(style)}`;
    const rotationName = rotation === ABSENT ? 'no rotation' : `rotation ${rotation}`;
    addDraw(`${styleName}, ${rotationName}`, {
      options: opts({pointStyle: style, rotation}),
      x: 50,
      y: 40,
    });
  }
}
for (const [style, rotations] of [
  ['rect', [0, 45, 90, 405, -30]],
  ['triangle', [90, -45, 360]],
  ['star', [15]],
  ['line', [90]],
  ['dash', [-90]],
]) {
  for (const rotation of rotations) {
    addDraw(`pointStyle ${dart(style)}, rotation ${rotation}`, {
      options: opts({pointStyle: style, rotation}),
      x: 50,
      y: 40,
    });
  }
}
for (const rotation of [ABSENT, 45]) {
  addDraw(
    `an image, ${rotation === ABSENT ? 'no rotation' : `rotation ${rotation}`}`,
    {options: opts({pointStyle: IMAGE, rotation}), x: 50, y: 40},
  );
}
addDraw('fractions', {
  options: opts({radius: 2.5, pointStyle: 'star', rotation: 12.5}),
  x: 50.5,
  y: 40.25,
});

addDraw('skip true', {options: opts({}), x: 50, y: 40, skip: true});
addDraw('skip false', {options: opts({}), x: 50, y: 40, skip: false});
for (const radius of [0.09, 0.1, 0, -1, null, NaN, ABSENT]) {
  const name = radius === ABSENT ? 'no radius' : `radius ${radius}`;
  addDraw(name, {options: opts({radius}), x: 50, y: 40});
}
for (const borderWidth of [0, -1, ABSENT]) {
  const name =
    borderWidth === ABSENT ? 'no borderWidth' : `borderWidth ${borderWidth}`;
  addDraw(name, {options: opts({borderWidth}), x: 50, y: 40});
}
addDraw('no colors', {
  options: opts({borderColor: ABSENT, backgroundColor: ABSENT}),
  x: 50,
  y: 40,
});
addDraw('no area', {options: opts({}), x: -1000, y: 5000}, ABSENT);

// radius 3, hoverRadius 4, borderWidth 1: size 10, margin 5.
const MARGIN5 = {radius: 3, hoverRadius: 4, borderWidth: 1};
for (const [name, x, y] of [
  ['inside the area', 50, 50],
  ['at the margin to the left', -5, 50],
  ['just inside the margin to the left', nextUp(-5), 50],
  ['just outside the margin to the left', nextDown(-5), 50],
  ['at the margin to the right', 105, 50],
  ['just inside the margin to the right', nextDown(105), 50],
  ['at the margin above', 50, -5],
  ['just inside the margin above', 50, nextUp(-5)],
  ['at the margin below', 50, 105],
  ['just inside the margin below', 50, nextDown(105)],
]) {
  addDraw(`margin 5, ${name}`, {options: opts(MARGIN5), x, y});
}
// radius 3, hoverRadius 1, borderWidth 0: size 6, margin 3.
const MARGIN3 = {radius: 3, hoverRadius: 1, borderWidth: 0};
addDraw('margin 3, at the margin', {options: opts(MARGIN3), x: -3, y: 50});
addDraw('margin 3, just inside the margin', {
  options: opts(MARGIN3),
  x: nextUp(-3),
  y: 50,
});
// No radius: size 0, so the margin is the default 0.5.
addDraw('margin 0.5, at the margin', {
  options: opts({radius: ABSENT}),
  x: -0.5,
  y: 50,
});
addDraw('margin 0.5, just inside the margin', {
  options: opts({radius: ABSENT}),
  x: nextUp(-0.5),
  y: 50,
});

// The Dart file.

const inRangeBody = inRangeCases
  .map(
    (c) => `  (
    name: ${dart(c.name)},
    cfg: ${dart(c.cfg)},
    animations: ${dartAnims(c.anims)},
    mouseX: ${num(c.mouseX)},
    mouseY: ${num(c.mouseY)},
    useFinalPosition: ${c.useFinalPosition === undefined ? 'null' : c.useFinalPosition},
    inRange: ${c.inRange},
    inXRange: ${c.inXRange},
    inYRange: ${c.inYRange},
    centerX: ${num(c.centerX)},
    centerY: ${num(c.centerY)},
  ),
`,
  )
  .join('');

const sizeBody = sizeCases
  .map(
    (c) => `  (
    name: ${dart(c.name)},
    elementOptions: ${c.elementOptions === ABSENT ? 'null' : dart(c.elementOptions)},
    options: ${c.options === ABSENT ? 'null' : dart(c.options)},
    size: ${num(c.size)},
  ),
`,
  )
  .join('');

const getRangeBody = getRangeCases
  .map(
    (c) => `  (
    name: ${dart(c.name)},
    options: ${c.options === ABSENT ? 'null' : dart(c.options)},
    range: ${num(c.range)},
  ),
`,
  )
  .join('');

const drawBody = drawCases
  .map(
    (c) => `  (
    name: ${dart(c.name)},
    cfg: ${dart(c.cfg)},
    area: ${
      c.area === ABSENT
        ? 'null'
        : `(left: ${num(c.area.left)}, top: ${num(c.area.top)}, right: ${num(c.area.right)}, bottom: ${num(c.area.bottom)})`
    },
    calls: [
${dartCalls(c.calls)
  .map(([name, args]) => `      (${dart(name)}, [${args.map(dart).join(', ')}]),\n`)
  .join('')}    ],
  ),
`,
  )
  .join('');

const total =
  inRangeCases.length + sizeCases.length + getRangeCases.length + drawCases.length;

const out = `// Original code, not ported from Chart.js: PointElement reference data.

// Generated by tool/reference/point_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/elements/element.point.ts at the pinned Chart.js, with the mock context
// of chartjs-test-utils. ${total} cases.

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// The Node.js version that generated this file.
const String pointReferenceNode = '${process.version}';

/// The V8 version that generated this file.
const String pointReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated this file.
const String pointReferenceArch = '${process.arch}';

/// Stands for the test image (8 x 6) in [pointDrawReference], as a point
/// style and as a drawImage argument.
const Symbol pointImage = #image;

/// An animation of \`$animations\`: the result of \`active()\` and \`_to\`.
typedef PointReferenceAnimation = ({bool active, Object? to});

/// One call of inRange, inXRange, inYRange and getCenterPoint.
typedef PointInRangeCase = ({
  String name,
  Map<String, Object?> cfg,
  Map<String, PointReferenceAnimation>? animations,
  double mouseX,
  double mouseY,
  bool? useFinalPosition,
  bool inRange,
  bool inXRange,
  bool inYRange,
  double centerX,
  double centerY,
});

/// One call of size. A null \`elementOptions\` is an element without
/// options. A null \`options\` is a call without an argument.
typedef PointSizeCase = ({
  String name,
  Map<String, Object?>? elementOptions,
  Map<String, Object?>? options,
  double size,
});

/// One call of getRange. A null \`options\` is an element without options.
typedef PointGetRangeCase = ({
  String name,
  Map<String, Object?>? options,
  double range,
});

/// One call of draw: the config of the element, the area (null for no
/// area) and the calls on the context.
typedef PointDrawCase = ({
  String name,
  Map<String, Object?> cfg,
  ({double left, double top, double right, double bottom})? area,
  List<(String, List<Object?>)> calls,
});

/// \`new PointElement(cfg)\` with \`$animations\`, then
/// \`inRange(mouseX, mouseY, useFinalPosition)\`,
/// \`inXRange(mouseX, useFinalPosition)\`,
/// \`inYRange(mouseY, useFinalPosition)\` and
/// \`getCenterPoint(useFinalPosition)\`. A null \`useFinalPosition\` is
/// \`undefined\`.
const List<PointInRangeCase> pointInRangeReference = [
${inRangeBody}];

/// \`new PointElement({options: elementOptions}).size(options)\`.
const List<PointSizeCase> pointSizeReference = [
${sizeBody}];

/// \`new PointElement({options}).getRange()\`.
const List<PointGetRangeCase> pointGetRangeReference = [
${getRangeBody}];

/// \`new PointElement(cfg).draw(ctx, area)\` and the calls that upstream
/// makes on the mock context of chartjs-test-utils, with the parameter
/// lists of MockContext (harness-mock-optional-args). A setter records the
/// value that the port gives it: \`null\` for an \`undefined\` option, and
/// the \`ToNumber\` of a \`lineWidth\`.
const List<PointDrawCase> pointDrawReference = [
${drawBody}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${total} cases to ${OUT}`);
