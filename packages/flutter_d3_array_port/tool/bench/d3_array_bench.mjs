// Original code, not ported from d3-array: upstream Node.js benchmark.

import {registerHooks} from "node:module";
import {performance} from "node:perf_hooks";
import {fileURLToPath, pathToFileURL} from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");

const internmapUrl = pathToFileURL(
  path.join(repo, "third_party/internmap/src/index.js"),
).href;
registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "internmap") {
      return {shortCircuit: true, url: internmapUrl};
    }
    return nextResolve(specifier, context);
  },
});

const d3 = await import(
  pathToFileURL(path.join(repo, "third_party/d3-array/src/index.js")).href
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

const r = new Lcg(42);
const f64_1024 = new Float64Array(1024);
const list1024 = new Array(1024);
for (let i = 0; i < 1024; i++) {
  const v = (r.nextDouble() - 0.35) * 2000.0;
  f64_1024[i] = v;
  list1024[i] = v;
}
const sorted1024 = Float64Array.from(f64_1024).sort();
const queries64 = new Float64Array(64);
for (let i = 0; i < 64; i++) {
  queries64[i] = (r.nextDouble() - 0.35) * 2100.0;
}
const f64_512 = new Float64Array(512);
for (let i = 0; i < 512; i++) {
  f64_512[i] = Math.round(r.nextDouble() * 100.0);
}
const grid64x64 = new Float64Array(64 * 64);
for (let i = 0; i < grid64x64.length; i++) {
  grid64x64[i] = r.nextDouble() * 255.0;
}
const tickDomains32 = Array.from({length: 32}, (_, i) => {
  const lo = (r.nextDouble() - 0.5) * 1000.0;
  const span = 0.01 + r.nextDouble() * 5000.0;
  const cnt = 3.0 + (i % 10);
  return [lo, lo + span, cnt];
});
const regions = ["North", "South", "East", "West", "Central"];
const cats = ["A", "B", "C", "D", "E", "F", "G", "H"];
const rows512 = Array.from({length: 512}, () => ({
  region: regions[Math.floor(r.nextDouble() * regions.length)],
  category: cats[Math.floor(r.nextDouble() * cats.length)],
  amount: r.nextDouble() * 1000.0,
}));
const ints1024 = Array.from({length: 1024}, (_, i) => i);

const qsBuf = new Float64Array(1024);
const blurBuf = new Float64Array(1024);
const gridBuf = new Float64Array(64 * 64);
const gridData = {data: gridBuf, width: 64, height: 64};
const shufBuf = ints1024.slice();
const binSturges = d3.bin();
const binFD = d3.bin().thresholds(d3.thresholdFreedmanDiaconis);
const shuffleRng = new Lcg(1337);
const shuf = d3.shuffler(() => shuffleRng.nextDouble());

let sink = 0;

const cases = {
  "sum.f64_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += d3.sum(f64_1024);
    sink += s;
  },
  "fsum.f64_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += d3.fsum(f64_1024);
    sink += s;
  },
  "minmax.f64_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const lo = d3.min(f64_1024);
      const hi = d3.max(f64_1024);
      const ext = d3.extent(f64_1024);
      s += lo + hi + ext[0] + ext[1];
    }
    sink += s;
  },
  "mean.f64_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += d3.mean(f64_1024);
    sink += s;
  },
  "variance.f64_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += d3.variance(f64_1024) + d3.deviation(f64_1024);
    sink += s;
  },
  "cumsum.f64_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += d3.cumsum(f64_1024)[1023];
    sink += s;
  },
  "quickselect.f64_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      qsBuf.set(f64_1024);
      d3.quickselect(qsBuf, 512);
      s += qsBuf[512];
    }
    sink += s;
  },
  "quantile.f64_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      s += d3.quantile(f64_1024, 0.25) + d3.quantile(f64_1024, 0.5) + d3.quantile(f64_1024, 0.75);
    }
    sink += s;
  },
  "bisect.f64_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 64; j++) {
        const q = queries64[j];
        s += d3.bisectLeft(sorted1024, q) + d3.bisectRight(sorted1024, q) + d3.bisectCenter(sorted1024, q);
      }
    }
    sink += s;
  },
  "bin.sturges_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const bins = binSturges(list1024);
      s += bins.length + bins[0].length;
    }
    sink += s;
  },
  "bin.fd_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const bins = binFD(list1024);
      s += bins.length + bins[0].length;
    }
    sink += s;
  },
  "ticks.batch32": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 32; j++) {
        const [lo, hi, cnt] = tickDomains32[j];
        const t = d3.ticks(lo, hi, cnt);
        const nc = d3.nice(lo, hi, cnt);
        s += t.length + nc[0] + nc[1];
      }
    }
    sink += s;
  },
  "range.1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const a = d3.range(0, 1024, 1);
      const b = d3.range(0, 10, 0.05);
      s += a[1023] + b[b.length - 1];
    }
    sink += s;
  },
  "blur1.1024_r3": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      blurBuf.set(f64_1024);
      d3.blur(blurBuf, 3);
      s += blurBuf[512];
    }
    sink += s;
  },
  "blur1.1024_r2_5": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      blurBuf.set(f64_1024);
      d3.blur(blurBuf, 2.5);
      s += blurBuf[512];
    }
    sink += s;
  },
  "blur2.64x64_r2": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      gridBuf.set(grid64x64);
      d3.blur2(gridData, 2);
      s += gridBuf[2080];
    }
    sink += s;
  },
  "sort.f64_1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const out = d3.sort(f64_1024);
      s += out[0] + out[1023];
    }
    sink += s;
  },
  "rank.f64_512": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const out = d3.rank(f64_512);
      s += out[0] + out[511];
    }
    sink += s;
  },
  "group.rollup_512": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const g = d3.group(rows512, (x) => x.region);
      const r = d3.rollup(rows512, (rows) => d3.sum(rows, (x) => x.amount), (x) => x.category);
      s += g.size + (r.get("A") ?? 0);
    }
    sink += s;
  },
  "shuffle.1024": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      shuf(shufBuf);
      s += shufBuf[0];
    }
    sink += s;
  },
};

let target = "node";
let filter = "";
let batches = 9;
let batchMs = 60;
let warmMs = 300;
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
  let ops = 4;
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
