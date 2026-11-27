// Original code, not ported from d3-time-format: Node.js reference generator.
//
// Run from repo root:
//   TZ=UTC node packages/flutter_d3_time_format_port/tool/reference/d3_time_format_reference.mjs

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

const d3 = await import(
  pathToFileURL(path.join(repo, "third_party/d3-time-format/src/index.js")).href
);

function utcDate(y, m, d, H = 0, M = 0, S = 0, L = 0) {
  if (0 <= y && y < 100) {
    const dt = new Date(Date.UTC(-1, m, d, H, M, S, L));
    dt.setUTCFullYear(y);
    return dt;
  }
  return new Date(Date.UTC(y, m, d, H, M, S, L));
}

const sampleDates = [
  utcDate(-2, 0, 1, 0, 0, 0, 0),
  utcDate(9, 10, 6, 7, 12, 34, 567),
  utcDate(123, 5, 15, 0, 5, 9, 42),
  utcDate(1969, 11, 31, 23, 59, 59, 999),
  utcDate(1970, 0, 1, 0, 0, 0, 0),
  utcDate(1990, 0, 1, 0, 0, 0, 0),
  utcDate(2000, 1, 29, 12, 34, 56, 789),
  utcDate(2012, 0, 1, 0, 0, 0, 0),
  utcDate(2015, 11, 31, 23, 59, 59, 1),
  utcDate(2016, 0, 1, 0, 0, 0, 0),
  utcDate(2018, 11, 30, 0, 0, 0, 0),
  utcDate(2018, 11, 31, 0, 0, 0, 0),
  utcDate(2024, 5, 15, 14, 37, 22, 432),
  utcDate(10002, 0, 1, 0, 0, 0, 0),
];

const specifiers = [
  "%Y-%m-%dT%H:%M:%S.%LZ",
  "%a %A %b %B %p %q",
  "%d %e %-d %_d %0d %0e %-e",
  "%H %I %-I %M %S %-S %_S %L %-L %f %-f",
  "%j %u %w %U %W %V %g %G %y %Y %Z %%",
  "%Q %s %s.%L %s.%f",
  "%c",
  "%x",
  "%X",
  "prefix-%k-suffix-%",
];

const formatVectors = [];
for (const spec of specifiers) {
  const f = d3.utcFormat(spec);
  for (const dt of sampleDates) {
    formatVectors.push([spec, +dt, f(dt)]);
  }
}

const isoVectors = sampleDates.map((dt) => [+dt, d3.isoFormat(dt)]);

const parseCases = [
  ["%Y-%m-%dT%H:%M:%S.%LZ", "2024-06-15T14:37:22.432Z"],
  ["%Y-%m-%d %H:%M:%S %Z", "2024-06-15 14:37:22 +0530"],
  ["%Y-%m-%d %H:%M:%S %Z", "2024-06-15 14:37:22 -08:00"],
  ["%Y-%m-%d %H:%M:%S %Z", "2024-06-15 14:37:22 +02"],
  ["%Y-%m-%d %H:%M:%S %Z", "2024-06-15 14:37:22 Z"],
  ["%a, %d %b %Y %H:%M:%S %Z", "Sat, 15 Jun 2024 14:37:22 +0000"],
  ["%A, %B %e, %Y %I:%M:%S %p", "Saturday, June 15, 2024 02:37:22 PM"],
  ["%A, %B %e, %Y %I:%M:%S %p", "Monday, January  1, 1990 12:00:00 am"],
  ["%Y-%j", "2024-060"],
  ["%Y-W%V-%u", "2019-W01-1"],
  ["%G-W%V-%w", "2019-W01-1"],
  ["%Y-%U-%w", "2012-01-0"],
  ["%Y-%W-%u", "1990-01-1"],
  ["%Y-Q%q", "2024-Q3"],
  ["%m/%d/%y", "02/03/69"],
  ["%m/%d/%y", "02/03/68"],
  ["%Q", "1718462242432"],
  ["%s.%L", "1718462242.432"],
  ["%s.%f", "1718462242.432999"],
  ["%c", "6/15/2024, 2:37:22 PM"],
  ["%Y-%m-%d", "not-a-date"],
  ["%V %Y", "00 2024"],
  ["%V %Y", "54 2024"],
  ["%Y-%m-%d %Z", "2024-06-15 +01:3"],
];

const parseVectors = parseCases.map(([spec, input]) => {
  const res = d3.utcParse(spec)(input);
  return [spec, input, res === null ? null : +res];
});

const isoParseInputs = [
  "1990-01-01T00:00:00.000Z",
  "2011-12-31T23:59:59.000Z",
  "2024-06-15T14:37:22.432Z",
  "2024-06-15T14:37:22Z",
  "2024-06-15T14:37:22+05:30",
  "2024-06-15T14:37:22-08:00",
  "2024-06-15",
  "1990-01-01T00:00:00.000X",
  "invalid",
  "",
];
const isoParseVectors = isoParseInputs.map((input) => {
  const res = d3.isoParse(input);
  return [input, res === null ? null : +res];
});

const localeDir = path.join(repo, "third_party/d3-time-format/locale");
const localeFiles = fs.readdirSync(localeDir).filter((f) => f.endsWith(".json")).sort();
const localeDate = utcDate(2024, 5, 15, 14, 37, 22, 432);
const localeDate2 = utcDate(2024, 6, 7, 9, 5, 3, 12); // Sunday July 7 (tests cs-CZ červenec & tr-TR Pazar)
const localeVectors = [];
for (const file of localeFiles) {
  const tag = file.slice(0, -5);
  const def = JSON.parse(fs.readFileSync(path.join(localeDir, file), "utf8"));
  const loc = d3.timeFormatLocale(def);
  for (const dt of [localeDate, localeDate2]) {
    const cStr = loc.utcFormat("%c")(dt);
    const xStr = loc.utcFormat("%x")(dt);
    const XStr = loc.utcFormat("%X")(dt);
    const abStr = loc.utcFormat("%A %a %B %b %p")(dt);
    const parsedC = loc.utcParse("%c")(cStr);
    const parsedFull = loc.utcParse("%B %d, %Y")(loc.utcFormat("%B %d, %Y")(dt));
    localeVectors.push([
      tag,
      +dt,
      cStr,
      xStr,
      XStr,
      abStr,
      parsedC === null ? null : +parsedC,
      parsedFull === null ? null : +parsedFull,
    ]);
  }
}

const esc = (s) =>
  "'" + s.replace(/\\/g, "\\\\").replace(/'/g, "\\'").replace(/\$/g, "\\$") + "'";

const lines = [
  "// Original code, not ported from d3-time-format: Node.js reference vectors.",
  "// Generated by tool/reference/d3_time_format_reference.mjs for v4.1.0.",
  "",
  "/// `(specifier, ms, expectedOutput)`.",
  "const List<(String, int, String)> refUtcFormat = [",
  ...formatVectors.map(([s, ms, out]) => `  (${esc(s)}, ${ms}, ${esc(out)}),`),
  "];",
  "",
  "/// `(ms, expectedIso)`.",
  "const List<(int, String)> refIsoFormat = [",
  ...isoVectors.map(([ms, out]) => `  (${ms}, ${esc(out)}),`),
  "];",
  "",
  "/// `(specifier, input, expectedMsOrNull)`.",
  "const List<(String, String, int?)> refUtcParse = [",
  ...parseVectors.map(([s, inp, ms]) => `  (${esc(s)}, ${esc(inp)}, ${ms}),`),
  "];",
  "",
  "/// `(input, expectedMsOrNull)`.",
  "const List<(String, int?)> refIsoParse = [",
  ...isoParseVectors.map(([inp, ms]) => `  (${esc(inp)}, ${ms}),`),
  "];",
  "",
  "/// `(tag, ms, cOut, xOut, XOut, abOut, parsedCMs, parsedFullMs)`.",
  "const List<(String, int, String, String, String, String, int?, int?)> refLocales = [",
  ...localeVectors.map(
    ([tag, ms, c, x, X, ab, pc, pf]) =>
      `  (${esc(tag)}, ${ms}, ${esc(c)}, ${esc(x)}, ${esc(X)}, ${esc(ab)}, ${pc}, ${pf}),`,
  ),
  "];",
  "",
];

const outPath = path.join(pkg, "test/port/d3_time_format_reference.dart");
fs.mkdirSync(path.dirname(outPath), {recursive: true});
fs.writeFileSync(outPath, lines.join("\n"));
console.log(
  `Wrote ${outPath} (${formatVectors.length} fmt, ${isoVectors.length} iso, ${parseVectors.length} parse, ${isoParseVectors.length} isoParse, ${localeVectors.length} locale vectors)`,
);
