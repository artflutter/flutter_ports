// Original code, not ported from d3-contour: Node.js reference vector and
// embedded faithful.tsv generator.

import {readFileSync, writeFileSync} from "node:fs";
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

const d3Array = await import(d3ArrayUrl);
const d3Contour = await import(
  pathToFileURL(path.join(repo, "third_party/d3-contour/src/index.js")).href
);

// 1. Emit test/data/faithful_data.dart from third_party/d3-contour/test/data/faithful.tsv
const tsvPath = path.join(repo, "third_party/d3-contour/test/data/faithful.tsv");
const tsvLines = readFileSync(tsvPath, "utf8").trim().split(/\r?\n/);
const faithfulRows = tsvLines.slice(1).map((line) => {
  const [eruptions, waiting] = line.split("\t").map(Number);
  return {eruptions, waiting};
});

const faithfulDart = [
  "// Original code, not ported from d3-contour: embedded faithful.tsv data.",
  "",
  "/// One observation from `faithful.tsv`.",
  "typedef FaithfulRow = ({double eruptions, double waiting});",
  "",
  "/// The 272 Old Faithful observations from `test/data/faithful.tsv`.",
  "const List<FaithfulRow> faithfulData = <FaithfulRow>[",
  ...faithfulRows.map(
    (r) => `  (eruptions: ${r.eruptions}, waiting: ${r.waiting}),`,
  ),
  "];",
  "",
].join("\n");

writeFileSync(path.join(pkg, "test/data/faithful_data.dart"), faithfulDart);

// 2. Generate deterministic reference parity cases from upstream d3-contour v4.0.2.
function fmtNum(v) {
  if (Number.isNaN(v)) return "double.nan";
  if (v === Infinity) return "double.infinity";
  if (v === -Infinity) return "double.negativeInfinity";
  return Object.is(v, -0) ? "0.0" : String(v);
}

// Synthetic 24x18 multi-peak + crater topographic grid.
const w1 = 24;
const h1 = 18;
const peaksGrid = new Array(w1 * h1);
for (let y = 0; y < h1; y++) {
  for (let x = 0; x < w1; x++) {
    const dx1 = (x - 7.3) / 4.2;
    const dy1 = (y - 6.1) / 3.8;
    const dx2 = (x - 16.5) / 5.0;
    const dy2 = (y - 11.4) / 4.4;
    const dx3 = (x - 15.8) / 1.9;
    const dy3 = (y - 11.2) / 1.8;
    const v =
      100 * Math.exp(-(dx1 * dx1 + dy1 * dy1)) +
      125 * Math.exp(-(dx2 * dx2 + dy2 * dy2)) -
      70 * Math.exp(-(dx3 * dx3 + dy3 * dy3)) +
      12 * Math.sin(x * 0.45) * Math.cos(y * 0.4);
    peaksGrid[y * w1 + x] = v;
  }
}

const peaksSmooth = d3Contour.contours().size([w1, h1]).thresholds(8)(peaksGrid);
const peaksRaw = d3Contour
  .contours()
  .size([w1, h1])
  .smooth(false)
  .thresholds([20, 50, 80])(peaksGrid);

// Saddle ambiguity & NaN/Infinity grid (12x10).
const w2 = 12;
const h2 = 10;
const specialGrid = new Array(w2 * h2);
for (let y = 0; y < h2; y++) {
  for (let x = 0; x < w2; x++) {
    specialGrid[y * w2 + x] = ((x + y) % 2 === 0 ? 1.5 : -0.5) + (x * 0.1 - y * 0.05);
  }
}
specialGrid[2 * w2 + 3] = NaN;
specialGrid[5 * w2 + 6] = -Infinity;
specialGrid[7 * w2 + 8] = Infinity;
const specialContour = d3Contour.contours().size([w2, h2]).contour(specialGrid, 0.4);

// Density contours on faithful.tsv with bandwidth=30, cellSize=4.
const width = 960;
const height = 500;
const wExt = d3Array.extent(faithfulRows, (d) => d.waiting);
const eExt = d3Array.extent(faithfulRows, (d) => d.eruptions);
const [wd0, wd1] = d3Array.nice(wExt[0], wExt[1], 10);
const [ed0, ed1] = d3Array.nice(eExt[0], eExt[1], 10);
const sx = (v) => Math.round(40 + ((v - wd0) / (wd1 - wd0)) * (width - 30 - 40));
const sy = (v) => Math.round(height - 30 + ((v - ed0) / (ed1 - ed0)) * (20 - (height - 30)));

const faithfulContours = d3Contour
  .contourDensity()
  .x((d) => sx(d.waiting))
  .y((d) => sy(d.eruptions))
  .size([width, height])
  .bandwidth(30)
  .thresholds(10)(faithfulRows);

const faithfulEvaluator = d3Contour
  .contourDensity()
  .x((d) => sx(d.waiting))
  .y((d) => sy(d.eruptions))
  .size([width, height])
  .bandwidth(30)
  .contours(faithfulRows);

const faithfulSingle = faithfulEvaluator(0.0025);

// Weighted density contours with cellSize=8, bandwidth=18.
const weightedPoints = [
  [40, 50, 2.5],
  [55, 62, 1.0],
  [48, 54, 3.0],
  [140, 120, 4.0],
  [148, 125, NaN],
  [135, 118, 2.0],
  [142, 130, -0.5],
];
const weightedDensity = d3Contour
  .contourDensity()
  .x((d) => d[0])
  .y((d) => d[1])
  .weight((d) => d[2])
  .size([200, 180])
  .cellSize(8)
  .bandwidth(18)
  .thresholds(6)(weightedPoints);

function encodeMultiPolygon(mp) {
  const polys = mp.coordinates
    .map(
      (poly) =>
        `<List<(double, double)>>[\n${poly
          .map(
            (ring) =>
              `      <(double, double)>[${ring.map((p) => `(${fmtNum(p[0])}, ${fmtNum(p[1])})`).join(", ")}],`,
          )
          .join("\n")}\n    ]`,
    )
    .join(",\n    ");
  return `(value: ${fmtNum(mp.value)}, coordinates: <List<List<(double, double)>>>[\n    ${polys}\n  ])`;
}

// Summaries for large density outputs (plus full coordinates for exact samples).
function summarizeContours(list) {
  return list.map((mp) => {
    let ringCount = 0;
    let pointCount = 0;
    let sumX = 0;
    let sumY = 0;
    for (const poly of mp.coordinates) {
      ringCount += poly.length;
      for (const ring of poly) {
        pointCount += ring.length;
        for (const p of ring) {
          sumX += p[0];
          sumY += p[1];
        }
      }
    }
    return {
      value: mp.value,
      polygons: mp.coordinates.length,
      rings: ringCount,
      points: pointCount,
      sumX,
      sumY,
    };
  });
}

function encodeSummaries(summaries) {
  return summaries
    .map(
      (s) =>
        `  (value: ${fmtNum(s.value)}, polygons: ${s.polygons}, rings: ${s.rings}, points: ${s.points}, sumX: ${fmtNum(s.sumX)}, sumY: ${fmtNum(s.sumY)}),`,
    )
    .join("\n");
}

const refDart = `// Original code, not ported from d3-contour: Node.js v4.0.2 reference vectors.
// Generated by tool/reference/generate_reference.mjs — do not edit by hand.

/// Expected contour geometry record.
typedef RefContour = ({
  double value,
  List<List<List<(double, double)>>> coordinates,
});

/// Expected contour summary record.
typedef RefContourSummary = ({
  double value,
  int polygons,
  int rings,
  int points,
  double sumX,
  double sumY,
});

const int refPeaksW = ${w1};
const int refPeaksH = ${h1};

const List<double> refPeaksGrid = <double>[
  ${peaksGrid.map(fmtNum).join(", ")}
];

const List<RefContour> refPeaksSmooth = <RefContour>[
  ${peaksSmooth.map(encodeMultiPolygon).join(",\n  ")}
];

const List<RefContour> refPeaksRaw = <RefContour>[
  ${peaksRaw.map(encodeMultiPolygon).join(",\n  ")}
];

const int refSpecialW = ${w2};
const int refSpecialH = ${h2};

const List<double> refSpecialGrid = <double>[
  ${specialGrid.map(fmtNum).join(", ")}
];

const RefContour refSpecialContour = ${encodeMultiPolygon(specialContour)};

const double refFaithfulMax = ${fmtNum(faithfulEvaluator.max)};

const List<RefContourSummary> refFaithfulContoursSummary = <RefContourSummary>[
${encodeSummaries(summarizeContours(faithfulContours))}
];

const RefContourSummary refFaithfulSingleSummary = (
  value: ${fmtNum(faithfulSingle.value)},
  polygons: ${faithfulSingle.coordinates.length},
  rings: ${summarizeContours([faithfulSingle])[0].rings},
  points: ${summarizeContours([faithfulSingle])[0].points},
  sumX: ${fmtNum(summarizeContours([faithfulSingle])[0].sumX)},
  sumY: ${fmtNum(summarizeContours([faithfulSingle])[0].sumY)},
);

const List<(double, double, double)> refWeightedPoints = <(double, double, double)>[
  ${weightedPoints.map((p) => `(${fmtNum(p[0])}, ${fmtNum(p[1])}, ${fmtNum(p[2])})`).join(",\n  ")},
];

const List<RefContourSummary> refWeightedDensitySummary = <RefContourSummary>[
${encodeSummaries(summarizeContours(weightedDensity))}
];
`;

writeFileSync(path.join(pkg, "test/port/d3_contour_reference.dart"), refDart);
console.log(
  `Generated faithful_data.dart (${faithfulRows.length} rows) and d3_contour_reference.dart`,
);
