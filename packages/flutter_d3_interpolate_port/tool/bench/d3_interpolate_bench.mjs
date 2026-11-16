// Original code, not ported from d3-interpolate: the benchmark of upstream in Node.js.
//
// The cases and the inputs of d3_interpolate_bench.dart, on the pinned
// upstream source third_party/d3-interpolate/src (or the folder of the env
// D3_INTERPOLATE_SRC), with third_party/d3-color/src for the bare specifier
// "d3-color". Each case prints one line `BENCH {json}` with the median time
// of one operation in nanoseconds. The arguments are those of the Dart file.
//
// A color interpolator of upstream returns the CSS text: the cases `call.*`
// and `text.*` of a color both time that call. The transform cases use
// interpolateTransformCss with a small DOMMatrix of the text `matrix(...)`,
// because Node.js has no DOMMatrix: the parse runs only at the creation.

import {performance} from "node:perf_hooks";
import {registerHooks} from "node:module";
import {fileURLToPath, pathToFileURL} from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");
const src = process.env.D3_INTERPOLATE_SRC
  ?? path.join(repo, "third_party/d3-interpolate/src");
const colorUrl = pathToFileURL(path.join(repo, "third_party/d3-color/src/index.js")).href;
registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "d3-color") return {url: colorUrl, shortCircuit: true};
    return nextResolve(specifier, context);
  },
});
const d3 = await import(pathToFileURL(path.join(src, "index.js")).href);
const d3color = await import(colorUrl);
const {default: decompose} = await import(pathToFileURL(path.join(src, "transform/decompose.js")).href);

globalThis.DOMMatrix = class {
  constructor(text) {
    const [a, b, c, d, e, f] = /matrix\(([^)]*)\)/.exec(text)[1].split(",").map(Number);
    Object.assign(this, {a, b, c, d, e, f});
    this.isIdentity = a === 1 && b === 0 && c === 0 && d === 1 && e === 0 && f === 0;
  }
};

class Lcg {
  constructor(seed) { this.seed = seed; }
  next(n) {
    this.seed = this.seed * 48271 % 2147483647;
    return this.seed % n;
  }
}

const POOL = 1024;
const M = POOL - 1;

function matrix(r) {
  return [
    r.next(200) / 100 + 0.5,
    r.next(200) / 100 - 1,
    r.next(200) / 100 - 1,
    r.next(200) / 100 + 0.5,
    r.next(20000) / 100 - 100,
    r.next(20000) / 100 - 100,
  ];
}

function inputs() {
  const r = new Lcg(42);
  const number = () => r.next(200000) / 100 - 1000;
  const rgb = () => d3color.rgb(r.next(256), r.next(256), r.next(256));
  const values = (n) => { const v = []; for (let k = 0; k < n; k++) v.push(r.next(10000) / 100); return v; };
  const p = {ts: [], numbersA: [], numbersB: [], huesA: [], huesB: [], basis: [], datesA: [], datesB: [],
    arraysA: [], arraysB: [], colorsA: [], colorsB: [], palettes: [], zoomsA: [], zoomsB: [],
    matricesA: [], matricesB: []};
  for (let i = 0; i < POOL; i++) {
    p.ts.push(r.next(1001) / 1000);
    p.numbersA.push(number());
    p.numbersB.push(number());
    p.huesA.push(r.next(72000) / 100 - 360);
    p.huesB.push(r.next(72000) / 100 - 360);
    p.basis.push(values(8));
    p.datesA.push(946684800000 + r.next(2000000000) * 100);
    p.datesB.push(946684800000 + r.next(2000000000) * 100);
    p.arraysA.push(values(16));
    p.arraysB.push(values(16));
    p.colorsA.push(rgb());
    p.colorsB.push(rgb());
    const palette = [];
    for (let k = 0; k < 8; k++) palette.push(rgb());
    p.palettes.push(palette);
    p.zoomsA.push([r.next(1000), r.next(1000), r.next(1000) + 1]);
    p.zoomsB.push([r.next(1000), r.next(1000), r.next(1000) + 1]);
    p.matricesA.push(matrix(r));
    p.matricesB.push(matrix(r));
  }
  return p;
}

let sink = 0;
const css = (m) => `matrix(${m.join(", ")})`;

function cases(p) {
  const make = (f) => { const a = []; for (let i = 0; i < POOL; i++) a.push(f(i)); return a; };
  const t = (i) => p.ts[(i * 7) & M];
  const number = make((i) => d3.interpolateNumber(p.numbersA[i], p.numbersB[i]));
  const round = make((i) => d3.interpolateRound(p.numbersA[i], p.numbersB[i]));
  const hue = make((i) => d3.interpolateHue(p.huesA[i], p.huesB[i]));
  const basis = make((i) => d3.interpolateBasis(p.basis[i]));
  const basisClosed = make((i) => d3.interpolateBasisClosed(p.basis[i]));
  const discrete = make((i) => d3.interpolateDiscrete(p.basis[i]));
  const date = make((i) => d3.interpolateDate(new Date(p.datesA[i]), new Date(p.datesB[i])));
  const numberArray = make((i) => d3.interpolateNumberArray(Float64Array.from(p.arraysA[i]), Float64Array.from(p.arraysB[i])));
  const array = make((i) => d3.interpolateArray(p.arraysA[i], p.arraysB[i]));
  const rgb = make((i) => d3.interpolateRgb(p.colorsA[i], p.colorsB[i]));
  const rgbGamma = make((i) => d3.interpolateRgb.gamma(2.2)(p.colorsA[i], p.colorsB[i]));
  const rgbBasis = make((i) => d3.interpolateRgbBasis(p.palettes[i]));
  const hsl = make((i) => d3.interpolateHsl(p.colorsA[i], p.colorsB[i]));
  const hslLong = make((i) => d3.interpolateHslLong(p.colorsA[i], p.colorsB[i]));
  const lab = make((i) => d3.interpolateLab(p.colorsA[i], p.colorsB[i]));
  const hcl = make((i) => d3.interpolateHcl(p.colorsA[i], p.colorsB[i]));
  const hclLong = make((i) => d3.interpolateHclLong(p.colorsA[i], p.colorsB[i]));
  const cubehelix = make((i) => d3.interpolateCubehelix(p.colorsA[i], p.colorsB[i]));
  const cubehelixGamma = make((i) => d3.interpolateCubehelixLong.gamma(3)(p.colorsA[i], p.colorsB[i]));
  const piecewiseRgb = make((i) => d3.piecewise(d3.interpolateRgb, p.palettes[i].slice(0, 4)));
  const zoom = make((i) => d3.interpolateZoom(p.zoomsA[i], p.zoomsB[i]));
  const transform = make((i) => d3.interpolateTransformCss(css(p.matricesA[i]), css(p.matricesB[i])));
  const textsA = make((i) => css(p.matricesA[i]));
  const textsB = make((i) => css(p.matricesB[i]));
  const decomp = (m) => decompose(m[0], m[1], m[2], m[3], m[4], m[5]);

  return [
    ["call.number", (i) => sink += number[i & M](t(i))],
    ["call.round", (i) => sink += round[i & M](t(i))],
    ["call.hue", (i) => sink += hue[i & M](t(i))],
    ["call.basis", (i) => sink += basis[i & M](t(i))],
    ["call.basisClosed", (i) => sink += basisClosed[i & M](t(i))],
    ["call.discrete", (i) => sink += discrete[i & M](t(i))],
    ["call.date", (i) => sink += date[i & M](t(i)).getTime()],
    ["call.numberArray", (i) => sink += numberArray[i & M](t(i))[3]],
    ["call.array", (i) => sink += array[i & M](t(i))[3]],
    ["call.rgb", (i) => sink += rgb[i & M](t(i)).length],
    ["call.rgbGamma", (i) => sink += rgbGamma[i & M](t(i)).length],
    ["call.rgbBasis", (i) => sink += rgbBasis[i & M](t(i)).length],
    ["call.hsl", (i) => sink += hsl[i & M](t(i)).length],
    ["call.hslLong", (i) => sink += hslLong[i & M](t(i)).length],
    ["call.lab", (i) => sink += lab[i & M](t(i)).length],
    ["call.hcl", (i) => sink += hcl[i & M](t(i)).length],
    ["call.hclLong", (i) => sink += hclLong[i & M](t(i)).length],
    ["call.cubehelix", (i) => sink += cubehelix[i & M](t(i)).length],
    ["call.cubehelixGamma", (i) => sink += cubehelixGamma[i & M](t(i)).length],
    ["call.piecewise", (i) => sink += piecewiseRgb[i & M](t(i)).length],
    ["call.zoom", (i) => sink += zoom[i & M](t(i))[2]],
    ["call.transform", (i) => sink += transform[i & M](t(i)).length],
    ["text.rgb", (i) => sink += rgb[i & M](t(i)).length],
    ["text.hsl", (i) => sink += hsl[i & M](t(i)).length],
    ["text.lab", (i) => sink += lab[i & M](t(i)).length],
    ["text.hcl", (i) => sink += hcl[i & M](t(i)).length],
    ["text.cubehelix", (i) => sink += cubehelix[i & M](t(i)).length],
    ["create.number", (i) => sink += d3.interpolateNumber(p.numbersA[i & M], p.numbersB[i & M])(0.5)],
    ["create.rgb", (i) => sink += d3.interpolateRgb(p.colorsA[i & M], p.colorsB[i & M])(0.5).length],
    ["create.hcl", (i) => sink += d3.interpolateHcl(p.colorsA[i & M], p.colorsB[i & M])(0.5).length],
    ["create.valueNumber", (i) => sink += d3.interpolate(p.numbersA[i & M], p.numbersB[i & M])(0.5)],
    ["create.valueColor", (i) => sink += d3.interpolate(p.colorsA[i & M], p.colorsB[i & M])(0.5).length],
    ["create.valueArray", (i) => sink += d3.interpolate(p.arraysA[i & M], p.arraysB[i & M])(0.5)[3]],
    ["create.zoom", (i) => sink += d3.interpolateZoom(p.zoomsA[i & M], p.zoomsB[i & M])(0.5)[2]],
    ["create.transform", (i) => sink += d3.interpolateTransformCss(textsA[i & M], textsB[i & M])(0.5).length],
    ["decompose", (i) => sink += decomp(p.matricesA[i & M]).rotate],
    ["quantize.rgb", (i) => sink += d3.quantize(d3.interpolateRgb(p.colorsA[i & M], p.colorsB[i & M]), 8).length],
  ];
}

let filter = null, batches = 9, batchMs = 60, warmMs = 300, target = "node";
for (const arg of process.argv.slice(2)) {
  const [key, value = ""] = arg.split("=");
  if (key === "--filter") filter = value;
  else if (key === "--batches") batches = +value;
  else if (key === "--batch-ms") batchMs = +value;
  else if (key === "--warm-ms") warmMs = +value;
  else if (key === "--target") target = value;
}

const p = inputs();
const now = () => performance.now() * 1000; // microseconds
for (const [name, run] of cases(p)) {
  if (filter != null && !name.includes(filter)) continue;
  let ops = 64, i = 0;
  const warmEnd = now() + warmMs * 1000;
  while (now() < warmEnd) {
    const start = now();
    for (let k = 0; k < ops; k++) run(i++);
    if (now() - start < batchMs * 1000 / 4) ops *= 2;
  }
  const perOp = [];
  for (let b = 0; b < batches; b++) {
    const start = now();
    for (let k = 0; k < ops; k++) run(i++);
    perOp.push((now() - start) * 1000 / ops);
  }
  perOp.sort((a, b) => a - b);
  const median = perOp[perOp.length >> 1];
  console.log(`BENCH {"target":"${target}","case":"${name}","nsPerOp":${median.toFixed(2)},"ops":${ops},"batches":[${perOp.map((v) => v.toFixed(2)).join(",")}]}`);
}
console.log(`SINK ${sink}`);
