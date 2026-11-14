// Original code, not ported from d3-color: the reference data of the port.
//
// Writes test/port/d3_color_reference.dart from upstream d3-color
// v3.1.0 (third_party/d3-color/src/, ESM) on the reference engine of the
// repository, Node.js v24.22.1 on arm64 (Chart.js ADR 0146).
//
// Run from packages/flutter_d3_color_port:
//
//   node tool/reference/d3_color_reference.mjs
//   dart format test/port/d3_color_reference.dart
//
// The input set is deterministic: fixed lists and a mulberry32 generator
// with a fixed seed. The data has three parts:
//
//   a) CSS texts: color(text), rgb(text), hsl(text) and the formats of the
//      parsed color.
//   b) colors of the five spaces with numeric channels: the conversions,
//      brighter and darker, clamp, displayable and the formats.
//   c) numbers in [0, 1] and [0, 360] and their JavaScript String(x),
//      printed by hsl(h, 0.5, 0.5, opacity).formatHsl().

import {execFileSync} from "node:child_process";
import {
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  writeFileSync,
} from "node:fs";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";

const NODE_VERSION = "v24.22.1";
const NODE_ARCH = "arm64";

if (process.version !== NODE_VERSION || process.arch !== NODE_ARCH) {
  console.error(
    `d3_color_reference.mjs needs Node.js ${NODE_VERSION} on ${NODE_ARCH}, ` +
      `not ${process.version} on ${process.arch} (Chart.js ADR 0146).`,
  );
  process.exit(1);
}

const here = path.dirname(fileURLToPath(import.meta.url));
const packageRoot = path.resolve(here, "../..");
const repoRoot = path.resolve(packageRoot, "../..");
const submodule = path.join(repoRoot, "third_party/d3-color");
const output = path.join(
  packageRoot,
  "test/port/d3_color_reference.dart",
);

// The submodule must be at the commit of the d3-color entry of the
// tool/port_sources.yaml files of the packages, with no change in src/. Each
// entry that names d3-color must give the same commit.
const pins = new Set();
for (const name of readdirSync(path.join(repoRoot, "packages"))) {
  const file = path.join(repoRoot, "packages", name, "tool/port_sources.yaml");
  if (!existsSync(file)) continue;
  for (const entry of readFileSync(file, "utf8").split(/\n\s*- header: /)) {
    if (!entry.startsWith("d3-color\n")) continue;
    const commit = /\n\s*commit: ([0-9a-f]{40})/.exec(entry)?.[1];
    if (commit) pins.add(commit);
  }
}
if (pins.size !== 1) {
  console.error(
    `The tool/port_sources.yaml files of packages/ give ${pins.size} ` +
      "commits for d3-color, not 1.",
  );
  process.exit(1);
}
const [pinned] = pins;
const head = execFileSync("git", ["-C", submodule, "rev-parse", "HEAD"], {
  encoding: "utf8",
}).trim();
const dirty = execFileSync(
  "git",
  ["-C", submodule, "status", "--porcelain", "--", "src"],
  {encoding: "utf8"},
).trim();
if (head !== pinned || dirty !== "") {
  console.error(
    `third_party/d3-color must be at ${pinned} with no change in src/ ` +
      `(HEAD ${head}${dirty ? ", src/ changed" : ""}).`,
  );
  process.exit(1);
}

const d3 = await import(
  pathToFileURL(path.join(submodule, "src/index.js")).href
);

// The CSS names of color.js, read from the source: the module does not export
// its table.
const colorSource = readFileSync(path.join(submodule, "src/color.js"), "utf8");
const namedBlock = /var named = \{([^}]*)\}/.exec(colorSource)[1];
const names = [...namedBlock.matchAll(/^\s*([a-z]+):/gm)].map((m) => m[1]);
if (names.length !== 148) {
  console.error(`color.js has ${names.length} names, not 148.`);
  process.exit(1);
}

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
const random = mulberry32(0xd3c01031);
const uniform = (lo, hi) => lo + (hi - lo) * random();
const integer = (lo, hi) => Math.floor(uniform(lo, hi + 1));
const pick = (list) => list[Math.floor(random() * list.length)];

// ---------------------------------------------------------------------------
// Dart literals.

/// A double as a Dart literal: NaN, infinities and -0 by name, an integer
/// below 2^53 as an int literal (the context type is double), any other
/// number as JavaScript String(x), which round-trips.
function dartNumber(x) {
  if (Number.isNaN(x)) return "double.nan";
  if (x === Infinity) return "double.infinity";
  if (x === -Infinity) return "double.negativeInfinity";
  if (Object.is(x, -0)) return "-0.0";
  const s = String(x);
  if (/[.e]/.test(s)) return s;
  if (Math.abs(x) <= 2 ** 53) return s;
  return x.toExponential();
}

/// A string as a Dart literal in single quotes.
function dartString(s) {
  let out = "'";
  for (const ch of s) {
    const c = ch.codePointAt(0);
    if (ch === "\\") out += "\\\\";
    else if (ch === "'") out += "\\'";
    else if (ch === "$") out += "\\$";
    else if (c === 0x0a) out += "\\n";
    else if (c === 0x0d) out += "\\r";
    else if (c === 0x09) out += "\\t";
    else if (c < 0x20 || c > 0x7e) out += `\\u{${c.toString(16)}}`;
    else out += ch;
  }
  return out + "'";
}

const dartNumbers = (list) => `[${list.map(dartNumber).join(", ")}]`;
const dartStrings = (list) => `[${list.map(dartString).join(", ")}]`;

// ---------------------------------------------------------------------------
// The channels of a color object of each space.

function spaceOf(c) {
  if (c instanceof d3.rgb) return "rgb";
  if (c instanceof d3.hsl) return "hsl";
  if (c instanceof d3.lab) return "lab";
  if (c instanceof d3.hcl) return "hcl";
  if (c instanceof d3.cubehelix) return "cubehelix";
  throw new Error(`no space for ${c}`);
}

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

const formatsOf = (c) => [
  c.formatHex(),
  c.formatHex8(),
  c.formatRgb(),
  c.formatHsl(),
  c.toString(),
];

// ---------------------------------------------------------------------------
// a) CSS texts.

const texts = [];
const addText = (s) => texts.push(s);

for (const name of names) addText(name);
for (const name of ["red", "steelblue", "rebeccapurple", "aliceblue"]) {
  addText(name.toUpperCase());
  addText(name[0].toUpperCase() + name.slice(1));
  addText(`  ${name}\t`);
}
addText("transparent");
addText("TRANSPARENT");
addText(" Transparent\n");

const hexDigits = "0123456789abcdef";
const hex = (n) => Array.from({length: n}, () => pick(hexDigits)).join("");
for (const digits of [3, 4, 6, 8]) {
  for (let i = 0; i < 15; ++i) addText(`#${hex(digits)}`);
  addText(`#${hex(digits).toUpperCase()}`);
  addText(` #${hex(digits)} `);
}
for (const s of [
  "#",
  "#f",
  "#ff",
  "#fffff",
  "#1234567",
  "#123456789",
  "#ggg",
  "#12345g",
  "##fff",
  "fff",
  "#ff 00 00",
  "# fff",
  "#000",
  "#fff",
  "#0000",
  "#ffff",
  "#00000000",
  "#ffffffff",
  "#ff000080",
  "#f008",
]) {
  addText(s);
}

const space = () => pick(["", "", "", " ", "  ", "\t", "\n"]);

/// A number text of the CSS patterns of color.js: a sign, digits, a leading
/// dot, a fraction and an exponent.
function numberText(lo, hi, {integerOnly = false} = {}) {
  const x = uniform(lo, hi);
  if (integerOnly) {
    const v = Math.round(x);
    const sign = v < 0 ? "-" : random() < 0.1 ? "+" : "";
    return sign + String(Math.abs(v));
  }
  const sign = x < 0 ? "-" : random() < 0.1 ? "+" : "";
  const ax = Math.abs(x);
  switch (integer(0, 5)) {
    case 0:
      return sign + String(Math.round(ax));
    case 1:
      return sign + ax.toFixed(integer(1, 4));
    case 2: {
      // A leading dot.
      const f = ax.toFixed(integer(1, 3));
      return sign + (f.startsWith("0.") ? f.slice(1) : f);
    }
    case 3: {
      // An exponent.
      const [m, e] = ax.toExponential(integer(0, 3)).split("e");
      const exponent = Number(e);
      return `${sign}${m}${pick(["e", "E"])}${exponent < 0 ? "-" : pick(["", "+"])}${Math.abs(exponent)}`;
    }
    case 4:
      return sign + String(ax);
    default:
      return sign + ax.toFixed(2).replace(/^0\./, ".");
  }
}

const n = (...args) => space() + numberText(...args) + space();
const p = (lo, hi) => space() + numberText(lo, hi) + "%" + space();

for (let i = 0; i < 30; ++i) {
  addText(
    `rgb(${n(-50, 300, {integerOnly: true})},${n(-50, 300, {integerOnly: true})},${n(-50, 300, {integerOnly: true})})`,
  );
}
for (let i = 0; i < 20; ++i) {
  addText(`rgb(${p(-10, 110)},${p(-10, 110)},${p(-10, 110)})`);
}
for (let i = 0; i < 20; ++i) {
  addText(
    `rgba(${n(0, 255, {integerOnly: true})},${n(0, 255, {integerOnly: true})},${n(0, 255, {integerOnly: true})},${n(-0.3, 1.3)})`,
  );
}
for (let i = 0; i < 15; ++i) {
  addText(`rgba(${p(0, 100)},${p(0, 100)},${p(0, 100)},${n(-0.3, 1.3)})`);
}
for (let i = 0; i < 25; ++i) {
  addText(`hsl(${n(-400, 800)},${p(-10, 110)},${p(-10, 110)})`);
}
for (let i = 0; i < 20; ++i) {
  addText(`hsla(${n(-400, 800)},${p(-10, 110)},${p(-10, 110)},${n(-0.3, 1.3)})`);
}
for (let i = 0; i < 6; ++i) {
  addText(`RGB(${n(0, 255, {integerOnly: true})}, ${n(0, 255, {integerOnly: true})}, ${n(0, 255, {integerOnly: true})})`);
  addText(`HsLa(${n(0, 360)}, ${p(0, 100)}, ${p(0, 100)}, ${n(0, 1)})`);
}

// Fixed texts: the edges of the patterns and of the number texts.
for (const s of [
  "rgb(255,255,255)",
  "rgb(0, 0, 0)",
  "rgb(-0,0,0)",
  "rgb(+1,-2,3)",
  "rgb(00255,0,0)",
  "rgb(999999999999999999999,0,0)",
  "rgb(256,-1,128)",
  "rgb(100%,0%,0%)",
  "rgb(1e2%,0%,0%)",
  "rgb(.5%,50.%,5e-1%)",
  "rgb(1e400%,0%,0%)",
  "rgb(12.5%, 37.5%, 62.5%)",
  "rgba(0,0,0,0)",
  "rgba(1,2,3,-0)",
  "rgba(1,2,3,-0.0)",
  "rgba(1,2,3,1e-7)",
  "rgba(1,2,3,.5)",
  "rgba(1,2,3,1)",
  "rgba(1,2,3,1.0000000000000002)",
  "rgba(1,2,3,1e400)",
  "rgba(1,2,3,-1e400)",
  "rgba(1,2,3,0.30000000000000004)",
  "rgba(10%,20%,30%,0.4)",
  "hsl(120,50%,50%)",
  "hsl(120,0%,50%)",
  "hsl(120,50%,0%)",
  "hsl(120,50%,100%)",
  "hsl(120,-0%,50%)",
  "hsl(-120,50%,50%)",
  "hsl(1e3,50%,50%)",
  "hsl(.5e1,5e1%,5E1%)",
  "hsl(+120,+50%,+50%)",
  "hsl(120.000000000000000001,50%,50%)",
  "hsl(1e400,50%,50%)",
  "hsl(-1e400,50%,50%)",
  "hsl(360,100%,50%)",
  "hsl(720,100%,50%)",
  "hsl(-360,100%,50%)",
  "hsl(0.1,33.333333333333336%,66.66666666666667%)",
  "hsla(120,50%,50%,0)",
  "hsla(120,50%,50%,1)",
  "hsla(120,50%,50%,0.5)",
  "hsla(120,50%,50%,-0.5)",
  "hsla(120,50%,50%,1.5)",
  "hsla(120,50%,50%,1e-7)",
  "rgb( 1 , 2 , 3 )",
  "rgba(\t1\t,\n2\n,\t3,\t.25 )",
  "hsl( 120 , 50% , 50% )",
  // Not CSS colors of d3-color.
  "rgb(120.,30,50)",
  "rgb(120.5,30,50)",
  "rgb(1e2,2,3)",
  "rgb (1,2,3)",
  "rgb(1 %,2%,3%)",
  "rgb(1%,2,3)",
  "rgb(1,2)",
  "rgb(1,2,3,4)",
  "rgb(1,2,3",
  "rgb()",
  "rgb(,,)",
  "rgb(1,2,3)x",
  "rgba(1,2,3)",
  "rgba(1,2,3,)",
  "rgba(1,2,3,50%)",
  "hsl(1,2,3)",
  "hsl(1%,2%,3%)",
  "hsl(120deg,50%,50%)",
  "hsla(120,50%,50%)",
  "hsl(120,50%,50%,1)",
  "hsl(.,50%,50%)",
  "hsl(1.e2,50%,50%)",
  "hsl(1e,50%,50%)",
  "hsl(e2,50%,50%)",
  "rgb(--1,2,3)",
  "rgb(+-1,2,3)",
  "notacolor",
  "redd",
  "red red",
  "re d",
  "hasOwnProperty",
  "__proto__",
  "constructor",
  "toString",
  "valueOf",
  "isPrototypeOf",
  "",
  " ",
  "\t\n",
  // White space and case of JavaScript String.prototype.trim and
  // toLowerCase.
  " red ",
  "﻿red",
  " red ",
  "　red",
  "\u000bred\u000c",
  " red ",
  " red ",
  "\u0085red",
  "red\u0085",
  "᠎red",
  "​red",
  "blacK",
  "İndigo",
  "WHİTE",
  "rgb( 1,2,3)",
  "rgb(1 ,2,3)",
  "rgb(1\u0085,2,3)",
  "rgb(١,2,3)",
]) {
  addText(s);
}

// Each text once, in the order of its first occurrence.
const parseCases = [...new Set(texts)].map((input) => {
  const c = d3.color(input);
  return {
    input,
    space: c === null ? null : spaceOf(c),
    channels: c === null ? [] : channelsOf(c),
    rgb: channelsOf(d3.rgb(input)),
    hsl: channelsOf(d3.hsl(input)),
    formats: c === null ? [] : formatsOf(c),
    displayable: c === null ? false : c.displayable(),
  };
});

// ---------------------------------------------------------------------------
// b) Colors with numeric channels.

const KS = [undefined, 0.5, 1, 2, -1.5];

/// A channel: mostly in [lo, hi], sometimes outside, NaN, -0 or infinite.
function channel(lo, hi) {
  const u = random();
  if (u < 0.05) return NaN;
  if (u < 0.07) return -0;
  if (u < 0.08) return pick([Infinity, -Infinity]);
  if (u < 0.2) return uniform(lo - (hi - lo) / 4, hi + (hi - lo) / 4);
  if (u < 0.3) return Math.round(uniform(lo, hi));
  return uniform(lo, hi);
}

function opacity() {
  const u = random();
  if (u < 0.35) return 1;
  if (u < 0.4) return 0;
  if (u < 0.45) return NaN;
  if (u < 0.55) return uniform(-0.5, 1.5);
  if (u < 0.57) return -0;
  return random();
}

const numericColors = [];
const makers = {
  rgb: (x, y, z, o) => d3.rgb(x, y, z, o),
  hsl: (x, y, z, o) => d3.hsl(x, y, z, o),
  lab: (x, y, z, o) => d3.lab(x, y, z, o),
  hcl: (x, y, z, o) => d3.hcl(x, y, z, o),
  cubehelix: (x, y, z, o) => d3.cubehelix(x, y, z, o),
};
const ranges = {
  rgb: [
    [0, 255],
    [0, 255],
    [0, 255],
  ],
  hsl: [
    [-720, 720],
    [0, 1],
    [0, 1],
  ],
  lab: [
    [0, 100],
    [-128, 128],
    [-128, 128],
  ],
  hcl: [
    [-360, 720],
    [0, 150],
    [0, 100],
  ],
  cubehelix: [
    [-360, 720],
    [0, 4],
    [0, 1],
  ],
};
for (const space of Object.keys(makers)) {
  const [r0, r1, r2] = ranges[space];
  for (let i = 0; i < 52; ++i) {
    numericColors.push([
      space,
      channel(...r0),
      channel(...r1),
      channel(...r2),
      opacity(),
    ]);
  }
}
// Fixed colors: the edges of displayable, of the rounding of clampi, of the
// hue branches of hslConvert and Hsl.rgb, and of the gray paths.
for (const c of [
  ["rgb", -0.5, 255.5, 255.49999999999997, 1],
  ["rgb", -0.5000000000000001, 0, 0, 1],
  ["rgb", 0, 255.5, 0, 1],
  ["rgb", 0.5, 1.5, 2.5, 0.5],
  ["rgb", 254.5, -0.4, -0.6, 1],
  ["rgb", 0.49999999999999994, 127.5, 128.5, 1],
  ["rgb", 255, 255, 255, 1],
  ["rgb", 0, 0, 0, 1],
  ["rgb", 128, 128, 128, 1],
  ["rgb", 255, 0, 0, 1],
  ["rgb", 255, 255, 0, 1],
  ["rgb", 0, 255, 255, 1],
  ["rgb", 0, 0, 255, 1],
  ["rgb", 255, 0, 255, 1],
  ["rgb", 10, 20, 20, 1],
  ["rgb", 20, 20, 10, 1],
  ["rgb", 20, 10, 20, 1],
  ["rgb", 300, 400, -100, 1],
  ["rgb", 70, 130, 180, 1.0000000000000002],
  ["rgb", 70, 130, 180, -1e-300],
  ["rgb", 70, 130, 180, 0.30000000000000004],
  ["rgb", NaN, NaN, NaN, 0],
  ["rgb", NaN, 128, 64, 1],
  ["hsl", 120, 0.5, 0.5, 1],
  ["hsl", -0, 0, 0.5, 1],
  ["hsl", 360, 1, 0.5, 1],
  ["hsl", -360, 1, 0.5, 1],
  ["hsl", -1e-20, 1, 0.5, 1],
  ["hsl", 1e20 + 0.5, 1, 0.5, 1],
  ["hsl", 1e300, 1, 0.5, 1],
  ["hsl", 123456789.123, 0.25, 0.75, 1],
  ["hsl", 60, 1, 0.5, 1],
  ["hsl", 180, 1, 0.5, 1],
  ["hsl", 240, 1, 0.5, 1],
  ["hsl", 300, 1, 0.5, 1],
  ["hsl", NaN, 0.5, 0.5, 1],
  ["hsl", 120, NaN, 0.5, 1],
  ["hsl", 120, 0.5, NaN, 1],
  ["hsl", 120, 1.5, -0.25, 1],
  ["hsl", 120, 0.5, 1e-9, 1e-7],
  ["hsl", Infinity, 0.5, 0.5, 1],
  ["lab", 50, 0, 0, 1],
  ["lab", 0, 0, 0, 1],
  ["lab", 100, 0, 0, 1],
  ["lab", 50, NaN, NaN, 1],
  ["lab", 53.24079414130722, 80.09245959641109, 67.20319651585301, 1],
  ["lab", 120, 0, 0, 0.5],
  ["hcl", NaN, 0, 50, 1],
  ["hcl", 40, 0, 50, 1],
  ["hcl", 40, 100, 0, 1],
  ["hcl", -40, 60, 50, 1],
  ["hcl", 400, 60, 50, 1],
  ["hcl", NaN, NaN, NaN, NaN],
  ["cubehelix", 300, 0.5, 0, 1],
  ["cubehelix", 300, 0.5, 1, 1],
  ["cubehelix", NaN, 0.5, 0.5, 1],
  ["cubehelix", 300, NaN, 0.5, 1],
  ["cubehelix", -100, 1.5, 0.8, 1],
]) {
  numericColors.push(c);
}

const colorCases = numericColors.map(([space, x, y, z, o]) => {
  const c = makers[space](x, y, z, o);
  const result = {
    space,
    channels: [x, y, z, o],
    rgb: channelsOf(d3.rgb(c)),
    hsl: channelsOf(d3.hsl(c)),
    lab: channelsOf(d3.lab(c)),
    hcl: channelsOf(d3.hcl(c)),
    cubehelix: channelsOf(d3.cubehelix(c)),
    brighter: KS.map((k) => channelsOf(c.brighter(k))),
    darker: KS.map((k) => channelsOf(c.darker(k))),
    clamp: space === "rgb" || space === "hsl" ? channelsOf(c.clamp()) : null,
    displayable: c.displayable(),
    formats: formatsOf(c),
  };
  // The factory keeps the channels as given.
  const own = channelsOf(c);
  for (let i = 0; i < 4; ++i) {
    if (!Object.is(own[i], [x, y, z, o][i])) {
      throw new Error(`${space}(${x}, ${y}, ${z}, ${o}) changed channel ${i}`);
    }
  }
  return result;
});

// ---------------------------------------------------------------------------
// c) The number text of the CSS formats.

const unitNumbers = [];
const degreeNumbers = [];
for (let i = 0; i < 500; ++i) unitNumbers.push(random());
for (let i = 0; i < 500; ++i) degreeNumbers.push(random() * 360);
const specials = [
  0,
  -0,
  1e-7,
  1.5e-7,
  9.999999999999999e-7,
  1e-6,
  1.0000000000000002e-6,
  5e-324,
  2.2250738585072014e-308,
  1e-300,
  0.1 + 0.2,
  0.1,
  0.5,
  1 / 3,
  2 / 3,
  0.9999999999999999,
  1 - 1e-7,
  123e-20,
  0.000123,
  0.0001,
  0.001,
];
const degreeSpecials = [
  ...specials,
  1,
  59.99999999999999,
  120,
  123.456,
  179.99999999999997,
  359.99999999999994,
  100 / 3,
  1e-5 * 360,
  12345e-3,
];
const numberCases = [];
for (let i = 0; i < 500; ++i) {
  numberCases.push([degreeNumbers[i], unitNumbers[i]]);
}
for (let i = 0; i < degreeSpecials.length; ++i) {
  numberCases.push([degreeSpecials[i], specials[i % specials.length]]);
}
for (let i = 0; i < specials.length; ++i) {
  numberCases.push([degreeSpecials[degreeSpecials.length - 1 - i], specials[i]]);
}
const numberTexts = numberCases.map(([h, a]) => {
  const text = d3.hsl(h, 0.5, 0.5, a).formatHsl();
  // The format prints h and the opacity as they are: h is in [0, 360) and the
  // opacity in [0, 1). A whole opacity 0 prints as "0".
  const expected = `hsla(${String(h)}, 50%, 50%, ${String(a)})`;
  if (text !== expected) {
    throw new Error(`formatHsl does not print the input: ${text} ${expected}`);
  }
  return {h, opacity: a, hText: String(h), opacityText: String(a), text};
});

// ---------------------------------------------------------------------------
// The Dart file.

const v8 = process.versions.v8;
const lines = [];
const out = (s = "") => lines.push(s);

out(
  "// Original code, not ported from d3-color: generated data, do not edit.",
  "// tool/reference/d3_color_reference.mjs writes this file.",
);
out(`// Node.js ${process.version} (${process.arch}), V8 ${v8}.`);
out(`// d3-color v3.1.0 src/ at ${pinned}.`);
out(
  `// ${parseCases.length} CSS texts, ${colorCases.length} numeric colors, ${numberTexts.length} number texts.`,
);
out("// The data has long string literals.");
out("// ignore_for_file: lines_longer_than_80_chars");
out();
out("/// The reference data of the d3-color port: upstream d3-color in Node.js.");
out("library;");
out();
out("/// The Node.js version that generated the data.");
out(`const String d3ColorReferenceNode = ${dartString(process.version)};`);
out();
out("/// The V8 version of the Node.js build that generated the data.");
out(`const String d3ColorReferenceV8 = ${dartString(v8)};`);
out();
out("/// The architecture of the Node.js build that generated the data.");
out(`const String d3ColorReferenceArch = ${dartString(process.arch)};`);
out();
out("/// One CSS text and its results in Node.js.");
out("typedef ParseCase = ({");
out("  /// The CSS text.");
out("  String input,");
out();
out("  /// The class of `color(input)`: `'rgb'`, `'hsl'`, or null when");
out("  /// `color(input)` is null.");
out("  String? space,");
out();
out("  /// The channels of `color(input)`: r, g, b and opacity, or h, s, l and");
out("  /// opacity. Empty when `color(input)` is null.");
out("  List<double> channels,");
out();
out("  /// The channels of `rgb(input)`.");
out("  List<double> rgb,");
out();
out("  /// The channels of `hsl(input)`.");
out("  List<double> hsl,");
out();
out("  /// `formatHex()`, `formatHex8()`, `formatRgb()`, `formatHsl()` and");
out("  /// `toString()` of `color(input)`. Empty when `color(input)` is null.");
out("  List<String> formats,");
out();
out("  /// `displayable()` of `color(input)`. False when `color(input)` is null.");
out("  bool displayable,");
out("});");
out();
out("/// One color with numeric channels and its results in Node.js.");
out("typedef ColorCase = ({");
out("  /// The space of the color: `'rgb'`, `'hsl'`, `'lab'`, `'hcl'` or");
out("  /// `'cubehelix'`.");
out("  String space,");
out();
out("  /// The three channels and the opacity of the factory call, for example");
out("  /// `hcl(h, c, l, opacity)`.");
out("  List<double> channels,");
out();
out("  /// The channels of `rgb(color)`.");
out("  List<double> rgb,");
out();
out("  /// The channels of `hsl(color)`.");
out("  List<double> hsl,");
out();
out("  /// The channels of `lab(color)`.");
out("  List<double> lab,");
out();
out("  /// The channels of `hcl(color)`.");
out("  List<double> hcl,");
out();
out("  /// The channels of `cubehelix(color)`.");
out("  List<double> cubehelix,");
out();
out("  /// The channels of `brighter()`, `brighter(0.5)`, `brighter(1)`,");
out("  /// `brighter(2)` and `brighter(-1.5)`, in the space of the color.");
out("  List<List<double>> brighter,");
out();
out("  /// The channels of `darker(k)` for the same k.");
out("  List<List<double>> darker,");
out();
out("  /// The channels of `clamp()` of an rgb or hsl color, else null.");
out("  List<double>? clamp,");
out();
out("  /// `displayable()`.");
out("  bool displayable,");
out();
out("  /// `formatHex()`, `formatHex8()`, `formatRgb()`, `formatHsl()` and");
out("  /// `toString()`.");
out("  List<String> formats,");
out("});");
out();
out("/// One hue and one opacity, their JavaScript `String(x)`, and the text of");
out("/// `hsl(h, 0.5, 0.5, opacity).formatHsl()` in Node.js.");
out("typedef NumberTextCase = ({");
out("  /// The hue, in [0, 360).");
out("  double h,");
out();
out("  /// The opacity, in [0, 1).");
out("  double opacity,");
out();
out("  /// `String(h)`.");
out("  String hText,");
out();
out("  /// `String(opacity)`.");
out("  String opacityText,");
out();
out("  /// `hsl(h, 0.5, 0.5, opacity).formatHsl()`.");
out("  String text,");
out("});");
out();
out("/// a) The CSS texts.");
out("const List<ParseCase> parseCases = [");
for (const c of parseCases) {
  out(
    `  (input: ${dartString(c.input)}, space: ${c.space === null ? "null" : dartString(c.space)}, ` +
      `channels: ${dartNumbers(c.channels)}, rgb: ${dartNumbers(c.rgb)}, hsl: ${dartNumbers(c.hsl)}, ` +
      `formats: ${dartStrings(c.formats)}, displayable: ${c.displayable}),`,
  );
}
out("];");
out();
out("/// b) The colors with numeric channels.");
out("const List<ColorCase> colorCases = [");
for (const c of colorCases) {
  out(
    `  (space: ${dartString(c.space)}, channels: ${dartNumbers(c.channels)}, ` +
      `rgb: ${dartNumbers(c.rgb)}, hsl: ${dartNumbers(c.hsl)}, lab: ${dartNumbers(c.lab)}, ` +
      `hcl: ${dartNumbers(c.hcl)}, cubehelix: ${dartNumbers(c.cubehelix)}, ` +
      `brighter: [${c.brighter.map(dartNumbers).join(", ")}], ` +
      `darker: [${c.darker.map(dartNumbers).join(", ")}], ` +
      `clamp: ${c.clamp === null ? "null" : dartNumbers(c.clamp)}, ` +
      `displayable: ${c.displayable}, formats: ${dartStrings(c.formats)}),`,
  );
}
out("];");
out();
out("/// c) The number texts.");
out("const List<NumberTextCase> numberTextCases = [");
for (const c of numberTexts) {
  out(
    `  (h: ${dartNumber(c.h)}, opacity: ${dartNumber(c.opacity)}, ` +
      `hText: ${dartString(c.hText)}, opacityText: ${dartString(c.opacityText)}, ` +
      `text: ${dartString(c.text)}),`,
  );
}
out("];");

mkdirSync(path.dirname(output), {recursive: true});
writeFileSync(output, lines.join("\n") + "\n");
console.log(
  `Wrote ${path.relative(packageRoot, output)}: ${parseCases.length} CSS texts, ` +
    `${colorCases.length} numeric colors, ${numberTexts.length} number texts. ` +
    "Run dart format on it.",
);
