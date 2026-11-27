// Original code, not ported from d3-contour: upstream Node.js benchmark.

import {registerHooks} from "node:module";
import {performance} from "node:perf_hooks";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");

const internmapUrl = pathToFileURL(
  path.join(repo, "third_party/internmap/src/index.js"),
).href;
const d3ArrayUrl = pathToFileURL(
  path.join(repo, "third_party/d3-array/src/index.js"),
).href;

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "internmap") {
      return {shortCircuit: true, url: internmapUrl};
    }
    if (specifier === "d3-array") {
      return {shortCircuit: true, url: d3ArrayUrl};
    }
    return nextResolve(specifier, context);
  },
});

const d3 = await import(
  pathToFileURL(path.join(repo, "third_party/d3-contour/src/index.js")).href
);

class Lcg {
  constructor(seed) {
    this.seed = seed;
  }
  nextDouble() {
    this.seed = (this.seed * 48271) % 2147483647;
    return this.seed / 2147483647.0;
  }
  nextGaussian() {
    const u1 = Math.max(1e-9, this.nextDouble());
    const u2 = this.nextDouble();
    return Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math.PI * u2);
  }
}

function makePeaksGrid(w, h) {
  const out = new Float64Array(w * h);
  for (let y = 0; y < h; y++) {
    const ny = y / h;
    for (let x = 0; x < w; x++) {
      const nx = x / w;
      const dx1 = (nx - 0.3) / 0.16;
      const dy1 = (ny - 0.35) / 0.16;
      const dx2 = (nx - 0.68) / 0.2;
      const dy2 = (ny - 0.62) / 0.19;
      const dx3 = (nx - 0.66) / 0.08;
      const dy3 = (ny - 0.61) / 0.08;
      out[y * w + x] =
        100.0 * Math.exp(-(dx1 * dx1 + dy1 * dy1)) +
        125.0 * Math.exp(-(dx2 * dx2 + dy2 * dy2)) -
        70.0 * Math.exp(-(dx3 * dx3 + dy3 * dy3)) +
        10.0 * Math.sin(nx * 14.0) * Math.cos(ny * 12.0);
    }
  }
  return out;
}

function makeHolesGrid(w, h) {
  const out = new Float64Array(w * h);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const gx = (x % 16) - 7.5;
      const gy = (y % 16) - 7.5;
      const r = Math.sqrt(gx * gx + gy * gy);
      out[y * w + x] = Math.cos(r * 0.9) * 50.0 + 50.0;
    }
  }
  return out;
}

function makeGoldsteinGrid(w, h) {
  const out = new Float64Array(w * h);
  for (let j = 0; j < h; j++) {
    const y = 1.0 - ((j + 0.5) / h) * 3.0;
    for (let i = 0; i < w; i++) {
      const x = ((i + 0.5) / w) * 4.0 - 2.0;
      const a = x + y + 1.0;
      const b = 2.0 * x - 3.0 * y;
      out[j * w + i] =
        (1.0 +
          a *
            a *
            (19.0 -
              14.0 * x +
              3.0 * x * x -
              14.0 * y +
              6.0 * x * y +
              3.0 * y * y)) *
        (30.0 +
          b *
            b *
            (18.0 -
              32.0 * x +
              12.0 * x * x +
              48.0 * y -
              36.0 * x * y +
              27.0 * y * y));
    }
  }
  return out;
}

function makeClusters(count, seed) {
  const r = new Lcg(seed);
  const centers = [
    [190, 150, 42, 34],
    [430, 240, 56, 46],
    [320, 110, 32, 28],
  ];
  const out = new Array(count);
  for (let i = 0; i < count; i++) {
    const [cx, cy, sx, sy] = centers[i % centers.length];
    out[i] = [cx + r.nextGaussian() * sx, cy + r.nextGaussian() * sy];
  }
  return out;
}

function makeWeightedClusters(count, seed) {
  const r = new Lcg(seed);
  const centers = [
    [190, 150, 42, 34],
    [430, 240, 56, 46],
    [320, 110, 32, 28],
  ];
  const out = new Array(count);
  for (let i = 0; i < count; i++) {
    const [cx, cy, sx, sy] = centers[i % centers.length];
    const w =
      i % 25 === 0 ? NaN : i % 19 === 0 ? 0.0 : 0.5 + r.nextDouble() * 3.0;
    out[i] = [cx + r.nextGaussian() * sx, cy + r.nextGaussian() * sy, w];
  }
  return out;
}

function makeFaithfulLike() {
  const r = new Lcg(99);
  const out = new Array(272);
  for (let i = 0; i < 272; i++) {
    if (i % 3 === 0) {
      out[i] = [220.0 + r.nextGaussian() * 55.0, 340.0 + r.nextGaussian() * 48.0];
    } else {
      out[i] = [680.0 + r.nextGaussian() * 72.0, 130.0 + r.nextGaussian() * 52.0];
    }
  }
  return out;
}

function checksumContours(list) {
  let total = list.length;
  for (let i = 0; i < list.length; i++) {
    const coords = list[i].coordinates;
    total += coords.length;
    for (let j = 0; j < coords.length; j++) {
      const poly = coords[j];
      total += poly.length;
      for (let k = 0; k < poly.length; k++) {
        total += poly[k].length;
      }
    }
  }
  return total;
}

const peaks64 = makePeaksGrid(64, 64);
const peaks128 = makePeaksGrid(128, 128);
const holes64 = makeHolesGrid(64, 64);
const goldstein96 = makeGoldsteinGrid(96, 96);
const faithfulPts = makeFaithfulLike();
const clusters2000 = makeClusters(2000, 42);
const clusters10000 = makeClusters(10000, 77);
const weighted2000 = makeWeightedClusters(2000, 123);

const cPeaks64 = d3.contours().size([64, 64]).thresholds(10);
const cPeaks64Raw = d3.contours().size([64, 64]).smooth(false).thresholds(10);
const cPeaks128 = d3.contours().size([128, 128]).thresholds(10);
const cSingle128 = d3.contours().size([128, 128]);
const cHoles64 = d3.contours().size([64, 64]).thresholds([20, 40, 60, 80]);
const cGoldstein96 = d3
  .contours()
  .size([96, 96])
  .thresholds(Array.from({length: 12}, (_, i) => Math.pow(2, i + 2)));

const dFaithful = d3
  .contourDensity()
  .size([960, 500])
  .bandwidth(30)
  .thresholds(20);
const dClusters2000Cs4 = d3
  .contourDensity()
  .size([640, 400])
  .bandwidth(20)
  .cellSize(4)
  .thresholds(12);
const dClusters2000Cs2 = d3
  .contourDensity()
  .size([640, 400])
  .bandwidth(20)
  .cellSize(2)
  .thresholds(10);
const dClusters10000Cs4 = d3
  .contourDensity()
  .size([640, 400])
  .bandwidth(24)
  .cellSize(4)
  .thresholds(10);
const dWeighted2000 = d3
  .contourDensity()
  .x((d) => d[0])
  .y((d) => d[1])
  .weight((d) => d[2])
  .size([640, 400])
  .bandwidth(20)
  .cellSize(4)
  .thresholds(10);

let sink = 0;

const cases = {
  "contours.peaks_64x64_10": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += checksumContours(cPeaks64(peaks64));
    sink += s;
  },
  "contours.peaks_64x64_raw": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += checksumContours(cPeaks64Raw(peaks64));
    sink += s;
  },
  "contours.peaks_128x128_10": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += checksumContours(cPeaks128(peaks128));
    sink += s;
  },
  "contours.single_128x128": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += cSingle128.contour(peaks128, 55).coordinates.length;
    sink += s;
  },
  "contours.holes_64x64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += checksumContours(cHoles64(holes64));
    sink += s;
  },
  "contours.goldstein_96x96_12": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += checksumContours(cGoldstein96(goldstein96));
    sink += s;
  },
  "density.faithful_bw30": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += checksumContours(dFaithful(faithfulPts));
    sink += s;
  },
  "density.clusters_2000_cs4": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += checksumContours(dClusters2000Cs4(clusters2000));
    sink += s;
  },
  "density.clusters_2000_cs2": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += checksumContours(dClusters2000Cs2(clusters2000));
    sink += s;
  },
  "density.clusters_10000_cs4": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += checksumContours(dClusters10000Cs4(clusters10000));
    sink += s;
  },
  "density.weighted_2000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += checksumContours(dWeighted2000(weighted2000));
    sink += s;
  },
  "density.contours_query5": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const q = dClusters2000Cs4.contours(clusters2000);
      const mx = q.max;
      for (let k = 1; k <= 5; k++) s += q((mx * k) / 6.0).coordinates.length;
    }
    sink += s;
  },
};

let target = "node";
let filter = "";
let batches = 7;
let batchMs = 60;
let warmMs = 250;
for (const arg of process.argv.slice(2)) {
  if (arg.startsWith("--target=")) target = arg.slice("--target=".length);
  else if (arg.startsWith("--filter=")) filter = arg.slice("--filter=".length);
  else if (arg.startsWith("--batches=")) batches = Number(arg.slice("--batches=".length));
  else if (arg.startsWith("--batch-ms=")) batchMs = Number(arg.slice("--batch-ms=".length));
  else if (arg.startsWith("--warm-ms=")) warmMs = Number(arg.slice("--warm-ms=".length));
}

const targetMs = batchMs * 0.25;
for (const [name, fn] of Object.entries(cases)) {
  if (filter && !name.includes(filter)) continue;
  let ops = 1;
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
