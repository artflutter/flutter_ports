// Original code, not ported from d3-format: upstream Node.js benchmark.

import {readFileSync} from "node:fs";
import {performance} from "node:perf_hooks";
import {fileURLToPath, pathToFileURL} from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const repo = path.resolve(here, "../../../..");
const d3 = await import(
  pathToFileURL(path.join(repo, "third_party/d3-format/src/index.js")).href
);

function loadLocale(tag) {
  return JSON.parse(
    readFileSync(path.join(repo, `third_party/d3-format/locale/${tag}.json`), "utf8"),
  );
}

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
const specifiers16 = [
  "",
  "d",
  ",d",
  "+012,d",
  ".2f",
  "+$,.2f",
  "($,.2f",
  ".3e",
  ".4~e",
  ".6g",
  ",~g",
  "n",
  ".3s",
  "~s",
  ".1%",
  "#010x",
];
const ints64 = Array.from({length: 64}, (_, i) => {
  const sign = (i & 3) === 0 ? -1.0 : 1.0;
  return sign * Math.round(r.nextDouble() * 1e9);
});
const floats64 = Array.from({length: 64}, (_, i) => {
  const sign = (i & 3) === 0 ? -1.0 : 1.0;
  return sign * (r.nextDouble() * 1e7);
});
const wide64 = Array.from({length: 64}, (_, i) => {
  const exp = -12 + (i % 25);
  const sign = (i & 7) === 0 ? -1.0 : 1.0;
  return sign * (1.0 + r.nextDouble() * 9.0) * Math.pow(10.0, exp);
});
const trim64 = Array.from({length: 64}, (_, i) => {
  const exp = -6 + (i % 13);
  const coeff = (1 + (i % 9)) * (i % 2 === 0 ? 1.0 : 1.25);
  return coeff * Math.pow(10.0, exp);
});
const ratios64 = Array.from({length: 64}, () => (r.nextDouble() - 0.3) * 2.0);
const hex64 = Array.from({length: 64}, () => Math.floor(r.nextDouble() * 0xffffffff));
const mega64 = Array.from({length: 64}, (_, i) => ((i & 3) === 0 ? -1.0 : 1.0) * r.nextDouble() * 5e7);

let sink = 0;
const eatText = (s) => s.length + s.charCodeAt(s.length - 1);

const dPlain = d3.format("d");
const dGrouped = d3.format(",d");
const dZeroPadGroup = d3.format("+012,d");
const fFixed2 = d3.format(".2f");
const fCurrency = d3.format("+$,.2f");
const fAccounting = d3.format("($,.2f");
const eExp = d3.format(".3e");
const eTrim = d3.format(".4~e");
const gGeneral = d3.format(".6g");
const noneDefault = d3.format("");
const sSiPrefix = d3.format(".3s");
const sSiTrim = d3.format("~s");
const prefixFixedM = d3.formatPrefix(",.2", 1e6);
const pctPercent = d3.format(".1%");
const hexPrefix = d3.format("#010x");
const locFr = d3.formatLocale(loadLocale("fr-FR")).format("$,.2f");
const locIn = d3.formatLocale(loadLocale("en-IN")).format("$,.2f");
const locAr = d3.formatLocale(loadLocale("ar-AE")).format("$,.2f");

const cases = {
  "parse.specifier16": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < specifiers16.length; j++) {
        const parsed = d3.formatSpecifier(specifiers16[j]);
        s += (parsed.width ?? 0) + (parsed.precision ?? 0) + parsed.type.length;
      }
    }
    sink += s;
  },
  "compile.format16": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < specifiers16.length; j++) {
        const fn = d3.format(specifiers16[j]);
        s += fn.toString().charCodeAt(1);
      }
    }
    sink += s;
  },
  "d.plain64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < ints64.length; j++) s += eatText(dPlain(ints64[j]));
    }
    sink += s;
  },
  "d.grouped64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < ints64.length; j++) s += eatText(dGrouped(ints64[j]));
    }
    sink += s;
  },
  "d.zeroPadGroup64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < ints64.length; j++) s += eatText(dZeroPadGroup(ints64[j]));
    }
    sink += s;
  },
  "f.fixed2_64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < floats64.length; j++) s += eatText(fFixed2(floats64[j]));
    }
    sink += s;
  },
  "f.currency64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < floats64.length; j++) s += eatText(fCurrency(floats64[j]));
    }
    sink += s;
  },
  "f.accounting64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < floats64.length; j++) s += eatText(fAccounting(floats64[j]));
    }
    sink += s;
  },
  "e.exp64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < wide64.length; j++) s += eatText(eExp(wide64[j]));
    }
    sink += s;
  },
  "e.trim64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < trim64.length; j++) s += eatText(eTrim(trim64[j]));
    }
    sink += s;
  },
  "g.general64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < wide64.length; j++) s += eatText(gGeneral(wide64[j]));
    }
    sink += s;
  },
  "none.default64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < trim64.length; j++) s += eatText(noneDefault(trim64[j]));
    }
    sink += s;
  },
  "s.siPrefix64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < wide64.length; j++) s += eatText(sSiPrefix(wide64[j]));
    }
    sink += s;
  },
  "s.siTrim64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < trim64.length; j++) s += eatText(sSiTrim(trim64[j]));
    }
    sink += s;
  },
  "prefix.fixedM64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < mega64.length; j++) s += eatText(prefixFixedM(mega64[j]));
    }
    sink += s;
  },
  "pct.percent64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < ratios64.length; j++) s += eatText(pctPercent(ratios64[j]));
    }
    sink += s;
  },
  "hex.prefix64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < hex64.length; j++) s += eatText(hexPrefix(hex64[j]));
    }
    sink += s;
  },
  "locale.frFR64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < floats64.length; j++) s += eatText(locFr(floats64[j]));
    }
    sink += s;
  },
  "locale.enIN64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < floats64.length; j++) s += eatText(locIn(floats64[j]));
    }
    sink += s;
  },
  "locale.arAE64": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < floats64.length; j++) s += eatText(locAr(floats64[j]));
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
