// Original code, not ported from d3-time: upstream Node.js benchmark.

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

const {
  utcSecond,
  utcMinute,
  utcHour,
  utcDay,
  utcWeek,
  utcMonth,
  timeDay,
  utcTicks,
  timeTicks,
} = await import(
  pathToFileURL(path.join(repo, "third_party/d3-time/src/index.js")).href
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
const spanMs = 80 * 365 * 86400 * 1000;
const dates = Array.from({length: 1000}, () => new Date(Math.floor(r.nextDouble() * spanMs)));
const datesB = Array.from({length: 1000}, () => new Date(Math.floor(r.nextDouble() * spanMs)));

const utcSpans = [
  [new Date(Date.UTC(2024, 0, 1, 12)), new Date(Date.UTC(2024, 0, 1, 12, 0, 1)), 5],
  [new Date(Date.UTC(2024, 0, 1, 12)), new Date(Date.UTC(2024, 0, 1, 12, 0, 30)), 6],
  [new Date(Date.UTC(2024, 0, 1, 12)), new Date(Date.UTC(2024, 0, 1, 12, 5)), 5],
  [new Date(Date.UTC(2024, 0, 1, 12)), new Date(Date.UTC(2024, 0, 1, 12, 45)), 6],
  [new Date(Date.UTC(2024, 0, 1, 12)), new Date(Date.UTC(2024, 0, 1, 18)), 6],
  [new Date(Date.UTC(2024, 0, 1)), new Date(Date.UTC(2024, 0, 3)), 8],
  [new Date(Date.UTC(2024, 0, 1)), new Date(Date.UTC(2024, 0, 15)), 7],
  [new Date(Date.UTC(2024, 0, 1)), new Date(Date.UTC(2024, 1, 15)), 6],
  [new Date(Date.UTC(2024, 0, 1)), new Date(Date.UTC(2024, 6, 1)), 6],
  [new Date(Date.UTC(2024, 0, 1)), new Date(Date.UTC(2025, 5, 1)), 6],
  [new Date(Date.UTC(2020, 0, 1)), new Date(Date.UTC(2026, 0, 1)), 6],
  [new Date(Date.UTC(1990, 0, 1)), new Date(Date.UTC(2025, 0, 1)), 7],
  [new Date(Date.UTC(1800, 0, 1)), new Date(Date.UTC(2025, 0, 1)), 8],
  [new Date(Date.UTC(2025, 0, 1)), new Date(Date.UTC(2024, 0, 1)), 6],
  [new Date(Date.UTC(2024, 5, 15, 10, 30)), new Date(Date.UTC(2024, 5, 15, 14, 45)), 8],
  [new Date(Date.UTC(2024, 2, 1)), new Date(Date.UTC(2024, 2, 31)), 10],
];

const localSpans = utcSpans.map(([a, b, c]) => [
  new Date(a.getUTCFullYear(), a.getUTCMonth(), a.getUTCDate(), a.getUTCHours(), a.getUTCMinutes(), a.getUTCSeconds()),
  new Date(b.getUTCFullYear(), b.getUTCMonth(), b.getUTCDate(), b.getUTCHours(), b.getUTCMinutes(), b.getUTCSeconds()),
  c,
]);

const u2024 = new Date(Date.UTC(2024, 0, 1));
const u2025 = new Date(Date.UTC(2025, 0, 1));
const u2024Feb = new Date(Date.UTC(2024, 1, 1));
const u2024Jan2 = new Date(Date.UTC(2024, 0, 2));
const u2015 = new Date(Date.UTC(2015, 0, 1));
const u1975 = new Date(Date.UTC(1975, 0, 1));
const l2024 = new Date(2024, 0, 1);
const l2025 = new Date(2025, 0, 1);

let sink = 0;

const cases = {
  "utcSecond.fcr_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < dates.length; j++) {
        const d = dates[j];
        s += +utcSecond.floor(d) + +utcSecond.ceil(d) + +utcSecond.round(d);
      }
    }
    sink += s;
  },
  "utcMinute.fcr_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < dates.length; j++) {
        const d = dates[j];
        s += +utcMinute.floor(d) + +utcMinute.ceil(d) + +utcMinute.round(d);
      }
    }
    sink += s;
  },
  "utcHour.fcr_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < dates.length; j++) {
        const d = dates[j];
        s += +utcHour.floor(d) + +utcHour.ceil(d) + +utcHour.round(d);
      }
    }
    sink += s;
  },
  "utcDay.fcr_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < dates.length; j++) {
        const d = dates[j];
        s += +utcDay.floor(d) + +utcDay.ceil(d) + +utcDay.round(d);
      }
    }
    sink += s;
  },
  "utcWeek.fcr_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < dates.length; j++) {
        const d = dates[j];
        s += +utcWeek.floor(d) + +utcWeek.ceil(d) + +utcWeek.round(d);
      }
    }
    sink += s;
  },
  "utcDay.range_366": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const out = utcDay.range(u2024, u2025);
      s += out.length + +out[out.length - 1];
    }
    sink += s;
  },
  "utcHour.range_744": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const out = utcHour.range(u2024, u2024Feb);
      s += out.length + +out[out.length - 1];
    }
    sink += s;
  },
  "utcMinute.range_1440": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const out = utcMinute.range(u2024, u2024Jan2);
      s += out.length + +out[out.length - 1];
    }
    sink += s;
  },
  "utcWeek.range_522": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const out = utcWeek.range(u2015, u2025);
      s += out.length + +out[out.length - 1];
    }
    sink += s;
  },
  "utcMonth.range_600": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const out = utcMonth.range(u1975, u2025);
      s += out.length + +out[out.length - 1];
    }
    sink += s;
  },
  "timeDay.range_366": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const out = timeDay.range(l2024, l2025);
      s += out.length + +out[out.length - 1];
    }
    sink += s;
  },
  "utc.count_offset_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < dates.length; j++) {
        const a = dates[j];
        const b = datesB[j];
        s += utcDay.count(a, b) + utcWeek.count(a, b) + +utcHour.offset(a, 5);
      }
    }
    sink += s;
  },
  "utcTicks.batch_16": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < utcSpans.length; j++) {
        const [a, b, c] = utcSpans[j];
        s += utcTicks(a, b, c).length;
      }
    }
    sink += s;
  },
  "timeTicks.batch_16": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < localSpans.length; j++) {
        const [a, b, c] = localSpans[j];
        s += timeTicks(a, b, c).length;
      }
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
