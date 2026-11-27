// Original code, not ported from d3-chord: upstream Node.js benchmark.

import {performance} from "node:perf_hooks";
import {registerHooks} from "node:module";
import {fileURLToPath, pathToFileURL} from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");

const d3PathUrl = pathToFileURL(
  path.join(repo, "third_party/d3-path/src/index.js"),
).href;

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "d3-path") {
      return {url: d3PathUrl, shortCircuit: true};
    }
    return nextResolve(specifier, context);
  },
});

const d3 = await import(
  pathToFileURL(path.join(repo, "third_party/d3-chord/src/index.js")).href
);

class Lcg {
  constructor(seed) {
    this.seed = seed;
  }
  nextDouble() {
    this.seed = (this.seed * 48271) % 2147483647;
    return this.seed / 2147483647.0;
  }
}

class BenchCanvasSink {
  constructor() {
    this.acc = 0;
  }
  moveTo(x, y) { this.acc += x + y; }
  closePath() { this.acc += 1; }
  lineTo(x, y) { this.acc += x + y; }
  quadraticCurveTo(x1, y1, x, y) { this.acc += x1 + y1 + x + y; }
  bezierCurveTo(x1, y1, x2, y2, x, y) { this.acc += x1 + y1 + x2 + y2 + x + y; }
  arcTo(x1, y1, x2, y2, r) { this.acc += x1 + y1 + x2 + y2 + r; }
  arc(x, y, r, a0, a1) { this.acc += x + y + r + a0 + a1; }
  rect(x, y, w, h) { this.acc += x + y + w + h; }
}

const matrix4 = [
  [11975, 5871, 8916, 2868],
  [1951, 10048, 2060, 6171],
  [8010, 16145, 8090, 8045],
  [1013, 990, 940, 6907],
];

const r = new Lcg(42);
function makeMatrix(n, zeroProb = 0) {
  return Array.from({length: n}, () =>
    Array.from({length: n}, () => {
      const u = r.nextDouble();
      if (zeroProb > 0 && u < zeroProb) return 0;
      return Math.floor(10 + r.nextDouble() * 990);
    }),
  );
}

const matrix16 = makeMatrix(16);
const sparse16 = makeMatrix(16, 0.3);
const matrix32 = makeMatrix(32);

const chords16 = d3.chord().padAngle(0.03)(matrix16);
const directed16 = d3.chordDirected().padAngle(0.03)(sparse16);

const desc = (a, b) => b - a;
const asc = (a, b) => a - b;

const chordPlain = d3.chord().padAngle(0.04);
const chordSorted = d3.chord().padAngle(0.04).sortGroups(desc).sortSubgroups(desc).sortChords(desc);
const chordDir = d3.chordDirected().padAngle(0.04);
const chordDirSorted = d3.chordDirected().padAngle(0.04).sortGroups(desc).sortSubgroups(desc).sortChords(asc);
const chordTrans = d3.chordTranspose().padAngle(0.04);

const ribSvg = d3.ribbon().radius(240);
const ribPadded = d3.ribbon().sourceRadius(240).targetRadius(225).padAngle(0.01);
const ribArrowSvg = d3.ribbonArrow().sourceRadius(240).targetRadius(230).headRadius(12);
const canvasSink = new BenchCanvasSink();
const ribCanvas = d3.ribbon().radius(240).context(canvasSink);
const ribArrowCanvas = d3.ribbonArrow().sourceRadius(240).targetRadius(230).headRadius(12).context(canvasSink);

let sink = 0;
const eatText = (s) => s.length + s.charCodeAt(s.length - 1);

const cases = {
  "chord.4x4": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const res = chordPlain(matrix4);
      s += res.length + res.groups[0].endAngle;
    }
    sink += s;
  },
  "chord.16x16": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const res = chordPlain(matrix16);
      s += res.length + res.groups[0].endAngle;
    }
    sink += s;
  },
  "chord.32x32": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const res = chordPlain(matrix32);
      s += res.length + res.groups[0].endAngle;
    }
    sink += s;
  },
  "chord.32x32_sorted": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const res = chordSorted(matrix32);
      s += res.length + res.groups[0].endAngle;
    }
    sink += s;
  },
  "chordDirected.16x16": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const res = chordDir(sparse16);
      s += res.length + res.groups[0].endAngle;
    }
    sink += s;
  },
  "chordDirected.32x32_sorted": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const res = chordDirSorted(matrix32);
      s += res.length + res.groups[0].endAngle;
    }
    sink += s;
  },
  "chordTranspose.16x16": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const res = chordTrans(matrix16);
      s += res.length + res.groups[0].endAngle;
    }
    sink += s;
  },
  "ribbon.svg_136": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < chords16.length; j++) s += eatText(ribSvg(chords16[j]));
    }
    sink += s;
  },
  "ribbon.padded_136": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < chords16.length; j++) s += eatText(ribPadded(chords16[j]));
    }
    sink += s;
  },
  "ribbonArrow.svg_180": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < directed16.length; j++) s += eatText(ribArrowSvg(directed16[j]));
    }
    sink += s;
  },
  "ribbon.canvas_136": (n) => {
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < chords16.length; j++) ribCanvas(chords16[j]);
    }
    sink += canvasSink.acc;
    canvasSink.acc = 0;
  },
  "ribbonArrow.canvas_180": (n) => {
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < directed16.length; j++) ribArrowCanvas(directed16[j]);
    }
    sink += canvasSink.acc;
    canvasSink.acc = 0;
  },
};

const args = process.argv.slice(2);
let filter = "";
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--filter" && i + 1 < args.length) filter = args[++i];
}

const batches = 9;
const batchMs = 60;
const warmMs = 250;

for (const [name, fn] of Object.entries(cases)) {
  if (filter && !name.includes(filter)) continue;
  let iters = 1;
  const w0 = performance.now();
  while (performance.now() - w0 < warmMs) {
    fn(iters);
    if (performance.now() - w0 < 20) iters *= 2;
  }
  let probe = 1;
  while (true) {
    const t0 = performance.now();
    fn(probe);
    const dt = performance.now() - t0;
    if (dt >= batchMs || probe >= 1 << 24) break;
    probe = dt === 0 ? probe * 8 : Math.min(probe * 8, Math.max(probe + 1, Math.ceil((probe * batchMs) / dt)));
  }
  const samples = [];
  for (let b = 0; b < batches; b++) {
    const t0 = performance.now();
    fn(probe);
    const dt = performance.now() - t0;
    samples.push((dt * 1e6) / probe);
  }
  samples.sort((a, b) => a - b);
  const median = samples[samples.length >> 1];
  console.log(
    `BENCH ${JSON.stringify({target: "node", case: name, ns_op: Number(median.toFixed(1)), iters: probe})}`,
  );
}
if (sink === -1.23456789) console.log(sink);
