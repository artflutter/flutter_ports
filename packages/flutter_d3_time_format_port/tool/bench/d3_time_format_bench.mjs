// Original code, not ported from d3-time-format: upstream Node.js benchmark.

import fs from "node:fs";
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
const d3TimeUrl = pathToFileURL(
  path.join(repo, "third_party/d3-time/src/index.js"),
).href;

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "internmap") {
      return {shortCircuit: true, url: internmapUrl};
    }
    if (specifier === "d3-array") {
      return {shortCircuit: true, url: d3ArrayUrl};
    }
    if (specifier === "d3-time") {
      return {shortCircuit: true, url: d3TimeUrl};
    }
    return nextResolve(specifier, context);
  },
});

const {
  timeFormat,
  utcFormat,
  utcParse,
  isoFormat,
  isoParse,
  timeFormatLocale,
} = await import(
  pathToFileURL(path.join(repo, "third_party/d3-time-format/src/index.js")).href
);

const frDef = JSON.parse(
  fs.readFileSync(
    path.join(repo, "third_party/d3-time-format/locale/fr-FR.json"),
    "utf8",
  ),
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

const zoneSuffixes = ["+05:30", "-0800", "Z", "+02", "-0430"];
const r = new Lcg(42);
const spanMs = 80 * 365 * 86400 * 1000;
const utcDates = Array.from(
  {length: 1000},
  () => new Date(Math.floor(r.nextDouble() * spanMs)),
);

const fmtIso = utcFormat("%Y-%m-%dT%H:%M:%S.%LZ");
const fmtYmd = utcFormat("%Y-%m-%d");
const fmtYmdHms = utcFormat("%Y-%m-%d %H:%M:%S");
const fmtC = utcFormat("%c");
const fmtWords = utcFormat("%A, %B %e, %Y");
const fmtShortWords = utcFormat("%a, %d %b %Y %H:%M:%S");
const fmtWeeks = utcFormat("%G-W%V-%u %j %U %W");
const fmtLocal = timeFormat("%Y-%m-%d %H:%M:%S %Z");
const fr = timeFormatLocale(frDef);
const fmtFr = fr.utcFormat("%A %e %B %Y à %X");

const isoStrs = utcDates.map((d) => fmtIso(d));
const ymdStrs = utcDates.map((d) => fmtYmd(d));
const zoneStrs = utcDates.map(
  (d, i) => `${fmtYmdHms(d)} ${zoneSuffixes[i % zoneSuffixes.length]}`,
);
const wordStrs = utcDates.map((d) => fmtShortWords(d));
const cStrs = utcDates.map((d) => fmtC(d));
const frStrs = utcDates.map((d) => fmtFr(d));

const parseIsoSpec = utcParse("%Y-%m-%dT%H:%M:%S.%LZ");
const parseYmd = utcParse("%Y-%m-%d");
const parseZone = utcParse("%Y-%m-%d %H:%M:%S %Z");
const parseWords = utcParse("%a, %d %b %Y %H:%M:%S");
const parseC = utcParse("%c");
const parseFr = fr.utcParse("%A %e %B %Y à %X");

let sink = 0;

const cases = {
  "utcFormat.iso_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < utcDates.length; j++) {
        s += fmtIso(utcDates[j]).charCodeAt(18);
      }
    }
    sink += s;
  },
  "utcFormat.ymd_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < utcDates.length; j++) {
        s += fmtYmd(utcDates[j]).charCodeAt(9);
      }
    }
    sink += s;
  },
  "utcFormat.locale_c_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < utcDates.length; j++) {
        s += fmtC(utcDates[j]).length;
      }
    }
    sink += s;
  },
  "utcFormat.words_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < utcDates.length; j++) {
        s += fmtWords(utcDates[j]).length;
      }
    }
    sink += s;
  },
  "utcFormat.weeks_doy_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < utcDates.length; j++) {
        s += fmtWeeks(utcDates[j]).length;
      }
    }
    sink += s;
  },
  "timeFormat.local_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < utcDates.length; j++) {
        s += fmtLocal(utcDates[j]).charCodeAt(24);
      }
    }
    sink += s;
  },
  "isoFormat.1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < utcDates.length; j++) {
        s += isoFormat(utcDates[j]).charCodeAt(18);
      }
    }
    sink += s;
  },
  "utcParse.iso_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < isoStrs.length; j++) {
        s += +parseIsoSpec(isoStrs[j]);
      }
    }
    sink += s;
  },
  "utcParse.ymd_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < ymdStrs.length; j++) {
        s += +parseYmd(ymdStrs[j]);
      }
    }
    sink += s;
  },
  "utcParse.zone_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < zoneStrs.length; j++) {
        s += +parseZone(zoneStrs[j]);
      }
    }
    sink += s;
  },
  "utcParse.words_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < wordStrs.length; j++) {
        s += +parseWords(wordStrs[j]);
      }
    }
    sink += s;
  },
  "utcParse.locale_c_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < cStrs.length; j++) {
        s += +parseC(cStrs[j]);
      }
    }
    sink += s;
  },
  "utcParse.fr_words_1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < frStrs.length; j++) {
        s += +parseFr(frStrs[j]);
      }
    }
    sink += s;
  },
  "isoParse.1000": (n) => {
    let s = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < isoStrs.length; j++) {
        s += +isoParse(isoStrs[j]);
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
