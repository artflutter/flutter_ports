// Original code, not ported from d3-shape: the reference data generator.
//
// Writes test/port/d3_shape_reference.dart from upstream d3-shape v3.2.0
// (third_party/d3-shape/src/, ESM) with third_party/d3-path/src/index.js
// on Node.js.
//
// Run from packages/flutter_d3_shape_port:
//
//   node tool/reference/d3_shape_reference.mjs

import {writeFileSync} from "node:fs";
import {registerHooks} from "node:module";
import path from "node:path";
import {fileURLToPath, pathToFileURL} from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(here, "../../../..");
const d3PathUrl = pathToFileURL(
  path.join(repoRoot, "third_party/d3-path/src/index.js"),
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
  pathToFileURL(path.join(repoRoot, "third_party/d3-shape/src/index.js")).href
);

// Fixed dataset for line/area curves.
const points = [
  [0, 10],
  [20, 45],
  [45, 25],
  [70, 80],
  [100, 35],
  [135, 65],
  [170, 15],
  [200, 50],
];

const areaPoints = [
  [0, 10, 40],
  [25, 22, 65],
  [55, 15, 50],
  [90, 30, 95],
  [120, 18, 70],
  [160, 25, 85],
];

const radialPoints = [
  [0, 30],
  [Math.PI / 3, 55],
  [(2 * Math.PI) / 3, 40],
  [Math.PI, 75],
  [(4 * Math.PI) / 3, 45],
  [(5 * Math.PI) / 3, 60],
];

const lineCurves = {
  linear: d3.curveLinear,
  linearClosed: d3.curveLinearClosed,
  basis: d3.curveBasis,
  basisClosed: d3.curveBasisClosed,
  basisOpen: d3.curveBasisOpen,
  bundle05: d3.curveBundle.beta(0.5),
  bumpX: d3.curveBumpX,
  bumpY: d3.curveBumpY,
  cardinal04: d3.curveCardinal.tension(0.4),
  cardinalClosed04: d3.curveCardinalClosed.tension(0.4),
  cardinalOpen04: d3.curveCardinalOpen.tension(0.4),
  catmullRom0: d3.curveCatmullRom.alpha(0),
  catmullRom05: d3.curveCatmullRom.alpha(0.5),
  catmullRom1: d3.curveCatmullRom.alpha(1),
  catmullRomClosed05: d3.curveCatmullRomClosed.alpha(0.5),
  catmullRomOpen05: d3.curveCatmullRomOpen.alpha(0.5),
  monotoneX: d3.curveMonotoneX,
  monotoneY: d3.curveMonotoneY,
  natural: d3.curveNatural,
  step: d3.curveStep,
  stepBefore: d3.curveStepBefore,
  stepAfter: d3.curveStepAfter,
};

const lineRefs = {};
for (const [name, curve] of Object.entries(lineCurves)) {
  lineRefs[name] = d3.line().curve(curve)(points);
}

// Line with gap (defined false at index 3).
lineRefs.withGap = d3
  .line()
  .defined((_, i) => i !== 3)
  .curve(d3.curveMonotoneX)(points);

const areaCurves = {
  linear: d3.curveLinear,
  linearClosed: d3.curveLinearClosed,
  basis: d3.curveBasis,
  basisClosed: d3.curveBasisClosed,
  basisOpen: d3.curveBasisOpen,
  bumpX: d3.curveBumpX,
  bumpY: d3.curveBumpY,
  cardinal04: d3.curveCardinal.tension(0.4),
  cardinalClosed04: d3.curveCardinalClosed.tension(0.4),
  cardinalOpen04: d3.curveCardinalOpen.tension(0.4),
  catmullRom05: d3.curveCatmullRom.alpha(0.5),
  catmullRomClosed05: d3.curveCatmullRomClosed.alpha(0.5),
  catmullRomOpen05: d3.curveCatmullRomOpen.alpha(0.5),
  monotoneX: d3.curveMonotoneX,
  monotoneY: d3.curveMonotoneY,
  natural: d3.curveNatural,
  step: d3.curveStep,
  stepBefore: d3.curveStepBefore,
  stepAfter: d3.curveStepAfter,
};

const areaRefs = {};
for (const [name, curve] of Object.entries(areaCurves)) {
  areaRefs[name] = d3
    .area()
    .x((d) => d[0])
    .y0((d) => d[1])
    .y1((d) => d[2])
    .curve(curve)(areaPoints);
}

const radialRefs = {
  lineLinear: d3.lineRadial()(radialPoints),
  lineBasisClosed: d3.lineRadial().curve(d3.curveBasisClosed)(radialPoints),
  lineNatural: d3.lineRadial().curve(d3.curveNatural)(radialPoints),
  lineCardinalClosed: d3.lineRadial().curve(d3.curveCardinalClosed)(radialPoints),
  lineCatmullRomClosed: d3.lineRadial().curve(d3.curveCatmullRomClosed)(radialPoints),
  areaLinear: d3
    .areaRadial()
    .angle((d) => d[0])
    .innerRadius((d) => d[1] * 0.5)
    .outerRadius((d) => d[1])(radialPoints),
  areaBasis: d3
    .areaRadial()
    .angle((d) => d[0])
    .innerRadius((d) => d[1] * 0.5)
    .outerRadius((d) => d[1])
    .curve(d3.curveBasis)(radialPoints),
};

const arcRefs = {
  sector: d3.arc()({
    innerRadius: 0,
    outerRadius: 100,
    startAngle: 0,
    endAngle: Math.PI / 2,
  }),
  annulus: d3.arc()({
    innerRadius: 40,
    outerRadius: 100,
    startAngle: 0.2,
    endAngle: 1.9,
  }),
  roundedPadded: d3.arc().cornerRadius(12).padAngle(0.04)({
    innerRadius: 45,
    outerRadius: 100,
    startAngle: 0.1,
    endAngle: 1.4,
  }),
  fullCircle: d3.arc()({
    innerRadius: 30,
    outerRadius: 90,
    startAngle: 0,
    endAngle: Math.PI * 2,
  }),
  padRadius: d3.arc().padRadius(80).padAngle(0.05).cornerRadius(8)({
    innerRadius: 20,
    outerRadius: 100,
    startAngle: -0.5,
    endAngle: 1.2,
  }),
};

const arcCentroids = {
  annulus: d3.arc().centroid({
    innerRadius: 40,
    outerRadius: 100,
    startAngle: 0.2,
    endAngle: 1.9,
  }),
  sector: d3.arc().centroid({
    innerRadius: 0,
    outerRadius: 100,
    startAngle: 0,
    endAngle: Math.PI / 2,
  }),
};

const pieData = [1, 1, 2, 3, 5, 8, 13, 21];
const pieDefault = d3.pie()(pieData);
const piePadded = d3
  .pie()
  .startAngle(-Math.PI / 2)
  .endAngle(Math.PI / 2)
  .padAngle(0.03)
  .sort(null)(pieData);

const linkDatum = {source: [10, 20], target: [150, 90]};
const linkRadialDatum = {source: [0.3, 40], target: [2.1, 120]};
const linkRefs = {
  horizontal: d3.linkHorizontal()(linkDatum),
  vertical: d3.linkVertical()(linkDatum),
  radial: d3.linkRadial()(linkRadialDatum),
};

const symbolNames = [
  ["circle", d3.symbolCircle],
  ["cross", d3.symbolCross],
  ["diamond", d3.symbolDiamond],
  ["square", d3.symbolSquare],
  ["star", d3.symbolStar],
  ["triangle", d3.symbolTriangle],
  ["wye", d3.symbolWye],
  ["times", d3.symbolTimes],
  ["plus", d3.symbolPlus],
  ["asterisk", d3.symbolAsterisk],
  ["diamond2", d3.symbolDiamond2],
  ["square2", d3.symbolSquare2],
  ["triangle2", d3.symbolTriangle2],
];

const symbolRefs = {};
for (const [name, type] of symbolNames) {
  symbolRefs[`${name}_64`] = d3.symbol(type, 64)();
  symbolRefs[`${name}_250`] = d3.symbol(type, 250)();
}

const stackData = [
  {a: 10, b: 25, c: 5, d: 15},
  {a: 30, b: 10, c: 20, d: 5},
  {a: 15, b: 35, c: 10, d: 25},
  {a: 5, b: 15, c: 40, d: 10},
  {a: 25, b: 5, c: 15, d: 30},
];

const stackDivergingData = [
  {a: 10, b: -5, c: 20, d: -15},
  {a: -10, b: 15, c: -5, d: 25},
  {a: 5, b: 10, c: -20, d: 5},
];

const stackOffsets = {
  none: d3.stackOffsetNone,
  expand: d3.stackOffsetExpand,
  silhouette: d3.stackOffsetSilhouette,
  wiggle: d3.stackOffsetWiggle,
};

const stackOrders = {
  none: d3.stackOrderNone,
  ascending: d3.stackOrderAscending,
  descending: d3.stackOrderDescending,
  appearance: d3.stackOrderAppearance,
  insideOut: d3.stackOrderInsideOut,
  reverse: d3.stackOrderReverse,
};

const stackRefs = {};
for (const [oName, offset] of Object.entries(stackOffsets)) {
  for (const [rName, order] of Object.entries(stackOrders)) {
    const res = d3
      .stack()
      .keys(["a", "b", "c", "d"])
      .offset(offset)
      .order(order)(stackData);
    stackRefs[`${oName}_${rName}`] = res.map((s) => ({
      key: s.key,
      index: s.index,
      points: s.map((p) => [p[0], p[1]]),
    }));
  }
}

stackRefs.diverging_none = d3
  .stack()
  .keys(["a", "b", "c", "d"])
  .offset(d3.stackOffsetDiverging)(stackDivergingData)
  .map((s) => ({
    key: s.key,
    index: s.index,
    points: s.map((p) => [p[0], p[1]]),
  }));

function fmtDouble(n) {
  if (Object.is(n, -0)) return "-0.0";
  const s = String(n);
  return s.includes(".") || s.includes("e") ? s : `${s}.0`;
}

function mapEntries(obj) {
  return Object.entries(obj).map(([k, v]) => `  '${k}': '${v}',`);
}

function pieEntries(arcs) {
  return arcs.map(
    (a) =>
      `  (data: ${a.data}, index: ${a.index}, value: ${fmtDouble(a.value)}, ` +
      `startAngle: ${fmtDouble(a.startAngle)}, endAngle: ${fmtDouble(a.endAngle)}, ` +
      `padAngle: ${fmtDouble(a.padAngle)}),`,
  );
}

const lines = [
  "// Original code, not ported from d3-shape: generated reference data.",
  "// Generated by tool/reference/d3_shape_reference.mjs",
  `// on Node.js ${process.version} (V8 ${process.versions.v8}, ${process.platform}-${process.arch}).`,
  "// Generated data rows exceed 80 chars.",
  "// ignore_for_file: lines_longer_than_80_chars",
  "",
  "/// Upstream `line()` outputs across all curves and gap handling.",
  "const Map<String, String> referenceLines = {",
  ...mapEntries(lineRefs),
  "};",
  "",
  "/// Upstream `area()` outputs across all area curves.",
  "const Map<String, String> referenceAreas = {",
  ...mapEntries(areaRefs),
  "};",
  "",
  "/// Upstream `lineRadial()` and `areaRadial()` outputs.",
  "const Map<String, String> referenceRadials = {",
  ...mapEntries(radialRefs),
  "};",
  "",
  "/// Upstream `arc()` outputs.",
  "const Map<String, String> referenceArcs = {",
  ...mapEntries(arcRefs),
  "};",
  "",
  "/// Upstream `arc().centroid(...)` outputs.",
  "const Map<String, (double, double)> referenceArcCentroids = {",
  ...Object.entries(arcCentroids).map(
    ([k, [x, y]]) => `  '${k}': (${fmtDouble(x)}, ${fmtDouble(y)}),`,
  ),
  "};",
  "",
  "/// Upstream `pie()` default outputs.",
  "const List<({int data, int index, double value, double startAngle, double endAngle, double padAngle})> referencePieDefault = [",
  ...pieEntries(pieDefault),
  "];",
  "",
  "/// Upstream `pie()` padded half-circle unsorted outputs.",
  "const List<({int data, int index, double value, double startAngle, double endAngle, double padAngle})> referencePiePadded = [",
  ...pieEntries(piePadded),
  "];",
  "",
  "/// Upstream `linkHorizontal`, `linkVertical`, and `linkRadial` outputs.",
  "const Map<String, String> referenceLinks = {",
  ...mapEntries(linkRefs),
  "};",
  "",
  "/// Upstream `symbol()` outputs for all 13 symbols at size 64 and 250.",
  "const Map<String, String> referenceSymbols = {",
  ...mapEntries(symbolRefs),
  "};",
  "",
  "/// Upstream `stack()` outputs across all offsets and orders.",
  "const Map<String, List<({String key, int index, List<(double, double)> points})>> referenceStacks = {",
  ...Object.entries(stackRefs).flatMap(([name, seriesList]) => [
    `  '${name}': [`,
    ...seriesList.map(
      (s) =>
        `    (key: '${s.key}', index: ${s.index}, points: [${s.points.map(([y0, y1]) => `(${fmtDouble(y0)}, ${fmtDouble(y1)})`).join(", ")}]),`,
    ),
    "  ],",
  ]),
  "};",
];

const outPath = path.join(here, "../../test/port/d3_shape_reference.dart");
writeFileSync(outPath, `${lines.join("\n")}\n`);
console.log(`Wrote ${outPath} (${lines.length} lines).`);
