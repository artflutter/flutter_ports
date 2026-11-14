// Original code, not ported from d3-color: the benchmark of upstream in Node.js.
//
// The cases and the inputs of d3_color_bench.dart, on the pinned upstream
// source third_party/d3-color/src (or the folder of the env D3_COLOR_SRC).
// Each case prints one line `BENCH {json}` with the median time of one
// operation in nanoseconds. The arguments are those of the Dart file.

import {performance} from "node:perf_hooks";
import {fileURLToPath, pathToFileURL} from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const src = process.env.D3_COLOR_SRC
  ?? path.resolve(here, "../../../../third_party/d3-color/src");
const d3 = await import(pathToFileURL(path.join(src, "index.js")).href);

class Lcg {
  constructor(seed) { this.seed = seed; }
  next(n) {
    this.seed = this.seed * 48271 % 2147483647;
    return this.seed % n;
  }
}

const POOL = 1024;
const NAMES = [
  "steelblue", "aliceblue", "rebeccapurple", "moccasin", "red", "tomato",
  "darkslategray", "lightgoldenrodyellow", "navy", "teal", "gold", "white",
  "black", "orange", "mediumspringgreen", "transparent", "cornflowerblue",
  "SteelBlue", "GRAY", "peru",
];
const HEX = "0123456789abcdef";
const hex = (r, n) => { let s = ""; for (let i = 0; i < n; i++) s += HEX[r.next(16)]; return s; };
const tenths = (n) => `${Math.floor(n / 10)}.${n % 10}`;
const twoDigits = (n) => n < 10 ? `0${n}` : `${n}`;

function inputs() {
  const r = new Lcg(42);
  const p = {hex6: [], hex3: [], named: [], rgb: [], rgbaPercent: [], hsl: [], invalid: [], mixed: [],
    rgbColors: [], hslColors: [], labColors: [], hclColors: [], cubehelixColors: []};
  for (let i = 0; i < POOL; i++) {
    p.hex6.push(`#${hex(r, 6)}`);
    p.hex3.push(`#${hex(r, 3)}`);
    p.named.push(NAMES[r.next(NAMES.length)]);
    p.rgb.push(`rgb(${r.next(256)}, ${r.next(256)}, ${r.next(256)})`);
    p.rgbaPercent.push(`rgba(${tenths(r.next(1001))}%, ${tenths(r.next(1001))}%, ${tenths(r.next(1001))}%, 0.${twoDigits(r.next(100))})`);
    p.hsl.push(`hsl(${r.next(360)}, ${r.next(101)}%, ${r.next(101)}%)`);
    p.invalid.push(["bostock", "#ab", "rgb(1,2)", "hsl(1 2 3)", "#abcdefg"][r.next(5)]);
    {
      const a = r.next(25600) / 100, b = r.next(25600) / 100, c = r.next(25600) / 100;
      const o = r.next(2) === 0 ? 1 : r.next(100) / 100;
      p.rgbColors.push(d3.rgb(a, b, c, o));
    }
    { const a = r.next(36000) / 100, b = r.next(1000) / 1000, c = r.next(1000) / 1000; p.hslColors.push(d3.hsl(a, b, c, 1)); }
    { const a = r.next(10000) / 100, b = r.next(16000) / 100 - 80, c = r.next(16000) / 100 - 80; p.labColors.push(d3.lab(a, b, c, 1)); }
    { const a = r.next(36000) / 100, b = r.next(10000) / 100, c = r.next(10000) / 100; p.hclColors.push(d3.hcl(a, b, c, 1)); }
    { const a = r.next(36000) / 100, b = r.next(1000) / 1000, c = r.next(1000) / 1000; p.cubehelixColors.push(d3.cubehelix(a, b, c, 1)); }
  }
  for (let i = 0; i < POOL; i++) {
    const k = i % 6;
    p.mixed.push([p.hex6, p.hex3, p.named, p.rgb, p.rgbaPercent, p.hsl][k][i]);
  }
  return p;
}

let sink = 0;
const M = POOL - 1;

function cases(p) {
  const parse = (pool, i) => { const c = d3.color(pool[i & M]); sink += c == null ? 1 : c.opacity; };
  return [
    ["parse.hex6", (i) => parse(p.hex6, i)],
    ["parse.hex3", (i) => parse(p.hex3, i)],
    ["parse.named", (i) => parse(p.named, i)],
    ["parse.rgb", (i) => parse(p.rgb, i)],
    ["parse.rgbaPercent", (i) => parse(p.rgbaPercent, i)],
    ["parse.hsl", (i) => parse(p.hsl, i)],
    ["parse.invalid", (i) => parse(p.invalid, i)],
    ["parse.mixed", (i) => parse(p.mixed, i)],
    ["rgb.parse", (i) => sink += d3.rgb(p.mixed[i & M]).r],
    ["format.hex", (i) => sink += p.rgbColors[i & M].formatHex().length],
    ["format.hex8", (i) => sink += p.rgbColors[i & M].formatHex8().length],
    ["format.rgb", (i) => sink += p.rgbColors[i & M].formatRgb().length],
    ["format.hsl", (i) => sink += p.hslColors[i & M].formatHsl().length],
    ["format.rgbOfHsl", (i) => sink += p.hslColors[i & M].toString().length],
    ["convert.rgbToHsl", (i) => sink += d3.hsl(p.rgbColors[i & M]).l],
    ["convert.hslToRgb", (i) => sink += p.hslColors[i & M].rgb().r],
    ["convert.rgbToLab", (i) => sink += d3.lab(p.rgbColors[i & M]).l],
    ["convert.labToRgb", (i) => sink += p.labColors[i & M].rgb().r],
    ["convert.rgbToHcl", (i) => sink += d3.hcl(p.rgbColors[i & M]).c],
    ["convert.hclToRgb", (i) => sink += p.hclColors[i & M].rgb().r],
    ["convert.rgbToCubehelix", (i) => sink += d3.cubehelix(p.rgbColors[i & M]).l],
    ["convert.cubehelixToRgb", (i) => sink += p.cubehelixColors[i & M].rgb().r],
    ["op.brighterRgb", (i) => sink += p.rgbColors[i & M].brighter(0.5).r],
    ["op.darkerHcl", (i) => sink += p.hclColors[i & M].darker().l],
    ["pipe.hclTick", (i) => {
      const c = p.hclColors[i & M];
      const h = c.h;
      c.h = h + 0.5;
      sink += (c + "").length;
      c.h = h;
    }],
    ["pipe.parseHex", (i) => sink += d3.rgb(p.mixed[i & M]).formatHex().length],
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
