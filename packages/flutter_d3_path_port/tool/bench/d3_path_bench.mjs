// Original code, not ported from d3-path: upstream Node.js benchmark.

import {performance} from "node:perf_hooks";
import {fileURLToPath, pathToFileURL} from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");
const d3PathUrl = pathToFileURL(
  path.join(repo, "third_party/d3-path/src/index.js"),
).href;
const {path: d3Path, pathRound} = await import(d3PathUrl);

class Lcg {
  constructor(seed) { this.seed = seed; }
  next(n) {
    this.seed = (this.seed * 48271) % 2147483647;
    return this.seed % n;
  }
  nextDouble() {
    this.seed = (this.seed * 48271) % 2147483647;
    return this.seed / 2147483647.0;
  }
}

const POOL = 256;
const M = POOL - 1;

const r = new Lcg(42);
const xs = new Float64Array(POOL);
const ys = new Float64Array(POOL);
const ixs = new Float64Array(POOL);
const iys = new Float64Array(POOL);
const radii = new Float64Array(POOL);
const a0s = new Float64Array(POOL);
const a1s = new Float64Array(POOL);
const ccws = new Uint8Array(POOL);

for (let i = 0; i < POOL; i++) {
  xs[i] = r.nextDouble() * 1000.0 - 200.0;
  ys[i] = r.nextDouble() * 600.0 - 100.0;
  ixs[i] = r.next(1000) - 200;
  iys[i] = r.next(600) - 100;
  radii[i] = 5.0 + r.nextDouble() * 95.0;
  a0s[i] = (r.nextDouble() * 2.0 - 1.0) * Math.PI;
  a1s[i] = a0s[i] + r.nextDouble() * 2.2 * Math.PI;
  ccws[i] = r.next(2);
}

let sink = 0;
const eatText = (s) => s.length + s.charCodeAt(s.length - 1);

function buildPolyline(p, px, py, start) {
  p.moveTo(px[start & M], py[start & M]);
  for (let j = 1; j < 100; j++) {
    const k = (start + j) & M;
    p.lineTo(px[k], py[k]);
  }
  return p.toString();
}

function buildBezier(p, start) {
  p.moveTo(xs[start & M], ys[start & M]);
  for (let j = 0; j < 50; j++) {
    const k0 = (start + j * 3) & M;
    const k1 = (start + j * 3 + 1) & M;
    const k2 = (start + j * 3 + 2) & M;
    p.bezierCurveTo(xs[k0], ys[k0], xs[k1], ys[k1], xs[k2], ys[k2]);
  }
  return p.toString();
}

function buildQuad(p, start) {
  p.moveTo(xs[start & M], ys[start & M]);
  for (let j = 0; j < 50; j++) {
    const k0 = (start + j * 2) & M;
    const k1 = (start + j * 2 + 1) & M;
    p.quadraticCurveTo(xs[k0], ys[k0], xs[k1], ys[k1]);
  }
  return p.toString();
}

function buildArcs(p, start) {
  for (let j = 0; j < 20; j++) {
    const k = (start + j) & M;
    p.arc(xs[k], ys[k], radii[k], a0s[k], a1s[k], ccws[k] !== 0);
  }
  return p.toString();
}

function buildArcTo(p, start) {
  p.moveTo(xs[start & M], ys[start & M]);
  for (let j = 0; j < 20; j++) {
    const k0 = (start + j * 2) & M;
    const k1 = (start + j * 2 + 1) & M;
    p.arcTo(xs[k0], ys[k0], xs[k1], ys[k1], radii[k0]);
  }
  return p.toString();
}

function buildRects(p, start) {
  for (let j = 0; j < 50; j++) {
    const k = (start + j) & M;
    p.rect(xs[k], ys[k], radii[k], radii[(k + 1) & M]);
  }
  return p.toString();
}

function buildMixed(p, start) {
  const k0 = start & M;
  const k1 = (start + 1) & M;
  const k2 = (start + 2) & M;
  const k3 = (start + 3) & M;
  p.moveTo(xs[k0], ys[k0]);
  p.lineTo(xs[k1], ys[k1]);
  p.quadraticCurveTo(xs[k1], ys[k2], xs[k2], ys[k2]);
  p.bezierCurveTo(xs[k0], ys[k1], xs[k2], ys[k3], xs[k3], ys[k3]);
  p.arc(xs[k0], ys[k0], radii[k0], a0s[k0], a1s[k0], ccws[k0] !== 0);
  p.arcTo(xs[k1], ys[k1], xs[k2], ys[k2], radii[k1]);
  p.rect(xs[k2], ys[k2], radii[k2], radii[k3]);
  p.closePath();
  return p.toString();
}

const cases = {
  "polyline100.full": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildPolyline(d3Path(), xs, ys, i)); sink += s; },
  "polyline100.round3": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildPolyline(pathRound(3), xs, ys, i)); sink += s; },
  "polyline100.int": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildPolyline(d3Path(), ixs, iys, i)); sink += s; },
  "bezier50.full": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildBezier(d3Path(), i)); sink += s; },
  "bezier50.round3": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildBezier(pathRound(3), i)); sink += s; },
  "quad50.full": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildQuad(d3Path(), i)); sink += s; },
  "quad50.round3": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildQuad(pathRound(3), i)); sink += s; },
  "arc20.full": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildArcs(d3Path(), i)); sink += s; },
  "arc20.round3": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildArcs(pathRound(3), i)); sink += s; },
  "arcTo20.full": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildArcTo(d3Path(), i)); sink += s; },
  "arcTo20.round3": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildArcTo(pathRound(3), i)); sink += s; },
  "rect50.full": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildRects(d3Path(), i)); sink += s; },
  "rect50.round3": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildRects(pathRound(3), i)); sink += s; },
  "mixed.full": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildMixed(d3Path(), i)); sink += s; },
  "mixed.round3": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(buildMixed(pathRound(3), i)); sink += s; },
};

let target = "node";
let filter = "";
let batches = 9;
let batchMs = 60;
let warmMs = 300;
for (const arg of process.argv.slice(2)) {
  if (arg.startsWith("--target=")) target = arg.slice(9);
  else if (arg.startsWith("--filter=")) filter = arg.slice(9);
  else if (arg.startsWith("--batches=")) batches = Number(arg.slice(10));
  else if (arg.startsWith("--batch-ms=")) batchMs = Number(arg.slice(11));
  else if (arg.startsWith("--warm-ms=")) warmMs = Number(arg.slice(10));
}

const targetMs = batchMs / 4;
for (const [name, fn] of Object.entries(cases)) {
  if (filter && !name.includes(filter)) continue;
  let ops = 8;
  const warmEnd = performance.now() + warmMs;
  while (performance.now() < warmEnd) {
    const t0 = performance.now();
    fn(ops);
    if (performance.now() - t0 < targetMs) ops *= 2;
  }
  const samples = [];
  for (let b = 0; b < batches; b++) {
    const t0 = performance.now();
    fn(ops);
    samples.push(((performance.now() - t0) * 1e6) / ops);
  }
  samples.sort((a, b) => a - b);
  const median = samples[samples.length >> 1];
  console.log(
    `BENCH {"target":"${target}","case":"${name}","ns":${median.toFixed(2)},"ops":${ops}}`,
  );
}
if (sink === -123456789) console.log(sink);
