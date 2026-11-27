// Original code, not ported from d3-array: Node.js reference data and test fixture generator.
//
// Writes:
//   - test/port/d3_array_reference.dart (Node.js parity data from upstream d3-array v3.2.4)
//   - test/port/test_data.dart (pure-Dart embedded athletes heights & barley dataset for web-safe tests)
//
// Run from packages/flutter_d3_array_port:
//   node tool/reference/d3_array_reference.mjs

import {readFileSync, writeFileSync} from "node:fs";
import {registerHooks} from "node:module";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const pkgRoot = path.resolve(here, "../..");
const repoRoot = path.resolve(pkgRoot, "../..");

const internmapUrl = pathToFileURL(
  path.join(repoRoot, "third_party/internmap/src/index.js"),
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
  pathToFileURL(path.join(repoRoot, "third_party/d3-array/src/index.js")).href
);

function fmtDouble(x) {
  if (x === undefined || x === null) return "null";
  if (Number.isNaN(x)) return "double.nan";
  if (x === Infinity) return "double.infinity";
  if (x === -Infinity) return "double.negativeInfinity";
  if (Object.is(x, -0)) return "-0.0";
  if (Number.isInteger(x) && Math.abs(x) <= 9007199254740991) {
    return String(x);
  }
  return String(x);
}

// 1. Generate test/port/test_data.dart (barley + athletes heights)
const barleyRaw = JSON.parse(
  readFileSync(path.join(repoRoot, "third_party/d3-array/test/data/barley.json"), "utf8"),
);
const athletesCsv = readFileSync(
  path.join(repoRoot, "third_party/d3-array/test/data/athletes.csv"),
  "utf8",
);
const csvLines = athletesCsv.trim().split(/\r?\n/);
const header = csvLines[0].split(",");
const heightCol = header.indexOf("height");
const heights = [];
for (let i = 1; i < csvLines.length; i++) {
  // Simple RFC-4180 CSV parser for athletes.csv
  const line = csvLines[i];
  let col = 0;
  let inQuotes = false;
  let start = 0;
  let val = "";
  for (let j = 0; j <= line.length; j++) {
    const ch = j < line.length ? line[j] : ",";
    if (ch === '"') {
      inQuotes = !inQuotes;
    } else if (ch === "," && !inQuotes) {
      if (col === heightCol) {
        val = line.slice(start, j).trim();
        break;
      }
      col++;
      start = j + 1;
    }
  }
  if (val) {
    const num = +val;
    if (!Number.isNaN(num)) heights.push(num);
  }
}

// Compress heights as run-length or compact int-cm (height * 100) for compact source
// Check exactness: all heights in athletes.csv are 2-decimal meters (e.g. 1.72)
const testDataLines = [
  "// Original code, not ported from d3-array: embedded upstream test datasets.",
  "",
  "/// Embedded `test/data/barley.json` and `test/data/athletes.csv` heights so",
  "/// upstream spec tests run identically on VM, Chrome JS, and Chrome Wasm",
  "/// without `dart:io`.",
  "library;",
  "",
  "/// A single record from `third_party/d3-array/test/data/barley.json`.",
  "typedef BarleyRow = ({double yield, String variety, int year, String site});",
  "",
  "/// All 120 rows of `third_party/d3-array/test/data/barley.json`.",
  "const List<BarleyRow> barleyData = <BarleyRow>[",
  ...barleyRaw.map(
    (r) =>
      `  (yield: ${fmtDouble(r.yield)}, variety: '${r.variety.replace(/'/g, "\\'")}', year: ${r.year}, site: '${r.site.replace(/'/g, "\\'")}'),`,
  ),
  "];",
  "",
  `/// All ${heights.length} non-empty athlete heights from \`athletes.csv\`.`,
  "const List<double> athleteHeights = <double>[",
];
for (let i = 0; i < heights.length; i += 12) {
  testDataLines.push("  " + heights.slice(i, i + 12).map(fmtDouble).join(", ") + ",");
}
testDataLines.push("];", "");
writeFileSync(path.join(pkgRoot, "test/port/test_data.dart"), testDataLines.join("\n"));

// 2. Generate test/port/d3_array_reference.dart (Node.js parity vectors)
let seed = 42;
function nextDouble() {
  seed = (seed * 48271) % 2147483647;
  return seed / 2147483647;
}

const sampleA = Array.from({length: 64}, () => (nextDouble() - 0.35) * 200);
const sampleB = Array.from({length: 64}, (_, i) =>
  i % 9 === 0 ? NaN : (nextDouble() - 0.5) * 1e6,
);
const fsumStress = [
  1, 1e100, 1, -1e100, 1e-100, 1e50, -1e50, -1e-100,
  0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1,
  1e20, 1, -1e20, 1e-15, 0.25, -0.25,
];
const ps = [0, 0.1, 0.25, 0.33, 0.5, 0.67, 0.75, 0.9, 1.0];

const tickCases = [
  [0, 10, 5],
  [0, 1, 10],
  [-1, 1, 5],
  [10, 0, 5],
  [0.1, 0.2, 4],
  [1, 1000, 7],
  [-123.45, 678.9, 8],
  [0.001, 0.009, 5],
  [1e6, 2e6, 5],
  [9.8, 13.2, 10],
  [0, 1, 1],
  [0, 1, 0],
];

const blur1Input = Array.from({length: 32}, (_, i) => (i === 15 ? 100.0 : (i % 5) * 3.5));
const blur1Radii = [0, 0.5, 1, 1.5, 2, 2.5, 3, 4.25];
const blur1Expected = blur1Radii.map((r) => d3.blur(blur1Input.slice(), r));

const blur2Input = Array.from({length: 9 * 7}, (_, i) => (i === 31 ? 50.0 : (i % 7) * 2.0));
const blur2Expected = [
  d3.blur2({data: blur2Input.slice(), width: 9, height: 7}, 1, 1).data,
  d3.blur2({data: blur2Input.slice(), width: 9, height: 7}, 1.5, 0.5).data,
  d3.blur2({data: blur2Input.slice(), width: 9, height: 7}, 2, 0).data,
  d3.blur2({data: blur2Input.slice(), width: 9, height: 7}, 0, 2).data,
];

const imgInput = new Uint8ClampedArray(6 * 5 * 4);
for (let i = 0; i < imgInput.length; i++) {
  imgInput[i] = (i * 37 + 13) & 255;
}
const imgExpected = Array.from(
  d3.blurImage({data: imgInput.slice(), width: 6, height: 5}, 1.5, 1).data,
);

const binA = d3.bin()(sampleA);
const binScott = d3.bin().thresholds(d3.thresholdScott)(sampleA);
const binFD = d3.bin().thresholds(d3.thresholdFreedmanDiaconis)(sampleA);

const refLines = [
  "// Original code, not ported from d3-array: generated Node.js reference data.",
  "",
  "/// Generated by `tool/reference/d3_array_reference.mjs` against upstream",
  "/// `d3-array` v3.2.4.",
  "library;",
  "",
  "const List<double> refSampleA = <double>[",
  "  " + sampleA.map(fmtDouble).join(", "),
  "];",
  "",
  "const List<double> refSampleB = <double>[",
  "  " + sampleB.map(fmtDouble).join(", "),
  "];",
  "",
  "const List<double> refFsumStress = <double>[",
  "  " + fsumStress.map(fmtDouble).join(", "),
  "];",
  "",
  `const int refCountA = ${d3.count(sampleA)};`,
  `const int refCountB = ${d3.count(sampleB)};`,
  `const double refSumA = ${fmtDouble(d3.sum(sampleA))};`,
  `const double refSumB = ${fmtDouble(d3.sum(sampleB))};`,
  `const double refFsumA = ${fmtDouble(d3.fsum(sampleA))};`,
  `const double refFsumStressResult = ${fmtDouble(d3.fsum(fsumStress))};`,
  `const double refMeanA = ${fmtDouble(d3.mean(sampleA))};`,
  `const double refMeanB = ${fmtDouble(d3.mean(sampleB))};`,
  `const double refVarianceA = ${fmtDouble(d3.variance(sampleA))};`,
  `const double refVarianceB = ${fmtDouble(d3.variance(sampleB))};`,
  `const double refDeviationA = ${fmtDouble(d3.deviation(sampleA))};`,
  `const double refDeviationB = ${fmtDouble(d3.deviation(sampleB))};`,
  `const double refMinA = ${fmtDouble(d3.min(sampleA))};`,
  `const double refMaxA = ${fmtDouble(d3.max(sampleA))};`,
  `const int refMinIndexB = ${d3.minIndex(sampleB)};`,
  `const int refMaxIndexB = ${d3.maxIndex(sampleB)};`,
  `const double refMedianA = ${fmtDouble(d3.median(sampleA))};`,
  `const int refMedianIndexA = ${d3.medianIndex(sampleA)};`,
  `const int refMedianIndexB = ${d3.medianIndex(sampleB)};`,
  "",
  "const List<double> refQuantilePs = <double>[",
  "  " + ps.map(fmtDouble).join(", "),
  "];",
  "const List<double> refQuantilesA = <double>[",
  "  " + ps.map((p) => fmtDouble(d3.quantile(sampleA, p))).join(", "),
  "];",
  "const List<double> refQuantilesB = <double>[",
  "  " + ps.map((p) => fmtDouble(d3.quantile(sampleB, p))).join(", "),
  "];",
  "const List<int> refQuantileIndicesA = <int>[",
  "  " + ps.map((p) => d3.quantileIndex(sampleA, p)).join(", "),
  "];",
  "",
  "const List<double> refCumsumA = <double>[",
  "  " + Array.from(d3.cumsum(sampleA)).map(fmtDouble).join(", "),
  "];",
  "const List<double> refFcumsumStress = <double>[",
  "  " + Array.from(d3.fcumsum(fsumStress)).map(fmtDouble).join(", "),
  "];",
  "",
  "const List<double> refRankB = <double>[",
  "  " + Array.from(d3.rank(sampleB)).map(fmtDouble).join(", "),
  "];",
  "",
  "const List<(double, double, double)> refTickCases = <(double, double, double)>[",
  ...tickCases.map(([a, b, c]) => `  (${fmtDouble(a)}, ${fmtDouble(b)}, ${fmtDouble(c)}),`),
  "];",
  "const List<List<double>> refTicksExpected = <List<double>>[",
  ...tickCases.map(([a, b, c]) => `  <double>[${d3.ticks(a, b, c).map(fmtDouble).join(", ")}],`),
  "];",
  "const List<double> refTickIncrementExpected = <double>[",
  "  " + tickCases.map(([a, b, c]) => fmtDouble(d3.tickIncrement(a, b, c))).join(", "),
  "];",
  "const List<double> refTickStepExpected = <double>[",
  "  " + tickCases.map(([a, b, c]) => fmtDouble(d3.tickStep(a, b, c))).join(", "),
  "];",
  "const List<(double, double)> refNiceExpected = <(double, double)>[",
  ...tickCases.map(([a, b, c]) => {
    const [n0, n1] = d3.nice(a, b, c);
    return `  (${fmtDouble(n0)}, ${fmtDouble(n1)}),`;
  }),
  "];",
  "",
  `const int refSturgesA = ${d3.thresholdSturges(sampleA)};`,
  `const int refScottA = ${d3.thresholdScott(sampleA, d3.min(sampleA), d3.max(sampleA))};`,
  `const int refFreedmanDiaconisA = ${d3.thresholdFreedmanDiaconis(sampleA, d3.min(sampleA), d3.max(sampleA))};`,
  "const List<(double, double, int)> refBinDefaultA = <(double, double, int)>[",
  ...binA.map((b) => `  (${fmtDouble(b.x0)}, ${fmtDouble(b.x1)}, ${b.length}),`),
  "];",
  "const List<(double, double, int)> refBinScottA = <(double, double, int)>[",
  ...binScott.map((b) => `  (${fmtDouble(b.x0)}, ${fmtDouble(b.x1)}, ${b.length}),`),
  "];",
  "const List<(double, double, int)> refBinFDA = <(double, double, int)>[",
  ...binFD.map((b) => `  (${fmtDouble(b.x0)}, ${fmtDouble(b.x1)}, ${b.length}),`),
  "];",
  "",
  "const List<double> refBlur1Input = <double>[",
  "  " + blur1Input.map(fmtDouble).join(", "),
  "];",
  "const List<double> refBlur1Radii = <double>[",
  "  " + blur1Radii.map(fmtDouble).join(", "),
  "];",
  "const List<List<double>> refBlur1Expected = <List<double>>[",
  ...blur1Expected.map((arr) => `  <double>[${arr.map(fmtDouble).join(", ")}],`),
  "];",
  "",
  "const List<double> refBlur2Input = <double>[",
  "  " + blur2Input.map(fmtDouble).join(", "),
  "];",
  "const List<List<double>> refBlur2Expected = <List<double>>[",
  ...blur2Expected.map((arr) => `  <double>[${arr.map(fmtDouble).join(", ")}],`),
  "];",
  "",
  "const List<int> refBlurImageInput = <int>[",
  "  " + Array.from(imgInput).join(", "),
  "];",
  "const List<int> refBlurImageExpected = <int>[",
  "  " + imgExpected.join(", "),
  "];",
  "",
];
writeFileSync(path.join(pkgRoot, "test/port/d3_array_reference.dart"), refLines.join("\n"));
console.log(`Generated test_data.dart (${barleyRaw.length} barley, ${heights.length} heights) and d3_array_reference.dart`);
