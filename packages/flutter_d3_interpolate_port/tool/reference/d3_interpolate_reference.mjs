// Original code, not ported from d3-interpolate: the reference data of the port.
//
// Writes test/port/d3_interpolate_reference.dart from upstream d3-interpolate
// v3.0.1 (third_party/d3-interpolate/src/, ESM) on the reference engine of
// the repository, Node.js v24.22.1 on arm64 (Chart.js ADR 0146).
//
// Run from packages/flutter_d3_interpolate_port:
//
//   node tool/reference/d3_interpolate_reference.mjs
//   dart format test/port/d3_interpolate_reference.dart
//
// The upstream source imports the bare specifier "d3-color". A module resolve
// hook (module.registerHooks of Node.js 24) maps it to
// third_party/d3-color/src/index.js, the source of the port of d3-color. The
// generator stops unless both submodules are at the commits of their
// tool/port_sources.yaml entries, with no change in src/.
//
// The input set is deterministic: fixed lists and a mulberry32 generator
// with a fixed seed. Each interpolator runs at the t values of `TS`.
//
// The color interpolators of upstream return `start + ""`, the text of
// formatRgb. The generator wraps the toString of the d3-color prototypes to
// read the channels of `start` at that call too, so the data has both the
// channels and the text of each result.
//
// The transform cases call interpolateTransformSvg with a fake global
// document: its element gives the matrix of a transform text through
// transform.baseVal.consolidate(), as a browser does. The data has the
// decomposed parts of both texts (upstream decompose of that matrix) and the
// six numbers of each result text; a part that the text omits is the
// identity value.

import {execFileSync} from "node:child_process";
import {
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import {registerHooks} from "node:module";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";

const NODE_VERSION = "v24.22.1";
const NODE_ARCH = "arm64";

if (process.version !== NODE_VERSION || process.arch !== NODE_ARCH) {
  console.error(
    `d3_interpolate_reference.mjs needs Node.js ${NODE_VERSION} on ` +
      `${NODE_ARCH}, not ${process.version} on ${process.arch} ` +
      "(Chart.js ADR 0146).",
  );
  process.exit(1);
}

const here = path.dirname(fileURLToPath(import.meta.url));
const packageRoot = path.resolve(here, "../..");
const repoRoot = path.resolve(packageRoot, "../..");
const interpolateRoot = path.join(repoRoot, "third_party/d3-interpolate");
const colorRoot = path.join(repoRoot, "third_party/d3-color");
const output = path.join(
  packageRoot,
  "test/port/d3_interpolate_reference.dart",
);

/// The commit of the entry [header] of the tool/port_sources.yaml files of
/// packages/. Each entry that names it must give the same commit. Stops
/// unless the submodule [root] is at that commit with no change in src/.
function checkPin(header, root) {
  const pins = new Set();
  for (const name of readdirSync(path.join(repoRoot, "packages"))) {
    const file = path.join(
      repoRoot,
      "packages",
      name,
      "tool/port_sources.yaml",
    );
    if (!existsSync(file)) continue;
    for (const entry of readFileSync(file, "utf8").split(/\n\s*- header: /)) {
      if (!entry.startsWith(`${header}\n`)) continue;
      const commit = /\n\s*commit: ([0-9a-f]{40})/.exec(entry)?.[1];
      if (commit) pins.add(commit);
    }
  }
  if (pins.size !== 1) {
    console.error(
      `The tool/port_sources.yaml files of packages/ give ${pins.size} ` +
        `commits for ${header}, not 1.`,
    );
    process.exit(1);
  }
  const [pinned] = pins;
  const head = execFileSync("git", ["-C", root, "rev-parse", "HEAD"], {
    encoding: "utf8",
  }).trim();
  const dirty = execFileSync(
    "git",
    ["-C", root, "status", "--porcelain", "--", "src"],
    {encoding: "utf8"},
  ).trim();
  if (head !== pinned || dirty !== "") {
    console.error(
      `${path.relative(repoRoot, root)} must be at ${pinned} with no change ` +
        `in src/ (HEAD ${head}${dirty ? ", src/ changed" : ""}).`,
    );
    process.exit(1);
  }
  return pinned;
}

const interpolatePin = checkPin("d3-interpolate", interpolateRoot);
const colorPin = checkPin("d3-color", colorRoot);

// The bare specifier "d3-color" of the upstream source is the d3-color
// submodule.
const colorUrl = pathToFileURL(path.join(colorRoot, "src/index.js")).href;
registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "d3-color") return {url: colorUrl, shortCircuit: true};
    return nextResolve(specifier, context);
  },
});

const d3 = await import(
  pathToFileURL(path.join(interpolateRoot, "src/index.js")).href
);
const d3color = await import(colorUrl);
const {default: decompose, identity} = await import(
  pathToFileURL(path.join(interpolateRoot, "src/transform/decompose.js")).href
);

// ---------------------------------------------------------------------------
// The channels of the color that a color interpolator formats.

/// The space name of a d3-color object.
function spaceOf(c) {
  if (c instanceof d3color.rgb) return "rgb";
  if (c instanceof d3color.hsl) return "hsl";
  if (c instanceof d3color.lab) return "lab";
  if (c instanceof d3color.hcl) return "hcl";
  if (c instanceof d3color.cubehelix) return "cubehelix";
  throw new Error(`no space for ${c}`);
}

/// The three channels and the opacity of a d3-color object in its space.
function channelsOf(c) {
  switch (spaceOf(c)) {
    case "rgb":
      return [c.r, c.g, c.b, c.opacity];
    case "hsl":
      return [c.h, c.s, c.l, c.opacity];
    case "lab":
      return [c.l, c.a, c.b, c.opacity];
    case "hcl":
      return [c.h, c.c, c.l, c.opacity];
    case "cubehelix":
      return [c.h, c.s, c.l, c.opacity];
  }
}

// `start + ""` calls toString: Color.prototype has it (color_formatRgb), and
// Rgb.prototype has its own (rgb_formatRgb). The wrappers record the object.
let formatted = [];
for (const proto of [d3color.color.prototype, d3color.rgb.prototype]) {
  const original = proto.toString;
  if (!Object.prototype.hasOwnProperty.call(proto, "toString")) {
    throw new Error("a d3-color prototype has no own toString");
  }
  proto.toString = function () {
    formatted.push({space: spaceOf(this), channels: channelsOf(this)});
    return original.call(this);
  };
}

/// Calls the color interpolator [i] at t and gives the formatted channels and
/// the text.
function colorResult(i, t) {
  formatted = [];
  const text = i(t);
  if (typeof text !== "string" || formatted.length !== 1) {
    throw new Error(`a color interpolator formatted ${formatted.length} colors`);
  }
  return {...formatted[0], text};
}

// ---------------------------------------------------------------------------
// Random inputs.

// mulberry32 with a fixed seed.
function mulberry32(seed) {
  let a = seed >>> 0;
  return function () {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
const random = mulberry32(0xd3171e01);
const uniform = (lo, hi) => lo + (hi - lo) * random();
const integer = (lo, hi) => Math.floor(uniform(lo, hi + 1));
const pick = (list) => list[Math.floor(random() * list.length)];

/// The t values of each interpolator.
const TS = [0, 0.1, 0.25, 1 / 3, 0.5, 0.75, 1, -0.5, 1.5];

/// A number: mostly in [lo, hi], sometimes a whole number, a half, -0 or
/// outside the range.
function value(lo, hi) {
  const u = random();
  if (u < 0.03) return -0;
  if (u < 0.15) return Math.round(uniform(lo, hi));
  if (u < 0.22) return Math.round(uniform(lo, hi)) + 0.5;
  if (u < 0.3) return uniform(lo - (hi - lo), hi + (hi - lo));
  return uniform(lo, hi);
}

const list = (n, f) => Array.from({length: n}, f);

// ---------------------------------------------------------------------------
// Dart literals.

/// The Dart name of -0 in the data. On the web, the constant evaluator makes
/// a whole double an int, so a constant -0.0 is +0: the data reads -0 at run
/// time, and a list that holds it is final, not const.
const NEGATIVE_ZERO = "negativeZero";

/// A double as a Dart literal: NaN, infinities and -0 by name, an integer
/// below 2^53 as an int literal (the context type is double), any other
/// number as JavaScript String(x), which round-trips.
function dartNumber(x) {
  if (Number.isNaN(x)) return "double.nan";
  if (x === Infinity) return "double.infinity";
  if (x === -Infinity) return "double.negativeInfinity";
  if (Object.is(x, -0)) return NEGATIVE_ZERO;
  const s = String(x);
  if (/[.e]/.test(s)) return s;
  if (Math.abs(x) <= 2 ** 53) return s;
  return x.toExponential();
}

/// A whole number as a Dart int literal.
function dartInt(x) {
  if (!Number.isSafeInteger(x)) throw new Error(`not an int: ${x}`);
  return String(Object.is(x, -0) ? 0 : x);
}

/// A string as a Dart literal in single quotes.
function dartString(s) {
  let out = "'";
  for (const ch of s) {
    const c = ch.codePointAt(0);
    if (ch === "\\") out += "\\\\";
    else if (ch === "'") out += "\\'";
    else if (ch === "$") out += "\\$";
    else if (c < 0x20 || c > 0x7e) out += `\\u{${c.toString(16)}}`;
    else out += ch;
  }
  return out + "'";
}

const dartNumbers = (xs) => `[${xs.map(dartNumber).join(", ")}]`;
const dartNumberLists = (xss) => `[${xss.map(dartNumbers).join(", ")}]`;
const dartNumberListLists = (xsss) =>
  `[${xsss.map(dartNumberLists).join(", ")}]`;
const dartStrings = (xs) => `[${xs.map(dartString).join(", ")}]`;
const dartColor = (c) =>
  `(space: ${dartString(c.space)}, channels: ${dartNumbers(c.channels)})`;

// ---------------------------------------------------------------------------
// 1. number, round, hue and interpolate of two numbers.

const numberCases = [];
function addNumber(interpolator, f, a, b) {
  const i = f(a, b);
  numberCases.push({interpolator, a, b, values: TS.map((t) => i(t))});
}

for (let k = 0; k < 40; ++k) {
  addNumber("interpolateNumber", d3.interpolateNumber, value(-1000, 1000), value(-1000, 1000));
}
for (const [a, b] of [
  [0, 0],
  [-0, -0],
  [0, -0],
  [-0, 0],
  [1, 1],
  [0.1, 0.2],
  [0.1, 0.1],
  [NaN, 1],
  [1, NaN],
  [Infinity, 1],
  [1, Infinity],
  [-Infinity, Infinity],
  [1e300, -1e300],
  [5e-324, -5e-324],
  [-1e308, 1e308],
  [9007199254740993, 9007199254740992],
]) {
  addNumber("interpolateNumber", d3.interpolateNumber, a, b);
}

for (let k = 0; k < 30; ++k) {
  addNumber("interpolateRound", d3.interpolateRound, value(-10, 10), value(-10, 10));
}
for (const [a, b] of [
  [-1, 0],
  [0, -1],
  [-3, -2],
  [-2, -3],
  [2, 3],
  [-0, -0],
  [0, -0],
  [-0.4, -0.4],
  [-0.6, 0.6],
  [-0.5, -0.5],
  [-1.5, -1.5],
  [-2.5, -2.5],
  [0.5, 0.5],
  [1.5, 1.5],
  [2.5, 2.5],
  [0.49999999999999994, 0.49999999999999994],
  [-0.49999999999999994, -0.49999999999999994],
  [-0.5000000000000001, -0.5000000000000001],
  [4503599627370495.5, 4503599627370495.5],
  [-4503599627370495.5, -4503599627370495.5],
  [9007199254740991, 9007199254740993],
  [1e300, -1e300],
  [NaN, 0],
  [0, NaN],
  [Infinity, 0],
  [-Infinity, 0],
  [0, Infinity],
]) {
  addNumber("interpolateRound", d3.interpolateRound, a, b);
}

for (let k = 0; k < 40; ++k) {
  addNumber("interpolateHue", d3.interpolateHue, value(-720, 720), value(-720, 720));
}
for (const [a, b] of [
  [0, 0],
  [-0, -0],
  [0, 360],
  [360, 0],
  [720, 0],
  [-360, 0],
  [350, 10],
  [10, 350],
  [0, 180],
  [0, -180],
  [180, 0],
  [0, 180.00000000000003],
  [0, -180.00000000000003],
  [0, 540],
  [0, -540],
  [0, 900],
  [0, -900],
  [0, 1260],
  [0, -1260],
  [0, 541],
  [0, -541],
  [-10, 10],
  [NaN, 120],
  [120, NaN],
  [NaN, NaN],
  [Infinity, 0],
  [0, Infinity],
  [-Infinity, -Infinity],
  [1e20, 0],
  [0, -1e-20],
  [359.99999999999994, 0],
]) {
  addNumber("interpolateHue", d3.interpolateHue, a, b);
}

for (let k = 0; k < 10; ++k) {
  addNumber("interpolate", d3.interpolate, value(-100, 100), value(-100, 100));
}
for (const [a, b] of [
  [NaN, 1],
  [1, NaN],
  [-0, -0],
]) {
  addNumber("interpolate", d3.interpolate, a, b);
}

// ---------------------------------------------------------------------------
// 2. basis and basisClosed.

const splineCases = [];
function addSpline(interpolator, f, values) {
  const i = f(values.slice());
  splineCases.push({interpolator, values, results: TS.map((t) => i(t))});
}
for (let k = 0; k < 25; ++k) {
  addSpline("interpolateBasis", d3.interpolateBasis, list(integer(2, 8), () => value(-100, 100)));
}
for (const values of [
  [0, 1],
  [0, 0],
  [-0, -0],
  [1, 2, 3, 4],
  [0, 10, 0, 10],
  [NaN, 1, 2],
  [0, 1, NaN],
  [Infinity, 0, 1],
  [1e300, -1e300, 1e300],
]) {
  addSpline("interpolateBasis", d3.interpolateBasis, values);
}
for (let k = 0; k < 25; ++k) {
  addSpline("interpolateBasisClosed", d3.interpolateBasisClosed, list(integer(1, 8), () => value(-100, 100)));
}
for (const values of [
  [5],
  [-0],
  [0, 1],
  [1, 2, 3, 4],
  [0, 10, 0, 10],
  [NaN, 1, 2],
  [Infinity, 0, 1],
]) {
  addSpline("interpolateBasisClosed", d3.interpolateBasisClosed, values);
}

// ---------------------------------------------------------------------------
// 3. discrete.

const discreteCases = [];
for (let k = 0; k < 12; ++k) {
  const range = list(integer(1, 7), () => value(-100, 100));
  const i = d3.interpolateDiscrete(range.slice());
  discreteCases.push({range, results: TS.map((t) => i(t))});
}

// ---------------------------------------------------------------------------
// 4. piecewise of numbers.

const piecewiseCases = [];
const piecewiseInterpolators = {
  interpolate: undefined,
  interpolateNumber: d3.interpolateNumber,
  interpolateRound: d3.interpolateRound,
};
for (const name of Object.keys(piecewiseInterpolators)) {
  for (let k = 0; k < 8; ++k) {
    const values = list(integer(2, 6), () => value(-100, 100));
    const f = piecewiseInterpolators[name];
    const i = f === undefined ? d3.piecewise(values.slice()) : d3.piecewise(f, values.slice());
    piecewiseCases.push({interpolate: name, values, results: TS.map((t) => i(t))});
  }
}
for (const values of [
  [0, 1],
  [0, 10, 0],
  [-0, -0, -0],
  [NaN, 0, 1],
]) {
  const i = d3.piecewise(values.slice());
  piecewiseCases.push({interpolate: "interpolate", values, results: TS.map((t) => i(t))});
}

// ---------------------------------------------------------------------------
// 5. quantize.

const quantizeCases = [];
for (const name of ["interpolateNumber", "interpolateRound"]) {
  for (const n of [0, 1, 2, 3, 5, 10, 17]) {
    const a = value(-100, 100);
    const b = value(-100, 100);
    quantizeCases.push({interpolator: name, a, b, n, samples: d3.quantize(d3[name](a, b), n)});
  }
}

// ---------------------------------------------------------------------------
// 6. Color interpolators.

const makers = {
  rgb: (x, y, z, o) => d3color.rgb(x, y, z, o),
  hsl: (x, y, z, o) => d3color.hsl(x, y, z, o),
  lab: (x, y, z, o) => d3color.lab(x, y, z, o),
  hcl: (x, y, z, o) => d3color.hcl(x, y, z, o),
  cubehelix: (x, y, z, o) => d3color.cubehelix(x, y, z, o),
};
const ranges = {
  rgb: [[0, 255], [0, 255], [0, 255]],
  hsl: [[-360, 720], [0, 1], [0, 1]],
  lab: [[0, 100], [-100, 100], [-100, 100]],
  hcl: [[-360, 720], [0, 130], [0, 100]],
  cubehelix: [[-360, 720], [0, 2], [0, 1]],
};

/// A channel: mostly in [lo, hi], sometimes outside or NaN.
function channel(lo, hi) {
  const u = random();
  if (u < 0.04) return NaN;
  if (u < 0.12) return uniform(lo - (hi - lo) / 4, hi + (hi - lo) / 4);
  if (u < 0.25) return Math.round(uniform(lo, hi));
  return uniform(lo, hi);
}

function opacity() {
  const u = random();
  if (u < 0.5) return 1;
  if (u < 0.55) return 0;
  if (u < 0.58) return NaN;
  return random();
}

/// A random color of [space] as {space, channels}.
function randomColor(space) {
  const [r0, r1, r2] = ranges[space];
  return {space, channels: [channel(...r0), channel(...r1), channel(...r2), opacity()]};
}

const makeColor = (c) => makers[c.space](...c.channels);

const colorCases = [];
const colorInterpolators = {
  interpolateRgb: (g) => (g === 1 ? d3.interpolateRgb : d3.interpolateRgb.gamma(g)),
  interpolateHsl: () => d3.interpolateHsl,
  interpolateHslLong: () => d3.interpolateHslLong,
  interpolateLab: () => d3.interpolateLab,
  interpolateHcl: () => d3.interpolateHcl,
  interpolateHclLong: () => d3.interpolateHclLong,
  interpolateCubehelix: (g) => (g === 1 ? d3.interpolateCubehelix : d3.interpolateCubehelix.gamma(g)),
  interpolateCubehelixLong: (g) =>
    g === 1 ? d3.interpolateCubehelixLong : d3.interpolateCubehelixLong.gamma(g),
  interpolate: () => d3.interpolate,
};

function addColor(interpolator, gamma, start, end) {
  const i = colorInterpolators[interpolator](gamma)(makeColor(start), makeColor(end));
  const results = TS.map((t) => colorResult(i, t));
  const spaces = new Set(results.map((r) => r.space));
  if (spaces.size !== 1) throw new Error(`${interpolator} gave ${[...spaces]}`);
  colorCases.push({
    interpolator,
    gamma,
    start,
    end,
    space: results[0].space,
    channels: results.map((r) => r.channels),
    texts: results.map((r) => r.text),
  });
}

/// The main space of each interpolator, and the other spaces of its inputs.
const colorPlan = [
  ["interpolateRgb", [1, 2.2, 3, 0.5], "rgb", ["hsl", "lab", "hcl", "cubehelix"]],
  ["interpolateHsl", [1], "hsl", ["rgb", "lab"]],
  ["interpolateHslLong", [1], "hsl", ["rgb", "hcl"]],
  ["interpolateLab", [1], "lab", ["rgb", "hcl"]],
  ["interpolateHcl", [1], "hcl", ["rgb", "lab"]],
  ["interpolateHclLong", [1], "hcl", ["rgb", "cubehelix"]],
  ["interpolateCubehelix", [1, 3], "cubehelix", ["rgb", "hsl"]],
  ["interpolateCubehelixLong", [1, 3], "cubehelix", ["rgb", "lab"]],
  ["interpolate", [1], "rgb", ["hsl", "hcl"]],
];
for (const [interpolator, gammas, main, others] of colorPlan) {
  for (const gamma of gammas) {
    for (let k = 0; k < 16; ++k) {
      addColor(interpolator, gamma, randomColor(main), randomColor(main));
    }
    for (let k = 0; k < 6; ++k) {
      addColor(interpolator, gamma, randomColor(pick(others)), randomColor(pick(others)));
    }
  }
}

// Fixed pairs: NaN channels (a gray hue, an undefined opacity), the same
// color, and hue steps at the edges of the shortest path.
const fixedColorPairs = {
  rgb: [
    [[255, 0, 0, 1], [0, 0, 255, 1]],
    [[70, 130, 180, 1], [70, 130, 180, 1]],
    [[NaN, NaN, NaN, 0], [70, 130, 180, 1]],
    [[70, 130, 180, 1], [NaN, NaN, NaN, 0]],
    [[NaN, 128, 64, 0.5], [10, NaN, 64, NaN]],
    [[-10, 300, 0, 1], [20, 30, 400, 0.5]],
    [[0, 0, 0, 1], [255, 255, 255, 1]],
    [[-0, 0, -0, 1], [0, -0, 0, 1]],
  ],
  hsl: [
    [[0, 1, 0.5, 1], [180, 1, 0.5, 1]],
    [[0, 1, 0.5, 1], [-180, 1, 0.5, 1]],
    [[0, 1, 0.5, 1], [540, 1, 0.5, 1]],
    [[0, 1, 0.5, 1], [-540, 1, 0.5, 1]],
    [[0, 1, 0.5, 1], [900, 1, 0.5, 1]],
    [[0, 1, 0.5, 1], [-900, 1, 0.5, 1]],
    [[350, 1, 0.5, 1], [10, 1, 0.5, 1]],
    [[NaN, 0, 0.5, 1], [120, 1, 0.5, 1]],
    [[120, 1, 0.5, 1], [NaN, 0, 0.5, 1]],
    [[NaN, NaN, 0, 1], [NaN, NaN, 1, 1]],
    [[120, 0.5, 0.5, NaN], [240, 0.5, 0.5, 0.5]],
  ],
  lab: [
    [[50, 0, 0, 1], [50, 0, 0, 1]],
    [[0, 0, 0, 1], [100, 0, 0, 1]],
    [[50, NaN, NaN, 1], [60, 20, -20, 1]],
    [[53.24, 80.09, 67.2, 1], [32.3, 79.19, -107.86, 0.5]],
  ],
  hcl: [
    [[NaN, 0, 50, 1], [40, 60, 50, 1]],
    [[40, 60, 50, 1], [NaN, 0, 50, 1]],
    [[0, 60, 50, 1], [180, 60, 50, 1]],
    [[0, 60, 50, 1], [-540, 60, 50, 1]],
    [[0, 60, 50, 1], [900, 60, 50, 1]],
    [[300, 60, 50, 1], [60, 60, 50, 1]],
    [[NaN, NaN, NaN, NaN], [NaN, NaN, NaN, NaN]],
  ],
  cubehelix: [
    [[300, 0.5, 0, 1], [-240, 0.5, 1, 1]],
    [[0, 1, 0.5, 1], [-540, 1, 0.5, 1]],
    [[0, 1, 0.5, 1], [900, 1, 0.5, 1]],
    [[NaN, 0.5, 0.5, 1], [260, 0.75, 0.35, 1]],
    [[260, 0.75, 0.35, 1], [80, 1.5, 0.8, 0.5]],
  ],
};
for (const [interpolator, gammas, main] of colorPlan) {
  for (const gamma of gammas) {
    for (const [s, e] of fixedColorPairs[main]) {
      addColor(interpolator, gamma, {space: main, channels: s}, {space: main, channels: e});
    }
  }
}

// ---------------------------------------------------------------------------
// 7. rgbBasis and rgbBasisClosed.

const colorSplineCases = [];
const colorSplines = {
  interpolateRgbBasis: d3.interpolateRgbBasis,
  interpolateRgbBasisClosed: d3.interpolateRgbBasisClosed,
};
function addColorSpline(interpolator, colors) {
  const i = colorSplines[interpolator](colors.map(makeColor));
  const results = TS.map((t) => colorResult(i, t));
  colorSplineCases.push({
    interpolator,
    colors,
    channels: results.map((r) => r.channels),
    texts: results.map((r) => r.text),
  });
}
for (const interpolator of Object.keys(colorSplines)) {
  const min = interpolator === "interpolateRgbBasis" ? 2 : 1;
  for (let k = 0; k < 14; ++k) {
    addColorSpline(interpolator, list(integer(min, 7), () => randomColor("rgb")));
  }
  for (let k = 0; k < 4; ++k) {
    addColorSpline(interpolator, list(integer(min, 5), () => randomColor(pick(["hsl", "lab", "hcl"]))));
  }
  addColorSpline(interpolator, [
    {space: "rgb", channels: [NaN, NaN, NaN, 0]},
    {space: "rgb", channels: [255, 0, NaN, 0.5]},
    {space: "rgb", channels: [0, 255, 128, 1]},
  ]);
}

// ---------------------------------------------------------------------------
// 8. Dates: the time values in milliseconds.

const dateCases = [];
const year2100 = Date.UTC(2100, 0, 1);
const year1900 = Date.UTC(1900, 0, 1);
function addDate(interpolator, a, b) {
  const i = (interpolator === "interpolate" ? d3.interpolate : d3.interpolateDate)(new Date(a), new Date(b));
  dateCases.push({interpolator, a, b, times: TS.map((t) => i(t).getTime())});
}
for (let k = 0; k < 30; ++k) {
  addDate("interpolateDate", integer(year1900, year2100), integer(year1900, year2100));
}
for (let k = 0; k < 10; ++k) {
  const a = integer(0, 1e12);
  addDate("interpolateDate", a, a + integer(-5, 5));
}
for (const [a, b] of [
  [0, 0],
  [0, 1],
  [0, -1],
  [-1, 1],
  [0, 3],
  [-3, 0],
  [Date.UTC(2000, 0, 1), Date.UTC(2000, 0, 2)],
  [Date.UTC(1969, 11, 31, 23, 59, 59, 999), Date.UTC(1970, 0, 1)],
]) {
  addDate("interpolateDate", a, b);
}
for (let k = 0; k < 6; ++k) {
  addDate("interpolate", integer(year1900, year2100), integer(year1900, year2100));
}

// ---------------------------------------------------------------------------
// 9. Number arrays: Float64Array and Float32Array.

const numberArrayCases = [];
const typedArrays = {Float64: Float64Array, Float32: Float32Array};
const arrayFunctions = {
  interpolateNumberArray: d3.interpolateNumberArray,
  interpolateArray: d3.interpolateArray,
  interpolate: d3.interpolate,
};
function addNumberArray(interpolator, type, a, b) {
  const i = arrayFunctions[interpolator](a.slice(), typedArrays[type].from(b));
  numberArrayCases.push({interpolator, type, a, b, results: TS.map((t) => Array.from(i(t)))});
}
for (const interpolator of Object.keys(arrayFunctions)) {
  for (const type of Object.keys(typedArrays)) {
    for (let k = 0; k < 6; ++k) {
      addNumberArray(
        interpolator,
        type,
        list(integer(0, 6), () => value(-100, 100)),
        list(integer(0, 6), () => value(-100, 100)),
      );
    }
  }
}
for (const [a, b] of [
  [[], []],
  [[1, 2, 3], []],
  [[], [1, 2, 3]],
  [[NaN, 0], [1, Infinity]],
  [[-0, 0], [-0, -0]],
  [[1e300], [-1e300]],
]) {
  addNumberArray("interpolateNumberArray", "Float64", a, b);
  addNumberArray("interpolateNumberArray", "Float32", a, b);
}

// ---------------------------------------------------------------------------
// 10. Arrays of numbers and arrays of arrays of numbers.

const arrayCases = [];
function addArray(interpolator, a, b) {
  const i = arrayFunctions[interpolator](a.slice(), b.slice());
  arrayCases.push({interpolator, a, b, results: TS.map((t) => i(t).slice())});
}
for (const interpolator of ["interpolateArray", "interpolate"]) {
  for (let k = 0; k < 12; ++k) {
    addArray(
      interpolator,
      list(integer(0, 6), () => value(-100, 100)),
      list(integer(0, 6), () => value(-100, 100)),
    );
  }
}
for (const [a, b] of [
  [[], []],
  [[1, 2], [3]],
  [[1], [3, 4]],
  [[NaN, 1], [2, NaN]],
  [[-0], [-0]],
]) {
  addArray("interpolateArray", a, b);
}

const nestedArrayCases = [];
function addNestedArray(interpolator, a, b) {
  const copy = (x) => x.map((y) => y.slice());
  const i = arrayFunctions[interpolator](copy(a), copy(b));
  nestedArrayCases.push({interpolator, a, b, results: TS.map((t) => copy(i(t)))});
}
const randomNested = () => list(integer(0, 4), () => list(integer(0, 4), () => value(-100, 100)));
for (const interpolator of ["interpolateArray", "interpolate"]) {
  for (let k = 0; k < 8; ++k) {
    addNestedArray(interpolator, randomNested(), randomNested());
  }
}
addNestedArray("interpolateArray", [[1, 2], [3]], [[4], [5, 6], [7]]);

// ---------------------------------------------------------------------------
// 11. zoom.

const zoomCases = [];
function addZoom(rho, p0, p1) {
  const z = rho === null ? d3.interpolateZoom : d3.interpolateZoom.rho(rho);
  const i = z(p0.slice(), p1.slice());
  zoomCases.push({rho, p0, p1, duration: i.duration, views: TS.map((t) => i(t).slice())});
}
const randomView = () => [uniform(-1000, 1000), uniform(-1000, 1000), uniform(0.5, 2000)];
for (const rho of [null, Math.SQRT2, 1, 0.5, 2, 1e-4]) {
  for (let k = 0; k < 8; ++k) addZoom(rho, randomView(), randomView());
  // u0 = u1 within the epsilon of the special case.
  const p = randomView();
  addZoom(rho, p, [p[0], p[1], uniform(0.5, 2000)]);
  addZoom(rho, p, [p[0] + 1e-7, p[1] - 1e-7, p[2]]);
  addZoom(rho, p, p.slice());
}
for (const [rho, p0, p1] of [
  // test/zoom-test.js
  [null, [324.68721096803614, 59.43501602433761, 1.8827137399562621], [324.6872108946794, 59.43501601062763, 7.399052110984391]],
  [null, [0, 0, 1], [0, 0, 1.1]],
  [null, [0, 0, 1], [0, 0, 2]],
  [null, [0, 0, 1], [10, 0, 8]],
  [null, [0, 0, 1], [10, 10, 5]],
  [0, [0, 0, 1], [10, 0, 8]],
  [2, [0, 0, 1], [10, 0, 8]],
  // d2 at the epsilon: the general case.
  [null, [0, 0, 1], [1e-6, 0, 1]],
  [null, [0, 0, 1], [9.9e-7, 0, 1]],
  [null, [0, 0, 1], [3, 4, 1]],
]) {
  addZoom(rho, p0, p1);
}

// ---------------------------------------------------------------------------
// 12. decompose.

const parts = (o) => [o.translateX, o.translateY, o.rotate, o.skewX, o.scaleX, o.scaleY];
const decomposeCases = [];
function addDecompose(m) {
  decomposeCases.push({matrix: m, parts: parts(decompose(...m))});
}
const deg = Math.PI / 180;
for (let k = 0; k < 30; ++k) {
  addDecompose(list(6, () => uniform(-10, 10)));
}
for (let k = 0; k < 10; ++k) {
  const r = uniform(-180, 180) * deg;
  const sx = uniform(0.1, 5) * pick([1, -1]);
  const sy = uniform(0.1, 5);
  addDecompose([sx * Math.cos(r), sx * Math.sin(r), -sy * Math.sin(r), sy * Math.cos(r), uniform(-100, 100), uniform(-100, 100)]);
}
for (const m of [
  [1, 0, 0, 1, 0, 0],
  [1, 0, 0, 1, 10, -20],
  [-1, 0, 0, 1, 0, 0],
  [1, 0, 0, -1, 0, 0],
  [-1, 0, 0, -1, 0, 0],
  [0, 1, 1, 0, 0, 0],
  [0, 1, -1, 0, 0, 0],
  [0, -1, 1, 0, 0, 0],
  [1, 0, Math.tan(30 * deg), 1, 0, 0],
  [1, Math.tan(20 * deg), 0, 1, 0, 0],
  [2, 0, 1, 3, 0, 0],
  [0, 0, 0, 1, 0, 0],
  [1, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 0, 0],
  [0, 0, 0, 0, 5, 6],
  [-0, -0, -0, -0, -0, -0],
  [0, 0, 1, 0, 0, 0],
  [1, 1, 1, 1, 0, 0],
  [1e-300, 0, 0, 1e-300, 0, 0],
  [1e300, 0, 0, 1e300, 0, 0],
  [3, 4, -4, 3, 0, 0],
]) {
  addDecompose(m);
}

// ---------------------------------------------------------------------------
// 13. interpolateTransformSvg through a fake document.

const multiply = (m, n) => ({
  a: m.a * n.a + m.c * n.b,
  b: m.b * n.a + m.d * n.b,
  c: m.a * n.c + m.c * n.d,
  d: m.b * n.c + m.d * n.d,
  e: m.a * n.e + m.c * n.f + m.e,
  f: m.b * n.e + m.d * n.f + m.f,
});
const translateMatrix = (x, y) => ({a: 1, b: 0, c: 0, d: 1, e: x, f: y});

/// The matrix of an SVG transform list, or null for an empty list.
function consolidate(text) {
  const re = /(matrix|translate|scale|rotate|skewX|skewY)\s*\(([^)]*)\)/g;
  let m = null;
  let match;
  while ((match = re.exec(text)) !== null) {
    const args = match[2].split(/[\s,]+/).filter((s) => s !== "").map(Number);
    let n;
    switch (match[1]) {
      case "matrix":
        n = {a: args[0], b: args[1], c: args[2], d: args[3], e: args[4], f: args[5]};
        break;
      case "translate":
        n = translateMatrix(args[0], args[1] ?? 0);
        break;
      case "scale":
        n = {a: args[0], b: 0, c: 0, d: args[1] ?? args[0], e: 0, f: 0};
        break;
      case "rotate": {
        const r = args[0] * deg;
        n = {a: Math.cos(r), b: Math.sin(r), c: -Math.sin(r), d: Math.cos(r), e: 0, f: 0};
        if (args.length === 3) {
          n = multiply(multiply(translateMatrix(args[1], args[2]), n), translateMatrix(-args[1], -args[2]));
        }
        break;
      }
      case "skewX":
        n = {a: 1, b: 0, c: Math.tan(args[0] * deg), d: 1, e: 0, f: 0};
        break;
      case "skewY":
        n = {a: 1, b: Math.tan(args[0] * deg), c: 0, d: 1, e: 0, f: 0};
        break;
    }
    m = m === null ? n : multiply(m, n);
  }
  return m;
}

globalThis.document = {
  createElementNS(namespace, name) {
    if (namespace !== "http://www.w3.org/2000/svg" || name !== "g") {
      throw new Error(`createElementNS(${namespace}, ${name})`);
    }
    let attribute = null;
    return {
      setAttribute(key, v) {
        if (key !== "transform") throw new Error(`setAttribute(${key})`);
        attribute = String(v);
      },
      transform: {
        baseVal: {
          consolidate() {
            const matrix = consolidate(attribute);
            return matrix === null ? null : {matrix};
          },
        },
      },
    };
  },
};

/// The parts of a transform text, as parseSvg reads them.
function partsOfText(text) {
  if (text == null) return parts(identity);
  const m = consolidate(String(text));
  return m === null ? parts(identity) : parts(decompose(m.a, m.b, m.c, m.d, m.e, m.f));
}

/// The six numbers of a result text of interpolateTransformSvg.
function partsOfResult(text) {
  const out = parts(identity);
  const re = /(translate|rotate|skewX|scale)\(([^)]*)\)/g;
  let rest = text;
  let match;
  while ((match = re.exec(text)) !== null) {
    const args = match[2].split(",").map((s) => Number(s.trim()));
    switch (match[1]) {
      case "translate":
        out[0] = args[0];
        out[1] = args[1];
        break;
      case "rotate":
        out[2] = args[0];
        break;
      case "skewX":
        out[3] = args[0];
        break;
      case "scale":
        out[4] = args[0];
        out[5] = args[1];
        break;
    }
    rest = rest.replace(match[0], "");
  }
  if (rest.trim() !== "") throw new Error(`unread transform text: ${text}`);
  return out;
}

const transformCases = [];
function addTransform(a, b) {
  const i = d3.interpolateTransformSvg(a, b);
  transformCases.push({
    a: a ?? "",
    b: b ?? "",
    partsA: partsOfText(a),
    partsB: partsOfText(b),
    results: TS.map((t) => partsOfResult(i(t))),
  });
}
const numberText = (lo, hi) => String(pick([Math.round(uniform(lo, hi)), uniform(lo, hi)]));
function randomTransform() {
  const tokens = [];
  for (let k = integer(1, 3); k > 0; --k) {
    switch (integer(0, 5)) {
      case 0:
        tokens.push(`translate(${numberText(-200, 200)}, ${numberText(-200, 200)})`);
        break;
      case 1:
        tokens.push(`rotate(${numberText(-360, 360)})`);
        break;
      case 2:
        tokens.push(`scale(${numberText(-3, 3)}, ${numberText(0.1, 3)})`);
        break;
      case 3:
        tokens.push(`skewX(${numberText(-60, 60)})`);
        break;
      case 4:
        tokens.push(`skewY(${numberText(-60, 60)})`);
        break;
      default:
        tokens.push(`matrix(${list(6, () => numberText(-5, 5)).join(" ")})`);
    }
  }
  return tokens.join(" ");
}
for (let k = 0; k < 40; ++k) addTransform(randomTransform(), randomTransform());
for (const [a, b] of [
  [null, null],
  ["", ""],
  [null, "translate(10, 20)"],
  ["translate(10, 20)", null],
  ["translate(10, 20)", "translate(10, 20)"],
  ["translate(10, 20)", "translate(30, 20)"],
  ["translate(10, 20)", "translate(10, 40)"],
  ["rotate(10)", "rotate(10)"],
  ["rotate(-170)", "rotate(170)"],
  ["rotate(170)", "rotate(-170)"],
  ["rotate(0)", "rotate(180)"],
  ["rotate(90)", "rotate(-90)"],
  ["skewX(10)", "skewX(10)"],
  ["skewX(-30)", "skewX(30)"],
  ["scale(2, 3)", "scale(2, 3)"],
  ["scale(1, 1)", "scale(2, 1)"],
  ["scale(-1, 1)", "scale(1, 1)"],
  ["scale(0, 0)", "scale(2, 2)"],
  ["translate(0.1, 0.2) rotate(30)", "translate(0.1, 0.2) rotate(30) scale(2)"],
  ["matrix(1 2 3 4 5 6)", "rotate(45 10 10)"],
  ["translate(1e-7, -1e21)", "rotate(1e-7)"],
]) {
  addTransform(a, b);
}

// ---------------------------------------------------------------------------
// The Dart file.

const v8 = process.versions.v8;
const lines = [];
const out = (...s) => lines.push(...(s.length === 0 ? [""] : s));

/// The first line of the open list of beginList.
let listStart = -1;

/// Opens the list [name] of the records [type], as a const list.
function beginList(type, name) {
  listStart = lines.length;
  out(`const List<${type}> ${name} = [`);
}

/// Closes the list of beginList: a list that holds -0 is final.
function endList() {
  out("];");
  if (lines.slice(listStart).some((line) => line.includes(NEGATIVE_ZERO))) {
    lines[listStart] = lines[listStart].replace(/^const /, "final ");
  }
}

out(
  "// Original code, not ported from d3-interpolate: generated data, do not edit.",
  "// tool/reference/d3_interpolate_reference.mjs writes this file.",
  `// Node.js ${process.version} (${process.arch}), V8 ${v8}.`,
  `// d3-interpolate v3.0.1 src/ at ${interpolatePin}.`,
  `// d3-color v3.1.0 src/ at ${colorPin}.`,
  "// The data has long lines.",
  "// ignore_for_file: lines_longer_than_80_chars",
);
out();
out("/// The reference data of the d3-interpolate port: upstream d3-interpolate");
out("/// in Node.js.");
out("library;");
out();
out("/// The Node.js version that generated the data.");
out(`const String d3InterpolateReferenceNode = ${dartString(process.version)};`);
out();
out("/// The V8 version of the Node.js build that generated the data.");
out(`const String d3InterpolateReferenceV8 = ${dartString(v8)};`);
out();
out("/// The architecture of the Node.js build that generated the data.");
out(`const String d3InterpolateReferenceArch = ${dartString(process.arch)};`);
out();
out("/// The double -0.0. The data reads it at run time: on the web, the");
out("/// constant evaluator makes a whole double an int, so a constant -0.0 is");
out("/// +0. A list that holds it is final, not const.");
out(`final double ${NEGATIVE_ZERO} = double.parse('-0');`);
out();
out("/// The t values of each case, in the order of its results.");
out(`const List<double> ts = ${dartNumbers(TS)};`);
out();
out("/// Two numbers and the results of one number interpolator.");
out("typedef NumberCase = ({");
out("  /// `'interpolateNumber'`, `'interpolateRound'`, `'interpolateHue'` or");
out("  /// `'interpolate'`.");
out("  String interpolator,");
out();
out("  /// The first argument.");
out("  double a,");
out();
out("  /// The second argument.");
out("  double b,");
out();
out("  /// The result at each t of [ts].");
out("  List<double> values,");
out("});");
out();
out("/// The values of a spline and its results.");
out("typedef SplineCase = ({");
out("  /// `'interpolateBasis'` or `'interpolateBasisClosed'`.");
out("  String interpolator,");
out();
out("  /// The values.");
out("  List<double> values,");
out();
out("  /// The result at each t of [ts].");
out("  List<double> results,");
out("});");
out();
out("/// The range of `interpolateDiscrete` and its results.");
out("typedef DiscreteCase = ({");
out("  /// The range.");
out("  List<double> range,");
out();
out("  /// The result at each t of [ts].");
out("  List<double> results,");
out("});");
out();
out("/// The values of `piecewise` and its results.");
out("typedef PiecewiseCase = ({");
out("  /// The interpolator of each piece: `'interpolate'` (the default),");
out("  /// `'interpolateNumber'` or `'interpolateRound'`.");
out("  String interpolate,");
out();
out("  /// The values.");
out("  List<double> values,");
out();
out("  /// The result at each t of [ts].");
out("  List<double> results,");
out("});");
out();
out("/// `quantize(interpolator(a, b), n)`.");
out("typedef QuantizeCase = ({");
out("  /// `'interpolateNumber'` or `'interpolateRound'`.");
out("  String interpolator,");
out();
out("  /// The first argument of the interpolator.");
out("  double a,");
out();
out("  /// The second argument of the interpolator.");
out("  double b,");
out();
out("  /// The sample count.");
out("  int n,");
out();
out("  /// The samples.");
out("  List<double> samples,");
out("});");
out();
out("/// A color of the data: its space and its channels.");
out("typedef ColorValue = ({");
out("  /// `'rgb'`, `'hsl'`, `'lab'`, `'hcl'` or `'cubehelix'`.");
out("  String space,");
out();
out("  /// The three channels and the opacity, as the constructor of the space");
out("  /// takes them.");
out("  List<double> channels,");
out("});");
out();
out("/// Two colors and the results of one color interpolator.");
out("typedef ColorCase = ({");
out("  /// `'interpolateRgb'`, `'interpolateHsl'`, `'interpolateHslLong'`,");
out("  /// `'interpolateLab'`, `'interpolateHcl'`, `'interpolateHclLong'`,");
out("  /// `'interpolateCubehelix'`, `'interpolateCubehelixLong'` or");
out("  /// `'interpolate'`.");
out("  String interpolator,");
out();
out("  /// The gamma of `interpolateRgb` and of the cubehelix interpolators: 1 is");
out("  /// the interpolator itself, another value its `gamma(y)`.");
out("  double gamma,");
out();
out("  /// The start color.");
out("  ColorValue start,");
out();
out("  /// The end color.");
out("  ColorValue end,");
out();
out("  /// The space of each result.");
out("  String space,");
out();
out("  /// The channels of the result at each t of [ts], in [space].");
out("  List<List<double>> channels,");
out();
out("  /// The text that upstream returns at each t of [ts] (`formatRgb`).");
out("  List<String> texts,");
out("});");
out();
out("/// The colors of an RGB spline and its results.");
out("typedef ColorSplineCase = ({");
out("  /// `'interpolateRgbBasis'` or `'interpolateRgbBasisClosed'`.");
out("  String interpolator,");
out();
out("  /// The colors.");
out("  List<ColorValue> colors,");
out();
out("  /// The RGB channels of the result at each t of [ts].");
out("  List<List<double>> channels,");
out();
out("  /// The text that upstream returns at each t of [ts] (`formatRgb`).");
out("  List<String> texts,");
out("});");
out();
out("/// Two dates (their time values in milliseconds) and the results.");
out("typedef DateCase = ({");
out("  /// `'interpolateDate'` or `'interpolate'`.");
out("  String interpolator,");
out();
out("  /// The time value of the first date.");
out("  int a,");
out();
out("  /// The time value of the second date.");
out("  int b,");
out();
out("  /// The time value of the result at each t of [ts].");
out("  List<int> times,");
out("});");
out();
out("/// A list and a typed number list, and the results.");
out("typedef NumberArrayCase = ({");
out("  /// `'interpolateNumberArray'`, `'interpolateArray'` or `'interpolate'`.");
out("  String interpolator,");
out();
out("  /// The class of the second argument: `'Float64'` (`Float64List`) or");
out("  /// `'Float32'` (`Float32List`).");
out("  String type,");
out();
out("  /// The first argument, a `List<double>`.");
out("  List<double> a,");
out();
out("  /// The values of the second argument, before the typed list stores them.");
out("  List<double> b,");
out();
out("  /// The elements of the result at each t of [ts].");
out("  List<List<double>> results,");
out("});");
out();
out("/// Two lists of numbers and the results.");
out("typedef ArrayCase = ({");
out("  /// `'interpolateArray'` or `'interpolate'`.");
out("  String interpolator,");
out();
out("  /// The first argument.");
out("  List<double> a,");
out();
out("  /// The second argument.");
out("  List<double> b,");
out();
out("  /// The elements of the result at each t of [ts].");
out("  List<List<double>> results,");
out("});");
out();
out("/// Two lists of lists of numbers and the results.");
out("typedef NestedArrayCase = ({");
out("  /// `'interpolateArray'` or `'interpolate'`.");
out("  String interpolator,");
out();
out("  /// The first argument.");
out("  List<List<double>> a,");
out();
out("  /// The second argument.");
out("  List<List<double>> b,");
out();
out("  /// The elements of the result at each t of [ts].");
out("  List<List<List<double>>> results,");
out("});");
out();
out("/// Two views and the results of `interpolateZoom`.");
out("typedef ZoomCase = ({");
out("  /// The rho of `interpolateZoom.rho(rho)`, or null for `interpolateZoom`.");
out("  double? rho,");
out();
out("  /// The start view: ux, uy and w.");
out("  List<double> p0,");
out();
out("  /// The end view: ux, uy and w.");
out("  List<double> p1,");
out();
out("  /// The duration in milliseconds.");
out("  double duration,");
out();
out("  /// The view (ux, uy and w) at each t of [ts].");
out("  List<List<double>> views,");
out("});");
out();
out("/// The six numbers of `decompose(a, b, c, d, e, f)` and its parts.");
out("typedef DecomposeCase = ({");
out("  /// a, b, c, d, e and f.");
out("  List<double> matrix,");
out();
out("  /// translateX, translateY, rotate, skewX, scaleX and scaleY.");
out("  List<double> parts,");
out("});");
out();
out("/// Two SVG transform texts and the results of `interpolateTransformSvg`.");
out("typedef TransformCase = ({");
out("  /// The first text (empty for null).");
out("  String a,");
out();
out("  /// The second text (empty for null).");
out("  String b,");
out();
out("  /// The parts of [a]: translateX, translateY, rotate, skewX, scaleX and");
out("  /// scaleY.");
out("  List<double> partsA,");
out();
out("  /// The parts of [b].");
out("  List<double> partsB,");
out();
out("  /// The six numbers of the result text at each t of [ts]. A part that the");
out("  /// text omits is the identity value. The text loses the sign of a zero.");
out("  List<List<double>> results,");
out("});");
out();

out("/// 1. Number interpolators.");
beginList("NumberCase", "numberCases");
for (const c of numberCases) {
  out(
    `  (interpolator: ${dartString(c.interpolator)}, a: ${dartNumber(c.a)}, b: ${dartNumber(c.b)}, ` +
      `values: ${dartNumbers(c.values)}),`,
  );
}
endList();
out();
out("/// 2. Splines of numbers.");
beginList("SplineCase", "splineCases");
for (const c of splineCases) {
  out(
    `  (interpolator: ${dartString(c.interpolator)}, values: ${dartNumbers(c.values)}, ` +
      `results: ${dartNumbers(c.results)}),`,
  );
}
endList();
out();
out("/// 3. Discrete ranges.");
beginList("DiscreteCase", "discreteCases");
for (const c of discreteCases) {
  out(`  (range: ${dartNumbers(c.range)}, results: ${dartNumbers(c.results)}),`);
}
endList();
out();
out("/// 4. Piecewise interpolators of numbers.");
beginList("PiecewiseCase", "piecewiseCases");
for (const c of piecewiseCases) {
  out(
    `  (interpolate: ${dartString(c.interpolate)}, values: ${dartNumbers(c.values)}, ` +
      `results: ${dartNumbers(c.results)}),`,
  );
}
endList();
out();
out("/// 5. quantize.");
beginList("QuantizeCase", "quantizeCases");
for (const c of quantizeCases) {
  out(
    `  (interpolator: ${dartString(c.interpolator)}, a: ${dartNumber(c.a)}, b: ${dartNumber(c.b)}, ` +
      `n: ${dartInt(c.n)}, samples: ${dartNumbers(c.samples)}),`,
  );
}
endList();
out();
out("/// 6. Color interpolators.");
beginList("ColorCase", "colorCases");
for (const c of colorCases) {
  out(
    `  (interpolator: ${dartString(c.interpolator)}, gamma: ${dartNumber(c.gamma)}, ` +
      `start: ${dartColor(c.start)}, end: ${dartColor(c.end)}, space: ${dartString(c.space)}, ` +
      `channels: ${dartNumberLists(c.channels)}, texts: ${dartStrings(c.texts)}),`,
  );
}
endList();
out();
out("/// 7. RGB splines.");
beginList("ColorSplineCase", "colorSplineCases");
for (const c of colorSplineCases) {
  out(
    `  (interpolator: ${dartString(c.interpolator)}, colors: [${c.colors.map(dartColor).join(", ")}], ` +
      `channels: ${dartNumberLists(c.channels)}, texts: ${dartStrings(c.texts)}),`,
  );
}
endList();
out();
out("/// 8. Dates.");
beginList("DateCase", "dateCases");
for (const c of dateCases) {
  out(
    `  (interpolator: ${dartString(c.interpolator)}, a: ${dartInt(c.a)}, b: ${dartInt(c.b)}, ` +
      `times: [${c.times.map(dartInt).join(", ")}]),`,
  );
}
endList();
out();
out("/// 9. Typed number lists.");
beginList("NumberArrayCase", "numberArrayCases");
for (const c of numberArrayCases) {
  out(
    `  (interpolator: ${dartString(c.interpolator)}, type: ${dartString(c.type)}, ` +
      `a: ${dartNumbers(c.a)}, b: ${dartNumbers(c.b)}, results: ${dartNumberLists(c.results)}),`,
  );
}
endList();
out();
out("/// 10. Lists of numbers.");
beginList("ArrayCase", "arrayCases");
for (const c of arrayCases) {
  out(
    `  (interpolator: ${dartString(c.interpolator)}, a: ${dartNumbers(c.a)}, b: ${dartNumbers(c.b)}, ` +
      `results: ${dartNumberLists(c.results)}),`,
  );
}
endList();
out();
out("/// 10. Lists of lists of numbers.");
beginList("NestedArrayCase", "nestedArrayCases");
for (const c of nestedArrayCases) {
  out(
    `  (interpolator: ${dartString(c.interpolator)}, a: ${dartNumberLists(c.a)}, ` +
      `b: ${dartNumberLists(c.b)}, results: ${dartNumberListLists(c.results)}),`,
  );
}
endList();
out();
out("/// 11. Zoom.");
beginList("ZoomCase", "zoomCases");
for (const c of zoomCases) {
  out(
    `  (rho: ${c.rho === null ? "null" : dartNumber(c.rho)}, p0: ${dartNumbers(c.p0)}, ` +
      `p1: ${dartNumbers(c.p1)}, duration: ${dartNumber(c.duration)}, views: ${dartNumberLists(c.views)}),`,
  );
}
endList();
out();
out("/// 12. decompose.");
beginList("DecomposeCase", "decomposeCases");
for (const c of decomposeCases) {
  out(`  (matrix: ${dartNumbers(c.matrix)}, parts: ${dartNumbers(c.parts)}),`);
}
endList();
out();
out("/// 13. interpolateTransformSvg.");
beginList("TransformCase", "transformCases");
for (const c of transformCases) {
  out(
    `  (a: ${dartString(c.a)}, b: ${dartString(c.b)}, partsA: ${dartNumbers(c.partsA)}, ` +
      `partsB: ${dartNumbers(c.partsB)}, results: ${dartNumberLists(c.results)}),`,
  );
}
endList();

const text = lines.join("\n") + "\n";
if (Buffer.byteLength(text) >= 2500000) {
  console.error(`The data has ${Buffer.byteLength(text)} bytes, not below 2,500,000.`);
  process.exit(1);
}
mkdirSync(path.dirname(output), {recursive: true});
writeFileSync(output, text);
console.log(
  `Wrote ${path.relative(packageRoot, output)} (${Buffer.byteLength(text)} bytes): ` +
    `${numberCases.length} number, ${splineCases.length} spline, ${discreteCases.length} discrete, ` +
    `${piecewiseCases.length} piecewise, ${quantizeCases.length} quantize, ${colorCases.length} color, ` +
    `${colorSplineCases.length} color spline, ${dateCases.length} date, ` +
    `${numberArrayCases.length} number array, ${arrayCases.length} array, ` +
    `${nestedArrayCases.length} nested array, ${zoomCases.length} zoom, ` +
    `${decomposeCases.length} decompose and ${transformCases.length} transform cases. ` +
    "Run dart format on it.",
);
