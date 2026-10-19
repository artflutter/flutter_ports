// Original code, not ported from Chart.js: drawPointLegend call-sequence reference generator.
//
// It writes test/port/helpers/draw_point_reference.dart, the data of the
// drawPointLegend and drawPoint groups of
// test/port/helpers/helpers.canvas_test.dart: 50 drawPointLegend calls, each
// with the calls that it makes on a recording context, and the Node.js
// version, V8 version and architecture in the header. The cases are fixed, so
// a rerun on the same Node.js writes the same file. Nothing in lib/ or test/
// runs this script (porting-flow.md section 4).
//
// The script runs the pinned upstream source
// third_party/Chart.js/src/helpers/helpers.canvas.ts with the type stripping
// of Node.js. A resolve hook maps the upstream `./x.js` imports to the `.ts`
// files. Check out the submodule first (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/draw_point_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0010), and the script stops
// on any other architecture. The test compares each number with closeTo, but
// Chart.js ADR 0010 takes all reference data from one engine.

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
  '../../../../third_party/Chart.js/src/helpers/helpers.canvas.ts',
  import.meta.url,
);
const OUT = fileURLToPath(
  new URL('../../test/port/helpers/draw_point_reference.dart', import.meta.url),
);

if (!existsSync(fileURLToPath(SOURCE))) {
  console.error(
    `${fileURLToPath(SOURCE)} is missing. ` +
      'Check out the submodules with `dart run melos run upstream`.',
  );
  process.exit(1);
}

// The upstream sources import `./helpers.math.js` and the other modules with
// a `.js` suffix; the files on disk are `.ts`.
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
});

const {drawPointLegend} = await import(SOURCE.href);

// The declared parameter counts of the Dart MockContext methods with
// optional parameters, and the value of an absent argument
// (harness-mock-optional-args): the mock records every declared parameter.
const PAD = {
  arc: [6, false],
  ellipse: [8, false],
  fill: [2, undefined],
  stroke: [1, undefined],
  drawImage: [5, undefined],
};

const METHODS = [
  'save', 'restore', 'translate', 'rotate', 'drawImage', 'beginPath',
  'ellipse', 'arc', 'closePath', 'moveTo', 'lineTo', 'rect', 'fill', 'stroke',
];

/** A context that records each call as [name, args]. */
function recordingContext() {
  const calls = [];
  const ctx = {};
  for (const name of METHODS) {
    ctx[name] = (...args) => {
      const pad = PAD[name];
      if (pad) while (args.length < pad[0]) args.push(pad[1]);
      calls.push([name, args]);
    };
  }
  return {ctx, calls};
}

/**
 * The test image: an 8 x 6 image, `_image` in the test. drawPoint tests
 * `style.toString()` for an image (helpers.canvas.ts:181-182).
 */
const IMAGE = {
  width: 8,
  height: 6,
  toString() {
    return '[object HTMLImageElement]';
  },
};
/** An object literal point style, `_object` in the test. */
const OBJECT = {};

/** The Dart literal of a number. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return String(v);
}

/** The Dart literal of a recorded value or a point style. */
function dart(v) {
  if (v === IMAGE) return 'drawPointImage';
  if (v === OBJECT) return 'drawPointObject';
  if (v === null || v === undefined) return 'null';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string') return `'${v}'`;
  throw new Error(`No Dart literal for ${v}`);
}

const cases = [];
function add(pointStyle, rotation, radius, borderWidth, w) {
  const {ctx, calls} = recordingContext();
  drawPointLegend(ctx, {pointStyle, rotation, radius, borderWidth}, 50, 40, w);
  cases.push({pointStyle, rotation, radius, borderWidth, w, calls});
}

// Every point style, without and with a rotation, without and with w.
const STYLES = [
  'circle', 'triangle', 'rectRounded', 'rect', 'rectRot', 'cross',
  'crossRot', 'star', 'line', 'dash', false, undefined, 'unknown', OBJECT,
];
for (const style of STYLES) {
  for (const rotation of [undefined, 30]) {
    for (const w of [undefined, 20]) add(style, rotation, 10, 1, w);
  }
}

// An image, without and with a rotation.
for (const rotation of [undefined, 45]) add(IMAGE, rotation, 0, 1, undefined);

// A radius of NaN, 0 or below 0, and a borderWidth of 0, NaN or below 0.
for (const [radius, borderWidth] of [
  [NaN, 1], [0, 1], [-1, 1], [10, 0], [10, NaN], [10, -1],
]) {
  add('circle', undefined, radius, borderWidth, undefined);
}

const body = cases
  .map(
    (c) => `  (
    style: ${dart(c.pointStyle)},
    rotation: ${dart(c.rotation)},
    w: ${dart(c.w)},
    radius: ${num(c.radius)},
    borderWidth: ${num(c.borderWidth)},
    calls: [
${c.calls
  .map(([name, args]) => `      ('${name}', [${args.map(dart).join(', ')}]),\n`)
  .join('')}    ],
  ),
`,
  )
  .join('');

const out = `// Original code, not ported from Chart.js: drawPoint reference data.

// Generated by tool/reference/draw_point_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/helpers/helpers.canvas.ts at the pinned Chart.js. ${cases.length} cases.

/// The Node.js version that generated [drawPointReference].
const String drawPointReferenceNode = '${process.version}';

/// The V8 version that generated [drawPointReference].
const String drawPointReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated [drawPointReference].
const String drawPointReferenceArch = '${process.arch}';

/// Stands for the test image (8 x 6) in [drawPointReference], as a point
/// style and as a drawImage argument.
const Symbol drawPointImage = #image;

/// Stands for an object literal \`{}\` point style in [drawPointReference].
const Symbol drawPointObject = #object;

/// One drawPointLegend call: the options, \`w\` and the calls on the context.
typedef DrawPointReferenceCase = ({
  Object? style,
  double? rotation,
  double? w,
  double radius,
  double borderWidth,
  List<(String, List<Object?>)> calls,
});

/// The drawPointLegend calls with \`x\` 50 and \`y\` 40, and the calls that
/// upstream makes on a context with the parameter lists of MockContext
/// (harness-mock-optional-args).
const List<DrawPointReferenceCase> drawPointReference = [
${body}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${cases.length} cases to ${OUT}`);
