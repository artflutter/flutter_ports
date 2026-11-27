// Original code, not ported from d3-random: upstream Node.js benchmark.

import {performance} from "node:perf_hooks";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");
const {
  randomLcg,
  randomUniform,
  randomInt,
  randomNormal,
  randomLogNormal,
  randomBates,
  randomExponential,
  randomPareto,
  randomBernoulli,
  randomGeometric,
  randomGamma,
  randomBeta,
  randomWeibull,
  randomBinomial,
  randomPoisson,
} = await import(
  pathToFileURL(path.join(repo, "third_party/d3-random/src/index.js")).href
);

const lcg = randomLcg(0.42);
const uniform = randomUniform.source(randomLcg(0.42))(-5, 10);
const randInt = randomInt.source(randomLcg(0.42))(10, 42);
const normal = randomNormal.source(randomLcg(0.42))(100, 15);
const logNormal = randomLogNormal.source(randomLcg(0.42))(1.5, 0.5);
const bates = randomBates.source(randomLcg(0.42))(10);
const exponential = randomExponential.source(randomLcg(0.42))(0.25);
const pareto = randomPareto.source(randomLcg(0.42))(3);
const bernoulli = randomBernoulli.source(randomLcg(0.42))(0.35);
const geometric = randomGeometric.source(randomLcg(0.42))(0.25);
const gamma = randomGamma.source(randomLcg(0.42))(5, 1.5);
const beta = randomBeta.source(randomLcg(0.42))(2.7, 0.3);
const weibull = randomWeibull.source(randomLcg(0.42))(3, 1, 2);
const binomial = randomBinomial.source(randomLcg(0.42))(200, 0.37);
const poisson = randomPoisson.source(randomLcg(0.42))(250);
const normalFillFactory = randomNormal.source(randomLcg(0.42));
const fillBuf = new Float64Array(10000);

let sink = 0;

const cases = {
  "lcg.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += lcg();
    }
    sink += s;
  },
  "uniform.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += uniform();
    }
    sink += s;
  },
  "int.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += randInt();
    }
    sink += s;
  },
  "normal.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += normal();
    }
    sink += s;
  },
  "logNormal.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += logNormal();
    }
    sink += s;
  },
  "bates.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += bates();
    }
    sink += s;
  },
  "exponential.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += exponential();
    }
    sink += s;
  },
  "pareto.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += pareto();
    }
    sink += s;
  },
  "bernoulli.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += bernoulli();
    }
    sink += s;
  },
  "geometric.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += geometric();
    }
    sink += s;
  },
  "gamma.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += gamma();
    }
    sink += s;
  },
  "beta.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += beta();
    }
    sink += s;
  },
  "weibull.draw_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 10000; j++) s += weibull();
    }
    sink += s;
  },
  "binomial.draw_2000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 2000; j++) s += binomial();
    }
    sink += s;
  },
  "poisson.draw_2000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < 2000; j++) s += poisson();
    }
    sink += s;
  },
  "normal.fill_10000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const g = normalFillFactory(100, 15);
      for (let j = 0; j < 10000; j++) fillBuf[j] = g();
      s += fillBuf[0] + fillBuf[9999];
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
