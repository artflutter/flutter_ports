// Original code, not ported from d3-shape: upstream Node.js benchmark.

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
  pathToFileURL(path.join(repo, "third_party/d3-shape/src/index.js")).href
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
const pieValues = Array.from({length: 20}, () => 5.0 + r.nextDouble() * 95.0);
const arcsPlain = d3.pie()(pieValues);
const arcsPadded = d3.pie().padAngle(0.03)(pieValues);

const points100 = Array.from({length: 100}, (_, i) => {
  const y0 = 10.0 + r.nextDouble() * 120.0;
  const y1 = y0 + 20.0 + r.nextDouble() * 150.0;
  return {
    x: i * 8.0,
    y0,
    y1,
    angle: (i / 100.0) * Math.PI * 2,
    radius: 40.0 + r.nextDouble() * 120.0,
  };
});

const links50 = Array.from({length: 50}, () => ({
  source: [r.nextDouble() * 100.0, r.nextDouble() * 400.0],
  target: [250.0 + r.nextDouble() * 200.0, r.nextDouble() * 400.0],
}));

const radialLinks50 = Array.from({length: 50}, () => ({
  source: [r.nextDouble() * Math.PI * 2, 30.0 + r.nextDouble() * 40.0],
  target: [r.nextDouble() * Math.PI * 2, 100.0 + r.nextDouble() * 80.0],
}));

const symbolSizes = Array.from({length: 50}, () => 32.0 + r.nextDouble() * 192.0);
const stackRows = Array.from({length: 50}, () =>
  Array.from({length: 8}, () => 5.0 + r.nextDouble() * 45.0),
);

let sink = 0;
const eatText = (s) => s.length + s.charCodeAt(s.length - 1);

const arcPlainGen = d3.arc().innerRadius(40).outerRadius(100);
const arcRoundedGen = d3.arc().innerRadius(40).outerRadius(100).cornerRadius(8);
const pieGen = d3.pie();

const makeLine = (curve) =>
  d3
    .line()
    .x((d) => d.x)
    .y((d) => d.y1)
    .curve(curve);

const lineLinear = makeLine(d3.curveLinear);
const lineBasis = makeLine(d3.curveBasis);
const lineCardinal = makeLine(d3.curveCardinal);
const lineCatmullRom = makeLine(d3.curveCatmullRom);
const lineMonotoneX = makeLine(d3.curveMonotoneX);
const lineNatural = makeLine(d3.curveNatural);
const lineStep = makeLine(d3.curveStep);

const makeArea = (curve) =>
  d3
    .area()
    .x((d) => d.x)
    .y0((d) => d.y0)
    .y1((d) => d.y1)
    .curve(curve);

const areaLinear = makeArea(d3.curveLinear);
const areaMonotoneX = makeArea(d3.curveMonotoneX);
const areaBasis = makeArea(d3.curveBasis);

const radialLineGen = d3
  .lineRadial()
  .angle((d) => d.angle)
  .radius((d) => d.radius)
  .curve(d3.curveLinearClosed);

const linkH = d3.linkHorizontal();
const linkR = d3.linkRadial();

const symCircle = d3.symbol().type(d3.symbolCircle).size((d) => d);
const symStar = d3.symbol().type(d3.symbolStar).size((d) => d);

const stackNone = d3
  .stack()
  .keys([0, 1, 2, 3, 4, 5, 6, 7])
  .value((d, k) => d[k]);

const stackWiggle = d3
  .stack()
  .keys([0, 1, 2, 3, 4, 5, 6, 7])
  .value((d, k) => d[k])
  .order(d3.stackOrderInsideOut)
  .offset(d3.stackOffsetWiggle);

const cases = {
  "arc.plain20": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) for (const a of arcsPlain) s += eatText(arcPlainGen(a));
    sink += s;
  },
  "arc.roundedPad20": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) for (const a of arcsPadded) s += eatText(arcRoundedGen(a));
    sink += s;
  },
  "pie.20": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const res = pieGen(pieValues);
      s += res.length + Math.round(res[0].endAngle);
    }
    sink += s;
  },
  "line.linear100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(lineLinear(points100));
    sink += s;
  },
  "line.basis100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(lineBasis(points100));
    sink += s;
  },
  "line.cardinal100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(lineCardinal(points100));
    sink += s;
  },
  "line.catmullRom100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(lineCatmullRom(points100));
    sink += s;
  },
  "line.monotoneX100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(lineMonotoneX(points100));
    sink += s;
  },
  "line.natural100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(lineNatural(points100));
    sink += s;
  },
  "line.step100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(lineStep(points100));
    sink += s;
  },
  "area.linear100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(areaLinear(points100));
    sink += s;
  },
  "area.monotoneX100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(areaMonotoneX(points100));
    sink += s;
  },
  "area.basis100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(areaBasis(points100));
    sink += s;
  },
  "lineRadial.100": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) s += eatText(radialLineGen(points100));
    sink += s;
  },
  "linkHorizontal.50": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) for (const l of links50) s += eatText(linkH(l));
    sink += s;
  },
  "linkRadial.50": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) for (const l of radialLinks50) s += eatText(linkR(l));
    sink += s;
  },
  "symbol.circle50": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) for (const sz of symbolSizes) s += eatText(symCircle(sz));
    sink += s;
  },
  "symbol.star50": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) for (const sz of symbolSizes) s += eatText(symStar(sz));
    sink += s;
  },
  "stack.none": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const res = stackNone(stackRows);
      s += res.length + Math.round(res[0][49][1]);
    }
    sink += s;
  },
  "stack.wiggle": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      const res = stackWiggle(stackRows);
      s += res.length + Math.round(res[0][49][1]);
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
  if (arg.startsWith("--target=")) target = arg.slice(9);
  else if (arg.startsWith("--filter=")) filter = arg.slice(9);
  else if (arg.startsWith("--batches=")) batches = Number(arg.slice(10));
  else if (arg.startsWith("--batch-ms=")) batchMs = Number(arg.slice(11));
  else if (arg.startsWith("--warm-ms=")) warmMs = Number(arg.slice(10));
}

const targetMs = batchMs / 4;
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
