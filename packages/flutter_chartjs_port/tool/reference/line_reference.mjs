// Original code, not ported from Chart.js: LineElement reference generator.
//
// It writes test/port/elements/line_reference.dart, the data of
// test/port/elements/element.line_test.dart. Each case makes a LineElement
// from point elements, options and properties, and runs a list of steps on
// it: draw, updateControlPoints, the points setter, path, pathSegment,
// interpolate, segments, first and last. For each step the file records the
// calls on the mock context of chartjs-test-utils (with the commands of each
// Path2D that a stroke gets), the result, the identity of the cached `_path`
// and `_pointsUpdated`. The header records the Node.js version, the V8
// version and the architecture. The cases are fixed, so a rerun on the same
// Node.js writes the same file. Nothing in lib/ or test/ runs this script
// (porting-flow.md section 4).
//
// The script runs the pinned upstream sources
// third_party/Chart.js/src/elements/element.line.js and element.point.ts with
// the type stripping of Node.js. A resolve hook maps the upstream `./x.js`
// imports to the `.ts` files, and `@kurkle/color` to the pinned
// third_party/kurkle-color/src/index.esm.js. The draw calls go to the pinned
// mock context third_party/chartjs-test-utils/src/context.js, which the Dart
// MockContext ports. element.line.js:233 tests `typeof Path2D` when the
// module loads. Node.js has no Path2D. Thus the script defines a Path2D that
// records its commands before it loads the module, as a browser has one
// (Chart.js ADR 0017, section 11). Check out the submodules first
// (`dart run melos run upstream`).
//
// Usage, from packages/flutter_chartjs_port, with an x64 build of Node.js v24.12.0
// (on Apple silicon, the darwin-x64 build runs under Rosetta) and with the
// Dart SDK on the PATH (the script formats the output with `dart format`):
//
//   node tool/reference/line_reference.mjs
//
// The reference is V8 13.6 on x64 (Chart.js ADR 0032). The script does not
// stop on another architecture.

import {execFileSync} from 'node:child_process';
import {existsSync, writeFileSync} from 'node:fs';
import {registerHooks} from 'node:module';
import {fileURLToPath} from 'node:url';

const THIRD_PARTY = new URL('../../../../third_party/', import.meta.url);
const LINE = new URL('Chart.js/src/elements/element.line.js', THIRD_PARTY);
const POINT = new URL('Chart.js/src/elements/element.point.ts', THIRD_PARTY);
const CONTEXT = new URL('chartjs-test-utils/src/context.js', THIRD_PARTY);
const COLOR = new URL('kurkle-color/src/index.esm.js', THIRD_PARTY);
const OUT = fileURLToPath(
  new URL('../../test/port/elements/line_reference.dart', import.meta.url),
);

for (const file of [LINE, POINT, CONTEXT, COLOR]) {
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
    const parent = context.parentURL ?? '';
    if (parent.includes('/third_party/Chart.js/')) {
      // helpers.color.ts imports the npm package; the checkout has no
      // node_modules. The pinned source of @kurkle/color 0.3.2 exports Color.
      if (specifier === '@kurkle/color') {
        return {url: COLOR.href, format: 'module', shortCircuit: true};
      }
      // The upstream sources import `../core/core.element.js` and the other
      // modules with a `.js` suffix; some files on disk are `.ts`.
      if (specifier.endsWith('.js')) {
        const js = new URL(specifier, parent);
        const ts = new URL(specifier.replace(/\.js$/, '.ts'), parent);
        if (!existsSync(fileURLToPath(js)) && existsSync(fileURLToPath(ts))) {
          return nextResolve(ts.href, context);
        }
      }
    }
    // chartjs-test-utils has no "type" in its package.json. Its
    // src/context.js is an ES module.
    if (specifier === CONTEXT.href) {
      return {url: CONTEXT.href, format: 'module', shortCircuit: true};
    }
    return nextResolve(specifier, context);
  },
});

/** The Path2D of a browser, as a recorder of its path commands. */
class Path2D {
  constructor() {
    this.calls = [];
  }
}
for (const name of ['moveTo', 'lineTo', 'bezierCurveTo', 'closePath']) {
  Path2D.prototype[name] = function (...args) {
    this.calls.push([name, args]);
  };
}
globalThis.Path2D = Path2D;

const {default: LineElement} = await import(LINE.href);
const {default: PointElement} = await import(POINT.href);
const {default: Context} = await import(CONTEXT.href);

/** The chart of a line with segment styles: `line._chart.getContext()`. */
const CHART = {
  getContext() {
    return {chart: 'chart', type: 'chart'};
  },
};

/**
 * The option `segment`: `'empty'` is `{}`, which makes draw stroke each
 * segment without a Path2D. `'style'` has a `setContext` that gives a red
 * style with width 2 before data index 2 and a blue style with width 4 from
 * it.
 */
function segmentOption(kind) {
  if (kind === 'empty') return {};
  return {
    setContext(ctx) {
      const late = ctx.p0DataIndex >= 2;
      return {borderColor: late ? 'blue' : 'red', borderWidth: late ? 4 : 2};
    },
  };
}

/** The resolved options of a line: the defaults and two colors. */
const BASE = {
  ...LineElement.defaults,
  borderDash: [],
  backgroundColor: 'green',
  borderColor: 'black',
};

const opts = (extra = {}) => ({...BASE, ...extra});

// The points: [x, y, skip, stop].
const P_LINE = [[0, 10], [10, 20], [20, 15], [30, 25], [40, 5]];
const P_DENSE = [
  [0, 10], [0.4, 30], [0.8, 5], [0.9, 20], [5, 10], [5.5, 10], [9.2, 40],
  [9.7, 0], [9.9, 25], [20, 20],
];
const P_GAPS = [
  [0, 10], [10, 20, true], [20, 15], [30, 25], [40, 5, true], [50, 10],
];
const P_RADAR = [[100, 50], [150, 90], [130, 150], [70, 150], [50, 90]];
const P_RADAR_GAP = [
  [100, 50], [150, 90], [130, 150, true], [70, 150], [50, 90],
];
const P_STOP = [[0, 0], [10, 10, undefined, true], [20, 5], [30, 15]];
const P_VERTICAL = [[10, 0], [20, 10], [15, 20], [25, 30], [5, 40]];
const P_SKIPPED = [[0, 0, true], [10, 10, true]];

// The chart areas of updateControlPoints: [left, top, right, bottom].
const AREA = [0, 8, 40, 22];
const AREA_V = [0, 0, 22, 40];
const AREA_R = [0, 0, 200, 200];

const LOOP = {_loop: true, _fullLoop: true};
const STILL = {animated: false};

const cases = [
  // The Path2D cache (element.line.js:207-217, :308-313, :439-443).
  {
    name: 'caches the path while the points do not change',
    points: P_LINE, options: opts(), props: STILL,
    steps: [
      ['draw'], ['draw'], ['setPoints'], ['draw'],
      ['updateControlPoints', ...AREA], ['draw'],
    ],
  },
  {
    name: 'drops the path after each draw when animated',
    points: P_LINE, options: opts(), props: {},
    steps: [['draw'], ['draw']],
  },
  {
    name: 'keeps the path after updateControlPoints',
    points: P_LINE, options: opts({tension: 0.4}), props: STILL,
    steps: [
      ['updateControlPoints', ...AREA], ['draw'],
      ['updateControlPoints', ...AREA], ['draw'], ['setPoints'],
      ['updateControlPoints', ...AREA], ['draw'],
    ],
  },
  {
    name: 'updates the control points again after an animated draw',
    points: P_LINE, options: opts({tension: 0.4}), props: {},
    steps: [
      ['updateControlPoints', ...AREA], ['draw'],
      ['updateControlPoints', ...AREA], ['draw'],
    ],
  },
  {
    name: 'strokes each segment without a Path2D when options.segment is set',
    points: P_LINE, options: opts(), segment: 'empty', props: STILL,
    steps: [['draw'], ['draw', 1, 2], ['draw', 0, 0]],
  },
  {
    name: 'strokes the segment styles',
    points: P_LINE, options: opts(), segment: 'style',
    props: {_chart: 'chart', _datasetIndex: 0},
    steps: [['segments'], ['draw', 0, 5]],
  },
  {
    name: 'strokes the segment styles over a gap with spanGaps',
    points: P_GAPS, options: opts({spanGaps: true}), segment: 'style',
    props: {_chart: 'chart', _datasetIndex: 1},
    steps: [['segments'], ['draw', 0, 6]],
  },
  {
    name: 'strokes the loop segments without a Path2D',
    points: P_RADAR_GAP, options: opts(), segment: 'empty', props: LOOP,
    steps: [['segments'], ['draw', 0, 5]],
  },

  // The segment method (element.line.js:185-190).
  {
    name: 'takes the fast path for the default options',
    points: P_LINE, options: opts(), props: {},
    steps: [['draw'], ['pathSegment', 0]],
  },
  {
    name: 'groups the points of one truncated x on the fast path',
    points: P_DENSE, options: opts(), props: {},
    steps: [
      ['draw'], ['pathSegment', 0, {reverse: true}],
      ['pathSegment', 0, {move: false}],
      ['pathSegment', 0, {start: 2, end: 7}],
    ],
  },
  {
    name: 'takes pathSegment for a decimated line',
    points: P_DENSE, options: opts(), props: {_decimated: true},
    steps: [['draw']],
  },
  {
    name: 'takes pathSegment for a dashed line',
    points: P_LINE, options: opts({borderDash: [4, 2], borderDashOffset: 1}),
    props: {},
    steps: [['draw']],
  },
  {
    name: 'takes the fast path for an empty dash',
    points: P_LINE, options: opts({borderDash: []}), props: {},
    steps: [['draw']],
  },
  {
    name: 'takes pathSegment for a loop',
    points: P_RADAR, options: opts(), props: LOOP,
    steps: [
      ['segments'], ['first'], ['last'], ['draw'],
      ['pathSegment', 0, {reverse: true}], ['path'],
    ],
  },

  // Steps (helpers.canvas.ts:342 through element.line.js:28-38).
  ...[true, 'before', 'after', 'middle'].map((stepped) => ({
    name: `steps the line with stepped ${JSON.stringify(stepped)}`,
    points: P_LINE, options: opts({stepped}), props: {},
    steps: [
      ['draw'], ['pathSegment', 0, {reverse: true}],
      ['interpolate', 15, 'x'], ['interpolate', 25, 'x'],
      ['interpolate', 20, 'x'],
    ],
  })),
  {
    name: 'does not set control points for a stepped line',
    points: P_LINE, options: opts({stepped: true, tension: 0.4}), props: {},
    steps: [['updateControlPoints', ...AREA], ['draw']],
  },

  // Control points (element.line.js:299-306).
  {
    name: 'sets the control points of a tension',
    points: P_LINE, options: opts({tension: 0.4}), props: {},
    steps: [
      ['updateControlPoints', ...AREA, 'x'], ['draw'],
      ['interpolate', 15, 'x'], ['interpolate', 35, 'x'],
    ],
  },
  {
    name: 'sets the control points of a tension without capBezierPoints',
    points: P_LINE, options: opts({tension: 0.4, capBezierPoints: false}),
    props: {},
    steps: [['updateControlPoints', ...AREA], ['draw']],
  },
  {
    name: 'sets the monotone control points',
    points: P_LINE, options: opts({cubicInterpolationMode: 'monotone'}),
    props: {},
    steps: [
      ['updateControlPoints', ...AREA], ['draw'], ['interpolate', 15, 'x'],
    ],
  },
  {
    name: "sets the monotone control points on the index axis 'y'",
    points: P_VERTICAL, options: opts({cubicInterpolationMode: 'monotone'}),
    props: {},
    steps: [
      ['updateControlPoints', ...AREA_V, 'y'], ['draw'],
      ['interpolate', 25, 'y'],
    ],
  },
  {
    name: 'sets the monotone control points over gaps with spanGaps',
    points: P_GAPS,
    options: opts({cubicInterpolationMode: 'monotone', spanGaps: true}),
    props: {},
    steps: [['updateControlPoints', ...AREA], ['segments'], ['draw']],
  },
  {
    name: 'reads _loop for the control points with spanGaps',
    points: P_RADAR_GAP, options: opts({tension: 0.3, spanGaps: true}),
    props: {_loop: true, _fullLoop: false},
    steps: [['updateControlPoints', ...AREA_R], ['segments'], ['draw']],
  },
  {
    name: 'reads _fullLoop for the control points without spanGaps',
    points: P_RADAR, options: opts({tension: 0.3}), props: LOOP,
    steps: [['updateControlPoints', ...AREA_R], ['draw']],
  },
  {
    name: 'reads _fullLoop false for the control points without spanGaps',
    points: P_RADAR, options: opts({tension: 0.3}),
    props: {_loop: true, _fullLoop: false},
    steps: [['updateControlPoints', ...AREA_R], ['draw']],
  },

  // interpolate (element.line.js:351-378).
  {
    name: 'interpolates a linear line',
    points: P_LINE, options: opts(), props: {},
    steps: [
      ['interpolate', 15, 'x'], ['interpolate', 10, 'x'],
      ['interpolate', 100, 'x'], ['interpolate', 17, 'y'],
      ['interpolate', 0, 'x'], ['interpolate', -5, 'x'],
    ],
  },
  {
    name: 'interpolates a line with gaps',
    points: P_GAPS, options: opts(), props: {},
    steps: [
      ['interpolate', 5, 'x'], ['interpolate', 25, 'x'],
      ['interpolate', 45, 'x'],
    ],
  },

  // segments, first and last (element.line.js:319-342).
  {
    name: 'splits the segments at the gaps',
    points: P_GAPS, options: opts(), props: {},
    steps: [['segments'], ['first'], ['last'], ['draw'], ['path', 2, 2]],
  },
  {
    name: 'spans the gaps with spanGaps',
    points: P_GAPS, options: opts({spanGaps: true}), props: {},
    steps: [['segments'], ['first'], ['last'], ['draw']],
  },
  {
    name: 'has no segments when every point is skipped',
    points: P_SKIPPED, options: opts(), props: {},
    steps: [['segments'], ['first'], ['last'], ['draw']],
  },
  {
    name: 'ends a segment at a stop point',
    points: P_STOP, options: opts(), props: {},
    steps: [['segments'], ['first'], ['last'], ['draw']],
  },
  {
    name: 'opens a loop at a gap',
    points: P_RADAR_GAP, options: opts(), props: LOOP,
    steps: [['segments'], ['first'], ['last'], ['draw']],
  },
  {
    name: 'spans the gap of a loop with spanGaps',
    points: P_RADAR_GAP, options: opts({spanGaps: true}), props: LOOP,
    steps: [['segments'], ['first'], ['last'], ['draw']],
  },

  // The draw arguments and the guards of element.line.js:427-444.
  {
    name: 'draws a range of the points',
    points: P_LINE, options: opts(), props: {},
    steps: [['draw', 1, 3], ['path', 1, 2], ['path'], ['path', 0, 0]],
  },
  {
    name: 'does not stroke without a border width',
    points: P_LINE, options: opts({borderWidth: 0}), props: {},
    steps: [['draw'], ['path']],
  },
  {
    name: 'does not stroke without options',
    points: P_LINE, options: null, props: {},
    steps: [['draw']],
  },
  {
    name: 'does not stroke without points',
    points: [], options: opts(), props: {},
    steps: [['draw'], ['segments'], ['first'], ['last']],
  },

  // pathSegment (element.line.js:394-397) with params.
  {
    name: 'appends a segment with params',
    points: P_LINE, options: opts({tension: 0.4}), props: {},
    steps: [
      ['updateControlPoints', ...AREA],
      ['pathSegment', 0], ['pathSegment', 0, {move: false}],
      ['pathSegment', 0, {start: 1, end: 3}],
      ['pathSegment', 0, {start: 3, end: 1}],
      ['pathSegment', 0, {reverse: true}],
      ['pathSegment', 0, {start: 6, end: 8}],
    ],
  },
];

/** The Dart literal of a number. */
function num(v) {
  if (Number.isNaN(v)) return 'double.nan';
  if (v === Infinity) return 'double.infinity';
  if (v === -Infinity) return 'double.negativeInfinity';
  if (Object.is(v, -0)) return '-0.0';
  return String(v);
}

/** The Dart literal of a string. */
function str(s) {
  const body = s.replace(/\\/g, '\\\\').replace(/\$/g, '\\$');
  if (body.includes("'") && !body.includes('"')) return `"${body}"`;
  return `'${body.replace(/'/g, "\\'")}'`;
}

/** The Dart literal of a plain value: an option, a call argument. */
function dart(v) {
  if (v === null || v === undefined) return 'null';
  if (typeof v === 'number') return num(v);
  if (typeof v === 'boolean') return String(v);
  if (typeof v === 'string') return str(v);
  if (Array.isArray(v)) return `<Object?>[${v.map(dart).join(', ')}]`;
  if (typeof v === 'object' && v.path !== undefined) {
    return `(id: ${v.path}, calls: ${dartCalls(v.calls)})`;
  }
  if (typeof v === 'object') {
    const entries = Object.entries(v).map(([k, x]) => `'${k}': ${dart(x)}`);
    return `<String, Object?>{${entries.join(', ')}}`;
  }
  throw new Error(`No Dart literal for ${v}`);
}

/** The Dart literal of a list of [name, args] calls. */
function dartCalls(calls) {
  const items = calls.map(
    ([name, args]) => `(${str(name)}, <Object?>[${args.map(dart).join(', ')}])`,
  );
  return `<LineReferenceCall>[${items.join(', ')}]`;
}

/** The Dart literal of an encoded interpolate result. */
function dartPoint(p) {
  return p.index !== undefined
    ? `(index: ${p.index}, x: null, y: null)`
    : `(index: null, x: ${dart(p.x)}, y: ${dart(p.y)})`;
}

/** The Dart literal of the result of a step. */
function dartResult(action, result) {
  if (result === null || result === undefined) return 'null';
  switch (action) {
    case 'updateControlPoints':
      return `<List<double>>[${result
        // A control point that was never set is undefined: NaN, as the
        // SplinePoint members state (adapt-spline-control-point-nan).
        .map((cps) => `<double>[${cps.map((v) => num(v ?? NaN)).join(', ')}]`)
        .join(', ')}]`;
    case 'segments':
      return `<LineReferenceSegment>[${result
        .map(([s, e, l, st]) => `(${num(s)}, ${num(e)}, ${l}, ${st})`)
        .join(', ')}]`;
    case 'interpolate':
      return Array.isArray(result)
        ? `<LineReferencePoint>[${result.map(dartPoint).join(', ')}]`
        : dartPoint(result);
    default:
      return dart(result);
  }
}

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

/** Runs one case. Returns its steps with their records. */
function run(c) {
  const ids = new Map();
  const pathId = (path) => {
    if (path === undefined) return null;
    if (!ids.has(path)) ids.set(path, ids.size + 1);
    return ids.get(path);
  };
  /** The value of a recorded argument, with a Path2D as its commands. */
  const value = (arg) =>
    arg instanceof Path2D
      ? {path: pathId(arg), calls: arg.calls.map(([n, a]) => [n, [...a]])}
      : arg;
  /** The calls of a mock context, with the parameter lists of MockContext. */
  const record = (ctx) =>
    ctx.getCalls().map(({name, args}) => {
      const list = [...args];
      // harness-mock-optional-args: the mock records every declared
      // parameter. `stroke` declares one.
      if (name === 'stroke' && list.length === 0) list.push(undefined);
      if (SETTERS.has(name)) list[0] = setterValue(name, list[0]);
      return [name, list.map(value)];
    });

  const points = c.points.map(
    ([x, y, skip, stop]) => new PointElement({x, y, skip, stop}),
  );
  const cfg = {points};
  if (c.options) {
    cfg.options = c.segment
      ? {...c.options, segment: segmentOption(c.segment)}
      : c.options;
  }
  for (const [key, v] of Object.entries(c.props)) {
    cfg[key] = v === 'chart' ? CHART : v;
  }
  const line = new LineElement(cfg);

  const encode = (p) => {
    const index = points.indexOf(p);
    return index >= 0 ? {index} : {x: p.x, y: p.y};
  };

  const steps = [];
  for (const [action, ...args] of c.steps) {
    const ctx = new Context();
    let result = null;
    let calls = [];
    switch (action) {
      case 'draw':
        line.draw(ctx, undefined, ...args);
        calls = record(ctx);
        break;
      case 'updateControlPoints': {
        const [left, top, right, bottom, indexAxis] = args;
        const area = {
          left, top, right, bottom, width: right - left, height: bottom - top,
        };
        line.updateControlPoints(area, indexAxis);
        result = points.map((p) => [p.cp1x, p.cp1y, p.cp2x, p.cp2y]);
        break;
      }
      case 'setPoints':
        line.points = line.points;
        break;
      case 'path':
        result = line.path(ctx, ...args);
        calls = record(ctx);
        break;
      case 'pathSegment': {
        const [index, params] = args;
        result = line.pathSegment(ctx, line.segments[index], params);
        calls = record(ctx);
        break;
      }
      case 'interpolate': {
        const [v, property] = args;
        const point = new PointElement(property === 'x' ? {x: v, y: 0} : {x: 0, y: v});
        const r = line.interpolate(point, property);
        result = r === undefined ? null : Array.isArray(r) ? r.map(encode) : encode(r);
        break;
      }
      case 'segments':
        result = line.segments.map((s) => [
          s.start, s.end, s.loop, s.style !== undefined,
        ]);
        break;
      case 'first':
      case 'last': {
        const p = line[action]();
        result = p ? points.indexOf(p) : null;
        break;
      }
      default:
        throw new Error(`Unknown step ${action}`);
    }
    steps.push({
      action, args, calls, result,
      path: pathId(line._path),
      pointsUpdated: line._pointsUpdated,
    });
  }
  return steps;
}

const body = cases
  .map((c) => {
    const steps = run(c);
    const points = c.points
      .map(([x, y, skip, stop]) => `(${num(x)}, ${num(y)}, ${dart(skip)}, ${dart(stop)})`)
      .join(', ');
    const stepLiterals = steps
      .map(
        (s) => `      (
        action: ${str(s.action)},
        args: ${dart(s.args)},
        calls: ${dartCalls(s.calls)},
        result: ${dartResult(s.action, s.result)},
        path: ${s.path ?? 'null'},
        pointsUpdated: ${s.pointsUpdated},
      ),
`,
      )
      .join('');
    return `  (
    name: ${str(c.name)},
    points: <LineReferencePointInput>[${points}],
    options: ${c.options ? dart(c.options) : 'null'},
    segment: ${c.segment ? str(c.segment) : 'null'},
    props: ${dart(c.props)},
    steps: <LineReferenceStep>[
${stepLiterals}    ],
  ),
`;
  })
  .join('');

const out = `// Original code, not ported from Chart.js: LineElement reference data.

// Generated by tool/reference/line_reference.mjs. Do not edit.
// Node.js ${process.version} (${process.platform}-${process.arch}), V8 ${process.versions.v8}:
// src/elements/element.line.js at the pinned Chart.js, with the mock context
// of chartjs-test-utils. ${cases.length} cases.

/// The Node.js version that generated [lineReference].
const String lineReferenceNode = '${process.version}';

/// The V8 version that generated [lineReference].
const String lineReferenceV8 = '${process.versions.v8}';

/// The architecture of the Node.js build that generated [lineReference].
const String lineReferenceArch = '${process.arch}';

/// One recorded call on the mock context or a Path2D: the name and the
/// arguments, with the parameter lists of MockContext
/// (harness-mock-optional-args). JS \`undefined\` is \`null\`.
typedef LineReferenceCall = (String, List<Object?>);

/// A Path2D argument of a call: the id of the path in its case (1 for the
/// first path that the case meets) and the commands of the path.
typedef LineReferencePath = ({int id, List<LineReferenceCall> calls});

/// One point of a line: \`(x, y, skip, stop)\`. \`null\` is JS \`undefined\`.
typedef LineReferencePointInput = (double, double, bool?, bool?);

/// A point of an interpolate result: the index of a point of the line, or
/// the \`x\` and \`y\` of a new point.
typedef LineReferencePoint = ({int? index, double? x, double? y});

/// A segment: \`(start, end, loop, style !== undefined)\`.
typedef LineReferenceSegment = (double, double, bool, bool);

/// One step of a case.
///
/// - \`action\` and \`args\`: \`draw\` (start and count), \`updateControlPoints\`
///   (left, top, right, bottom and the index axis), \`setPoints\` (the write
///   \`line.points = line.points\`), \`path\` (start and count),
///   \`pathSegment\` (the segment index and the params object),
///   \`interpolate\` (the value and the property of a point element with 0
///   for the other coordinate), \`segments\`, \`first\` and \`last\`.
/// - \`calls\`: the calls on a new mock context.
/// - \`result\`: the control points \`[cp1x, cp1y, cp2x, cp2y]\` of each point
///   after \`updateControlPoints\` (NaN for \`undefined\`), the result of
///   \`path\` and \`pathSegment\` (\`null\` for \`undefined\`), a
///   [LineReferencePoint] or a list of them for \`interpolate\` (\`null\` for
///   \`undefined\`), the [LineReferenceSegment] list of \`segments\`, and the
///   point index of \`first\` and \`last\` (\`null\` for a falsy result).
/// - \`path\`: the id of \`line._path\` after the step, \`null\` for
///   \`undefined\`.
/// - \`pointsUpdated\`: \`line._pointsUpdated\` after the step.
typedef LineReferenceStep = ({
  String action,
  List<Object?> args,
  List<LineReferenceCall> calls,
  Object? result,
  int? path,
  bool pointsUpdated,
});

/// One case: the config of the line and its steps. \`options\` is \`null\`
/// for a line without options. \`segment\` is the option \`segment\`:
/// \`'empty'\` for \`{}\`, \`'style'\` for the \`setContext\` of the generator,
/// or \`null\`. The \`props\` value \`'chart'\` is the chart of the generator.
typedef LineReferenceCase = ({
  String name,
  List<LineReferencePointInput> points,
  Map<String, Object?>? options,
  String? segment,
  Map<String, Object?> props,
  List<LineReferenceStep> steps,
});

/// The cases of element.line.js in Node.js on x64.
const List<LineReferenceCase> lineReference = [
${body}];
`;

writeFileSync(OUT, out);
execFileSync('dart', ['format', OUT], {stdio: 'inherit'});
console.log(`Wrote ${cases.length} cases to ${OUT}`);
