// Original code, not ported from d3-scale-chromatic: upstream Node.js benchmark.

import {performance} from "node:perf_hooks";
import {registerHooks} from "node:module";
import {fileURLToPath, pathToFileURL} from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");
const colorUrl = pathToFileURL(path.join(repo, "third_party/d3-color/src/index.js")).href;
const interpUrl = pathToFileURL(path.join(repo, "third_party/d3-interpolate/src/index.js")).href;
const chromSrc = path.join(repo, "third_party/d3-scale-chromatic/src");

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "d3-color") return {url: colorUrl, shortCircuit: true};
    if (specifier === "d3-interpolate") return {url: interpUrl, shortCircuit: true};
    return nextResolve(specifier, context);
  },
});

const d3 = await import(pathToFileURL(path.join(chromSrc, "index.js")).href);
const {default: colors} = await import(pathToFileURL(path.join(chromSrc, "colors.js")).href);

class Lcg {
  constructor(seed) { this.seed = seed; }
  next(n) {
    this.seed = (this.seed * 48271) % 2147483647;
    return this.seed % n;
  }
}

const POOL = 1024;
const M = POOL - 1;

const SPEC10 = "1f77b4ff7f0e2ca02cd627289467bd8c564be377c27f7f7fbcbd2217becf";
const SPEC256 =
  "44015444025645045745055946075a46085c460a5d460b5e470d60470e61471063471164" +
  "47136548146748166848176948186a481a6c481b6d481c6e481d6f481f70482071482173" +
  "482374482475482576482677482878482979472a7a472c7a472d7b472e7c472f7d46307e" +
  "46327e46337f463480453581453781453882443983443a83443b84433d84433e85423f85" +
  "4240864241864142874144874045884046883f47883f48893e49893e4a893e4c8a3d4d8a" +
  "3d4e8a3c4f8a3c508b3b518b3b528b3a538b3a548c39558c39568c38588c38598c375a8c" +
  "375b8d365c8d365d8d355e8d355f8d34608d34618d33628d33638d32648e32658e31668e" +
  "31678e31688e30698e306a8e2f6b8e2f6c8e2e6d8e2e6e8e2e6f8e2d708e2d718e2c718e" +
  "2c728e2c738e2b748e2b758e2a768e2a778e2a788e29798e297a8e297b8e287c8e287d8e" +
  "277e8e277f8e27808e26818e26828e26828e25838e25848e25858e24868e24878e23888e" +
  "23898e238a8d228b8d228c8d228d8d218e8d218f8d21908d21918c20928c20928c20938c" +
  "1f948c1f958b1f968b1f978b1f988b1f998a1f9a8a1e9b8a1e9c891e9d891f9e891f9f88" +
  "1fa0881fa1881fa1871fa28720a38620a48621a58521a68522a78522a88423a98324aa83" +
  "25ab8225ac8226ad8127ad8128ae8029af7f2ab07f2cb17e2db27d2eb37c2fb47c31b57b" +
  "32b67a34b67935b77937b87838b9773aba763bbb753dbc743fbc7340bd7242be7144bf70" +
  "46c06f48c16e4ac16d4cc26c4ec36b50c46a52c56954c56856c66758c7655ac8645cc863" +
  "5ec96260ca6063cb5f65cb5e67cc5c69cd5b6ccd5a6ece5870cf5773d05675d05477d153" +
  "7ad1517cd2507fd34e81d34d84d44b86d54989d5488bd6468ed64590d74393d74195d840" +
  "98d83e9bd93c9dd93ba0da39a2da37a5db36a8db34aadc32addc30b0dd2fb2dd2db5de2b" +
  "b8de29bade28bddf26c0df25c2df23c5e021c8e020cae11fcde11dd0e11cd2e21bd5e21a" +
  "d8e219dae319dde318dfe318e2e418e5e419e7e419eae51aece51befe51cf1e51df4e61e" +
  "f6e620f8e621fbe723fde725";

const r = new Lcg(42);
const ts = new Float64Array(POOL);
const tsWrap = new Float64Array(POOL);
for (let i = 0; i < POOL; i++) {
  const t = r.next(1001) / 1000;
  ts[i] = t;
  tsWrap[i] = t * 5 - 2;
}

let sink = 0;
const eatText = (s) => s.length + s.charCodeAt(s.length - 1);

const cases = {
  "call.viridis": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateViridis(ts[(i * 7) & M])); sink += s; },
  "call.magma": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateMagma(ts[(i * 7) & M])); sink += s; },
  "call.turbo": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateTurbo(ts[(i * 7) & M])); sink += s; },
  "call.cividis": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateCividis(ts[(i * 7) & M])); sink += s; },
  "call.sinebow": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateSinebow(ts[(i * 7) & M])); sink += s; },
  "call.rainbow": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateRainbow(ts[(i * 7) & M])); sink += s; },
  "call.rainbowWrap": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateRainbow(tsWrap[(i * 7) & M])); sink += s; },
  "call.warm": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateWarm(ts[(i * 7) & M])); sink += s; },
  "call.cubehelixDefault": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateCubehelixDefault(ts[(i * 7) & M])); sink += s; },
  "call.brBG": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateBrBG(ts[(i * 7) & M])); sink += s; },
  "call.blues": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateBlues(ts[(i * 7) & M])); sink += s; },
  "text.viridis": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateViridis(ts[(i * 7) & M])); sink += s; },
  "text.turbo": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateTurbo(ts[(i * 7) & M])); sink += s; },
  "text.sinebow": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateSinebow(ts[(i * 7) & M])); sink += s; },
  "text.rainbow": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateRainbow(ts[(i * 7) & M])); sink += s; },
  "text.brBG": (n) => { let s = 0; for (let i = 0; i < n; i++) s += eatText(d3.interpolateBrBG(ts[(i * 7) & M])); sink += s; },
  "parse.colors10": (n) => { let s = 0; for (let i = 0; i < n; i++) { const l = colors(SPEC10); s += l[i & 7].charCodeAt(1); } sink += s; },
  "parse.colors256": (n) => { let s = 0; for (let i = 0; i < n; i++) { const l = colors(SPEC256); s += l[i & 255].charCodeAt(1); } sink += s; },
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
  let ops = 64;
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
if (sink === -1.23456789) console.log(sink);
