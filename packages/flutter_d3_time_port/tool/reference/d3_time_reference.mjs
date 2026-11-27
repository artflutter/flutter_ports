// Original code, not ported from d3-time: Node.js reference vector generator.
//
// Run from repo root:
//   TZ=UTC node packages/flutter_d3_time_port/tool/reference/d3_time_reference.mjs

import fs from "node:fs";
import {registerHooks} from "node:module";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const pkg = path.resolve(here, "../..");
const repo = path.resolve(pkg, "../..");
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
  pathToFileURL(path.join(repo, "third_party/d3-time/src/index.js")).href
);

// Deterministic UTC dates spanning pre-epoch, leap years, century boundaries,
// first century, and far future.
const sampleMs = [
  Date.UTC(9, 10, 6, 7, 12, 34, 567),
  Date.UTC(1969, 11, 31, 23, 59, 59, 999),
  Date.UTC(1970, 0, 1, 0, 0, 0, 0),
  Date.UTC(1970, 0, 1, 0, 0, 0, 1),
  Date.UTC(1999, 11, 31, 23, 59, 59, 500),
  Date.UTC(2000, 1, 29, 12, 34, 56, 789),
  Date.UTC(2011, 2, 13, 8, 30, 15, 250),
  Date.UTC(2011, 10, 6, 7, 45, 59, 999),
  Date.UTC(2024, 1, 29, 0, 0, 0, 0),
  Date.UTC(2026, 10, 27, 13, 35, 39, 500),
  Date.UTC(2100, 0, 1, 0, 0, 0, 1),
];

const utcIntervals = [
  ["utcMillisecond", d3.utcMillisecond],
  ["utcSecond", d3.utcSecond],
  ["utcMinute", d3.utcMinute],
  ["utcHour", d3.utcHour],
  ["utcDay", d3.utcDay],
  ["unixDay", d3.unixDay],
  ["utcSunday", d3.utcSunday],
  ["utcMonday", d3.utcMonday],
  ["utcTuesday", d3.utcTuesday],
  ["utcWednesday", d3.utcWednesday],
  ["utcThursday", d3.utcThursday],
  ["utcFriday", d3.utcFriday],
  ["utcSaturday", d3.utcSaturday],
  ["utcMonth", d3.utcMonth],
  ["utcYear", d3.utcYear],
];

const unaryRecords = [];
for (const [name, iv] of utcIntervals) {
  for (const ms of sampleMs) {
    const d = new Date(ms);
    unaryRecords.push([
      name,
      ms,
      +iv.floor(d),
      +iv.ceil(d),
      +iv.round(d),
      +iv.offset(d, -3),
      +iv.offset(d, 0),
      +iv.offset(d, 5),
    ]);
  }
}

const countPairs = [
  [Date.UTC(1969, 0, 1), Date.UTC(1971, 0, 1)],
  [Date.UTC(1999, 11, 31, 23, 59), Date.UTC(2000, 2, 1, 0, 1)],
  [Date.UTC(2010, 11, 31, 23, 59, 59), Date.UTC(2012, 0, 1, 0, 0, 1)],
  [Date.UTC(2024, 0, 1), Date.UTC(2025, 0, 1)],
  [Date.UTC(2025, 0, 1), Date.UTC(2024, 0, 1)],
];

const countRecords = [];
for (const [name, iv] of utcIntervals) {
  for (const [a, b] of countPairs) {
    countRecords.push([name, a, b, iv.count(new Date(a), new Date(b))]);
  }
}

const rangeSpecs = [
  ["utcMillisecond", 50, Date.UTC(2020, 0, 1, 0, 0, 0, 920), Date.UTC(2020, 0, 1, 0, 0, 1, 180), 1],
  ["utcSecond", 15, Date.UTC(2020, 0, 1, 0, 0, 12), Date.UTC(2020, 0, 1, 0, 1, 45), 1],
  ["utcMinute", 15, Date.UTC(2020, 0, 1, 0, 7), Date.UTC(2020, 0, 1, 2, 15), 1],
  ["utcHour", 6, Date.UTC(2020, 0, 1, 3), Date.UTC(2020, 0, 3, 1), 1],
  ["utcDay", 3, Date.UTC(2019, 11, 28, 12), Date.UTC(2020, 0, 10, 12), 1],
  ["unixDay", 3, Date.UTC(2019, 11, 28, 12), Date.UTC(2020, 0, 10, 12), 1],
  ["utcSunday", 2, Date.UTC(2019, 11, 1), Date.UTC(2020, 2, 1), 1],
  ["utcMonday", 1, Date.UTC(2019, 11, 25), Date.UTC(2020, 1, 1), 2],
  ["utcMonth", 3, Date.UTC(2018, 10, 15), Date.UTC(2021, 3, 2), 1],
  ["utcYear", 5, Date.UTC(1998, 6, 1), Date.UTC(2027, 0, 1), 1],
];

const rangeRecords = [];
for (const [name, everyK, start, stop, step] of rangeSpecs) {
  const base = utcIntervals.find(([n]) => n === name)[1];
  const iv = everyK > 1 ? base.every(everyK) : base;
  const out = iv.range(new Date(start), new Date(stop), step).map((d) => +d);
  rangeRecords.push([name, everyK, start, stop, step, out]);
}

const tickSpecs = [
  [Date.UTC(2020, 0, 1, 0, 0, 0), Date.UTC(2020, 0, 1, 0, 0, 0, 500), 5],
  [Date.UTC(2020, 0, 1, 0, 0, 0), Date.UTC(2020, 0, 1, 0, 0, 10), 5],
  [Date.UTC(2020, 0, 1, 0, 0, 0), Date.UTC(2020, 0, 1, 0, 5, 0), 6],
  [Date.UTC(2020, 0, 1, 0, 0, 0), Date.UTC(2020, 0, 1, 18, 0, 0), 6],
  [Date.UTC(2020, 0, 1, 0, 0, 0), Date.UTC(2020, 0, 20, 0, 0, 0), 8],
  [Date.UTC(2020, 0, 1, 0, 0, 0), Date.UTC(2020, 5, 1, 0, 0, 0), 6],
  [Date.UTC(2020, 0, 1, 0, 0, 0), Date.UTC(2022, 0, 1, 0, 0, 0), 8],
  [Date.UTC(1960, 0, 1, 0, 0, 0), Date.UTC(2025, 0, 1, 0, 0, 0), 10],
  [Date.UTC(2025, 0, 1, 0, 0, 0), Date.UTC(2020, 0, 1, 0, 0, 0), 5],
  [Date.UTC(2020, 5, 1, 12, 0, 0), Date.UTC(2020, 5, 1, 12, 0, 0), 5],
  [Date.UTC(2020, 0, 1, 0, 0, 0), Date.UTC(2020, 0, 2, 0, 0, 0), 0],
  [Date.UTC(2020, 0, 1, 0, 0, 0), Date.UTC(2020, 0, 2, 0, 0, 0), -5],
];

const tickRecords = [];
for (const [start, stop, count] of tickSpecs) {
  const out = d3.utcTicks(new Date(start), new Date(stop), count).map((d) => +d);
  tickRecords.push([start, stop, count, out]);
}

const lines = [
  "// Original code, not ported from d3-time: Node.js reference vectors.",
  "// Generated by tool/reference/d3_time_reference.mjs for v3.1.0.",
  "",
  "/// `(intervalName, ms, floorMs, ceilMs, roundMs, offNeg3Ms, off0Ms, off5Ms)`.",
  "const List<(String, int, int, int, int, int, int, int)> refUnary = [",
  ...unaryRecords.map((r) => `  ('${r[0]}', ${r[1]}, ${r[2]}, ${r[3]}, ${r[4]}, ${r[5]}, ${r[6]}, ${r[7]}),`),
  "];",
  "",
  "/// `(intervalName, startMs, endMs, expectedCount)`.",
  "const List<(String, int, int, int)> refCounts = [",
  ...countRecords.map((r) => `  ('${r[0]}', ${r[1]}, ${r[2]}, ${r[3]}),`),
  "];",
  "",
  "/// `(intervalName, everyK, startMs, stopMs, step, expectedMs)`.",
  "const List<(String, int, int, int, int, List<int>)> refRanges = [",
  ...rangeRecords.map((r) => `  ('${r[0]}', ${r[1]}, ${r[2]}, ${r[3]}, ${r[4]}, <int>[${r[5].join(", ")}]),`),
  "];",
  "",
  "/// `(startMs, stopMs, count, expectedMs)`.",
  "const List<(int, int, int, List<int>)> refUtcTicks = [",
  ...tickRecords.map((r) => `  (${r[0]}, ${r[1]}, ${r[2]}, <int>[${r[3].join(", ")}]),`),
  "];",
  "",
];

const outPath = path.join(pkg, "test/port/d3_time_reference.dart");
fs.mkdirSync(path.dirname(outPath), {recursive: true});
fs.writeFileSync(outPath, lines.join("\n"));
console.log(
  `Wrote ${outPath} (${unaryRecords.length} unary, ${countRecords.length} counts, ${rangeRecords.length} ranges, ${tickRecords.length} ticks)`,
);
