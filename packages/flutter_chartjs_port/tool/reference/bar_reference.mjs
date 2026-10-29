// Original code, not ported from Chart.js: BarElement reference generator.
//
// It writes test/port/elements/bar_reference.dart, the data of
// test/port/elements/element.bar_test.dart: the inRange, inXRange, inYRange,
// getCenterPoint, tooltipPosition and getRange results of a set of bars, the
// calls that draw makes on the mock context for a set of bars, and the
// Node.js version, V8 version and architecture in the header. The cases are
// fixed, so a rerun on the same Node.js writes the same file. Nothing in lib/
// or test/ runs this script (porting-flow.md section 4).
//
// The script runs the pinned upstream source
// third_party/Chart.js/src/elements/element.bar.js with the type stripping of
// Node.js. A resolve hook maps the upstream `./x.js` imports to the `.ts`
// files, and `@kurkle/color` to third_party/kurkle-color/src/index.esm.js
// (helpers/index.js imports helpers.color.ts). The draw calls go to the mock
// context third_party/chartjs-test-utils/src/context.js, which the Dart
// MockContext ports. Check out the submodules first
// (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs_port, with the darwin-arm64 build of
// Node.js v24.22.1 (Chart.js ADR 0045) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/bar_reference.mjs
//
// The reference is V8 13.6 on arm64 (Chart.js ADR 0045). The script does not
// stop on another architecture.

import {execFileSync} from 'node:child_process';
import {existsSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const SOURCE = new URL('Chart.js/src/elements/element.bar.js', THIRD_PARTY);
const CONTEXT = new URL('chartjs-test-utils/src/context.js', THIRD_PARTY);
const KURKLE = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL('../../test/port/elements/bar_reference.dart', import.meta.url),
);

for (const url of [SOURCE, CONTEXT, KURKLE]) {
  if (!existsSync(fileURLToPath(url))) {
    console.error(
      `${fileURLToPath(url)} is missing. ` +
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

const {default: BarElement} = await import(SOURCE.href);
const {default: Context} = await import(CONTEXT.href);

// An absent argument. The Dart MockContext records every declared parameter
// (harness-mock-optional-args): an absent nullable argument is Dart `null`,
// an absent `counterclockwise` of `arc` is `false`.
const ABSENT = Symbol('absent');
const PAD = {
  arc: [6, false],
  fill: [2, ABSENT],
  clip: [2, ABSENT],
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
 * The calls of [ctx] with the parameter lists of the Dart MockContext, and
 * the setter values of setterValue.
 */
function calls(ctx) {
  return ctx.getCalls().map(({name, args}) => {
    const padded = [...args];
    const pad = PAD[name];
    if (pad) while (padded.length < pad[0]) padded.push(pad[1]);
    if (SETTERS.has(name)) padded[0] = setterValue(name, padded[0]);
    return [name, padded];
  });
}

/** The Dart literal of a number. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return String(v);
}

/**
 * The Dart literal of a coordinate of a returned point `{x, y}`. A copied
 * `undefined` is NaN, as the Point rules of lib/src/types/geometric.dart
 * state.
 */
function coord(v) {
  return v === undefined ? 'double.nan' : num(v);
}

/** Whether the data has an `undefined` literal, which needs its import. */
let usesUndefined = false;

/** The Dart literal of a recorded value or of a cfg value. */
function dart(v) {
  if (v === ABSENT || v === null) return 'null';
  if (v === undefined) {
    usesUndefined = true;
    return 'undefined';
  }
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string' && /^[\w ]*$/.test(v)) return `'${v}'`;
  if (typeof v === 'object' && Object.getPrototypeOf(v) === Object.prototype) {
    const entries = Object.keys(v).map((k) => `${dart(k)}: ${dart(v[k])}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${String(v)}`);
}

/** The Dart literal of the animation list of a case. */
function dartAnimations(animations) {
  return `[${animations
    .map(([prop, active, to]) => `('${prop}', ${active}, ${num(to)})`)
    .join(', ')}]`;
}

/**
 * A new bar from [cfg], with an animation `{active, _to}` for each entry
 * `[prop, active, to]` of [animations].
 */
function bar(cfg, animations) {
  const b = new BarElement(cfg);
  if (animations.length) {
    b.$animations = Object.fromEntries(
      animations.map(([prop, active, to]) => [prop, {active: () => active, _to: to}]),
    );
  }
  return b;
}

// Range cases.

/**
 * The edges of the bar that [props] give, for the choice of the mouse
 * coordinates only: the expected results come from the upstream methods.
 */
function edges({x, y, base, width, height, horizontal}) {
  if (horizontal) {
    return [Math.min(x, base), Math.max(x, base), y - height / 2, y + height / 2];
  }
  return [x - width / 2, x + width / 2, Math.min(y, base), Math.max(y, base)];
}

/**
 * The coordinates around [lo] and [hi]: outside the epsilon of `_isBetween`
 * (1e-6), on it, on the edge, and the middle.
 */
function around(lo, hi) {
  if (Number.isNaN(lo) || Number.isNaN(hi)) return [0, 10];
  return [lo - 2e-6, lo - 1e-6, lo, (lo + hi) / 2, hi, hi + 1e-6, hi + 2e-6];
}

const rangeCases = [];
function addRange(name, cfg, animations = [], useFinalPosition = undefined) {
  const b = bar(cfg, animations);
  const props = {...cfg};
  if (useFinalPosition) {
    for (const [prop, active, to] of animations) if (active) props[prop] = to;
  }
  const [left, right, top, bottom] = edges(props);
  const points = [];
  for (const mx of around(left, right)) {
    for (const my of around(top, bottom)) {
      points.push({
        x: mx,
        y: my,
        inRange: b.inRange(mx, my, useFinalPosition),
        inXRange: b.inXRange(mx, useFinalPosition),
        inYRange: b.inYRange(my, useFinalPosition),
      });
    }
  }
  const center = b.getCenterPoint(useFinalPosition);
  const tooltip = b.tooltipPosition(useFinalPosition);
  rangeCases.push({
    name,
    cfg,
    animations,
    useFinalPosition,
    points,
    center,
    tooltip,
    rangeX: b.getRange('x'),
    rangeY: b.getRange('y'),
  });
}

addRange('vertical bar of the spec', {base: 0, width: 4, x: 10, y: 15});
addRange('vertical negative bar of the spec', {base: 0, width: 4, x: 10, y: -15});
addRange('vertical bar, base below the value', {
  horizontal: false, x: 50, y: 20, base: 100, width: 30, height: 80,
});
addRange('vertical bar, base above the value', {
  horizontal: false, x: 50, y: 140, base: 100, width: 30, height: 40,
});
addRange('horizontal bar, base left of the value', {
  horizontal: true, x: 120, y: 40, base: 10, width: 110, height: 24,
});
addRange('horizontal bar, base right of the value', {
  horizontal: true, x: -12.5, y: 10.25, base: 0, width: 12.5, height: 8,
});
addRange('fractional vertical bar', {
  horizontal: false, x: 10.1, y: 0.3, base: 0.7, width: 0.2, height: 0.4,
});
addRange('zero size bar', {horizontal: false, x: 10, y: 0, base: 0, width: 0, height: 0});
addRange('undefined state', {});
const ANIMS = [['x', true, 80], ['y', false, 999], ['base', true, 60]];
addRange('vertical bar with animations, current position', {
  horizontal: false, x: 50, y: 20, base: 100, width: 30, height: 80,
}, ANIMS);
addRange('vertical bar with animations, final position', {
  horizontal: false, x: 50, y: 20, base: 100, width: 30, height: 80,
}, ANIMS, true);
addRange('horizontal bar with animations, final position', {
  horizontal: true, x: 120, y: 40, base: 10, width: 110, height: 24,
}, [['x', true, 30], ['height', true, 10]], true);

// Draw cases.

const V = {horizontal: false, x: 50, y: 20, base: 100, width: 30, height: 80};
const VN = {horizontal: false, x: 50, y: 140, base: 100, width: 30, height: 40};
const H = {horizontal: true, x: 120, y: 40, base: 10, width: 110, height: 24};
const COLORS = {borderColor: 'red', backgroundColor: 'blue'};

const drawCases = [];
function addDraw(name, cfg, animations = []) {
  const b = bar(cfg, animations);
  const ctx = new Context();
  let error = null;
  try {
    b.draw(ctx);
  } catch (e) {
    error = e.constructor.name;
  }
  drawCases.push({name, cfg, animations, error, calls: calls(ctx)});
}

/** A cfg of [props] with the options [options] and the other [rest]. */
function draw(props, options, rest) {
  return {...props, options: {...COLORS, ...options}, ...rest};
}

addDraw('no border', draw(V, {borderWidth: 0, borderRadius: 0}, {
  borderSkipped: {bottom: true}, inflateAmount: 0,
}));
addDraw('border 2, bottom skipped', draw(V, {borderWidth: 2, borderRadius: 0}, {
  borderSkipped: {bottom: true}, inflateAmount: 0,
}));
addDraw('border 2, no edge skipped', draw(V, {borderWidth: 2, borderRadius: 0}, {
  borderSkipped: {}, inflateAmount: 0,
}));
addDraw('border 2, all edges skipped', draw(V, {borderWidth: 2, borderRadius: 0}, {
  borderSkipped: {top: true, right: true, bottom: true, left: true},
  inflateAmount: 0,
}));
addDraw('border object, inflateAmount 0.33', draw(V, {
  borderWidth: {top: 1, right: 2, bottom: 3, left: 4}, borderRadius: 0,
}, {borderSkipped: {}, inflateAmount: 0.33}));
addDraw('border shorthand x and y', draw(V, {
  borderWidth: {x: 1, y: 5}, borderRadius: 0,
}, {borderSkipped: {}, inflateAmount: 0}));
addDraw('border above half the size', draw(V, {borderWidth: 20, borderRadius: 0}, {
  borderSkipped: {}, inflateAmount: 0,
}));
addDraw('border below 0', draw(V, {borderWidth: -3, borderRadius: 0}, {
  borderSkipped: {}, inflateAmount: 0,
}));
addDraw('radius number, enableBorderRadius true', draw(V, {
  borderWidth: 2, borderRadius: 6,
}, {borderSkipped: {bottom: true}, enableBorderRadius: true, inflateAmount: 0}));
addDraw('radius number, enableBorderRadius false', draw(V, {
  borderWidth: 2, borderRadius: 6,
}, {borderSkipped: {bottom: true}, enableBorderRadius: false, inflateAmount: 0}));
addDraw('radius number, enableBorderRadius undefined', draw(V, {
  borderWidth: 2, borderRadius: 6,
}, {borderSkipped: {bottom: true}, inflateAmount: 0}));
addDraw('radius object, enableBorderRadius false', draw(V, {
  borderWidth: 2, borderRadius: {topLeft: 3, bottomRight: 6},
}, {borderSkipped: {}, enableBorderRadius: false, inflateAmount: 0}));
addDraw('radius object, bottom skipped', draw(V, {
  borderWidth: 0,
  borderRadius: {topLeft: 4, topRight: 4, bottomLeft: 4, bottomRight: 4},
}, {borderSkipped: {bottom: true}, enableBorderRadius: false, inflateAmount: 0}));
addDraw('radius above the limit', draw(V, {borderWidth: 2, borderRadius: 50}, {
  borderSkipped: {}, enableBorderRadius: true, inflateAmount: 0,
}));
addDraw('radius below 0', draw(V, {borderWidth: 2, borderRadius: -4}, {
  borderSkipped: {}, enableBorderRadius: true, inflateAmount: 0,
}));
addDraw('radius, top skipped', draw(V, {borderWidth: 0, borderRadius: 8}, {
  borderSkipped: {top: true}, enableBorderRadius: true, inflateAmount: 0,
}));
addDraw('radius below the border', draw(V, {borderWidth: 5, borderRadius: 2}, {
  borderSkipped: {}, enableBorderRadius: true, inflateAmount: 0,
}));
addDraw('horizontal bar, left skipped, radius', draw(H, {
  borderWidth: 3, borderRadius: 8,
}, {borderSkipped: {left: true}, enableBorderRadius: true, inflateAmount: 0.33}));
addDraw('horizontal bar, border object', draw(H, {
  borderWidth: {top: 1, right: 2, bottom: 3, left: 4}, borderRadius: 0,
}, {borderSkipped: {left: true}, inflateAmount: 0}));
addDraw('vertical bar, base above the value', draw(VN, {
  borderWidth: 2, borderRadius: 5,
}, {borderSkipped: {top: true}, enableBorderRadius: true, inflateAmount: 0}));
addDraw('inflateAmount 1', draw(V, {borderWidth: 2, borderRadius: 0}, {
  borderSkipped: {bottom: true}, inflateAmount: 1,
}));
addDraw('inflateAmount -1', draw(V, {borderWidth: 2, borderRadius: 0}, {
  borderSkipped: {bottom: true}, inflateAmount: -1,
}));
addDraw('inflateAmount undefined', draw(V, {borderWidth: 2, borderRadius: 0}, {
  borderSkipped: {bottom: true},
}));
addDraw('inflateAmount 0.33, no border', draw(V, {borderWidth: 0, borderRadius: 0}, {
  borderSkipped: {bottom: true}, inflateAmount: 0.33,
}));
addDraw('unknown edge skipped', draw(V, {borderWidth: 2, borderRadius: 0}, {
  borderSkipped: {middle: true}, inflateAmount: 0,
}));
addDraw('no colors', {
  ...V, options: {borderWidth: 1, borderRadius: 0}, borderSkipped: {},
  inflateAmount: 0,
});
addDraw('zero size bar', draw(
  {horizontal: false, x: 10, y: 0, base: 0, width: 0, height: 0},
  {borderWidth: 2, borderRadius: 3},
  {borderSkipped: {}, enableBorderRadius: true, inflateAmount: 0},
));
addDraw('undefined state', {
  options: {...COLORS, borderWidth: 2, borderRadius: 0}, borderSkipped: {},
});
addDraw('animations, draw uses the current values', draw(V, {
  borderWidth: 2, borderRadius: 0,
}, {borderSkipped: {bottom: true}, inflateAmount: 0}), ANIMS);
addDraw('no options', {...V, borderSkipped: {}, inflateAmount: 0});
addDraw('no borderSkipped', draw(V, {borderWidth: 2, borderRadius: 0}, {
  inflateAmount: 0,
}));

const rangeBody = rangeCases
  .map(
    (c) => `  (
    name: '${c.name}',
    cfg: ${dart(c.cfg)},
    animations: ${dartAnimations(c.animations)},
    useFinalPosition: ${dart(c.useFinalPosition ?? null)},
    points: [
${c.points
  .map(
    (p) =>
      `      (${num(p.x)}, ${num(p.y)}, ${p.inRange}, ${p.inXRange}, ` +
      `${p.inYRange}),\n`,
  )
  .join('')}    ],
    center: (${coord(c.center.x)}, ${coord(c.center.y)}),
    tooltip: (${coord(c.tooltip.x)}, ${coord(c.tooltip.y)}),
    rangeX: ${num(c.rangeX)},
    rangeY: ${num(c.rangeY)},
  ),
`,
  )
  .join('');

const drawBody = drawCases
  .map(
    (c) => `  (
    name: '${c.name}',
    cfg: ${dart(c.cfg)},
    animations: ${dartAnimations(c.animations)},
    error: ${c.error === null ? 'null' : `'${c.error}'`},
    calls: [
${c.calls
  .map(([name, args]) => `      ('${name}', [${args.map(dart).join(', ')}]),\n`)
  .join('')}    ],
  ),
`,
  )
  .join('');

const out = `// Original code, not ported from Chart.js: BarElement reference data.

// Generated by tool/reference/bar_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/elements/element.bar.js at the pinned Chart.js. ${rangeCases.length} range
// cases, ${drawCases.length} draw cases.
${usesUndefined ? "\nimport 'package:flutter_chartjs_port/src/js/js_undefined.dart';\n" : ''}
/// The Node.js version that generated the data.
const String barReferenceNode = '${process.version}';

/// The V8 version that generated the data.
const String barReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated the data.
const String barReferenceArch = '${process.arch}';

/// An animation \`{active: () => active, _to: to}\` of the property \`prop\`
/// in \`$animations\`.
typedef BarReferenceAnimation = (String prop, bool active, double to);

/// One mouse position and the results of \`inRange(x, y)\`, \`inXRange(x)\`
/// and \`inYRange(y)\`.
typedef BarReferencePoint = (
  double x,
  double y,
  bool inRange,
  bool inXRange,
  bool inYRange,
);

/// A bar \`new BarElement(cfg)\` with its animations, the
/// \`useFinalPosition\` argument (null for an absent argument), the results
/// of the range methods, \`getCenterPoint\` and \`tooltipPosition\` as
/// \`(x, y)\`, and \`getRange('x')\` and \`getRange('y')\`. A copied
/// \`undefined\` in a point is NaN, as the \`Point\` rules of
/// \`lib/src/types/geometric.dart\` state.
typedef BarReferenceRangeCase = ({
  String name,
  Map<String, Object?> cfg,
  List<BarReferenceAnimation> animations,
  bool? useFinalPosition,
  List<BarReferencePoint> points,
  (double, double) center,
  (double, double) tooltip,
  double rangeX,
  double rangeY,
});

/// A bar \`new BarElement(cfg)\` with its animations, the name of the error
/// class that \`draw\` throws (or null), and the calls of \`draw\` on the mock
/// context with the parameter lists of MockContext
/// (harness-mock-optional-args).
typedef BarReferenceDrawCase = ({
  String name,
  Map<String, Object?> cfg,
  List<BarReferenceAnimation> animations,
  String? error,
  List<(String, List<Object?>)> calls,
});

/// The range cases.
const List<BarReferenceRangeCase> barRangeReference = [
${rangeBody}];

/// The draw cases.
const List<BarReferenceDrawCase> barDrawReference = [
${drawBody}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(
  `Wrote ${rangeCases.length} range cases and ${drawCases.length} draw cases to ${OUT}`,
);
