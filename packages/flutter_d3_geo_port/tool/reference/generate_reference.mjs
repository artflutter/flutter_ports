// Original code, not ported from d3-geo: Node.js fixture & reference generator.

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

const d3 = await import(
  pathToFileURL(path.join(repo, "third_party/d3-geo/src/index.js")).href
);

// --- 1. Decode us-10m.json objects.land (TopoJSON -> GeoJSON MultiPolygon) ---
const usTopo = JSON.parse(
  readFileSync(path.join(repo, "third_party/d3-geo/test/data/us-10m.json"), "utf8"),
);

function decodeArc(topology, arcIndex) {
  const rev = arcIndex < 0;
  const idx = rev ? ~arcIndex : arcIndex;
  const raw = topology.arcs[idx];
  const {scale, translate} = topology.transform;
  const pts = [];
  let x = 0;
  let y = 0;
  for (let i = 0; i < raw.length; ++i) {
    x += raw[i][0];
    y += raw[i][1];
    pts.push([x * scale[0] + translate[0], y * scale[1] + translate[1]]);
  }
  if (rev) pts.reverse();
  return pts;
}

function decodeRing(topology, arcIndices) {
  const pts = [];
  for (let i = 0; i < arcIndices.length; ++i) {
    const seg = decodeArc(topology, arcIndices[i]);
    if (i > 0) seg.shift();
    for (let j = 0; j < seg.length; ++j) pts.push(seg[j]);
  }
  return pts;
}

const usLandPolygons = usTopo.objects.land.arcs.map((poly) =>
  poly.map((ring) => decodeRing(usTopo, ring)),
);
const usLandGeoJson = {
  type: "Feature",
  geometry: {type: "MultiPolygon", coordinates: usLandPolygons},
};

// Verify us-10m fitExtent matches upstream fit-test.js:110-115
const albersCheck = d3.geoAlbersUsa().fitExtent([[50, 50], [950, 950]], usLandGeoJson);
console.log("usLand albersUsa check:", albersCheck.scale(), albersCheck.translate());

// Write compact quantized us_land_data.dart using exact TopoJSON transform + arcs
// Only include arcs actually used by objects.land to keep file small!
const usUsedArcMap = new Map();
const usUsedArcs = [];
const usRemappedPolys = usTopo.objects.land.arcs.map((poly) =>
  poly.map((ring) =>
    ring.map((a) => {
      const rev = a < 0;
      const idx = rev ? ~a : a;
      let newIdx = usUsedArcMap.get(idx);
      if (newIdx === undefined) {
        newIdx = usUsedArcs.length;
        usUsedArcMap.set(idx, newIdx);
        usUsedArcs.push(usTopo.arcs[idx]);
      }
      return rev ? ~newIdx : newIdx;
    }),
  ),
);

function writeUsLandDart() {
  const flatArcs = [];
  const arcOffsets = [0];
  for (const arc of usUsedArcs) {
    for (const [dx, dy] of arc) {
      flatArcs.push(dx, dy);
    }
    arcOffsets.push(flatArcs.length);
  }
  const lines = [
    "// Original code, not ported from d3-geo: embedded us-10m land fixture.",
    "",
    "import 'dart:typed_data';",
    "",
    "import 'package:flutter_d3_geo_port/d3_geo.dart';",
    "",
    `const double _sx = ${usTopo.transform.scale[0]};`,
    `const double _sy = ${usTopo.transform.scale[1]};`,
    `const double _tx = ${usTopo.transform.translate[0]};`,
    `const double _ty = ${usTopo.transform.translate[1]};`,
    "",
    `final Int32List _arcDeltas = Int32List.fromList(<int>[${flatArcs.join(",")}]);`,
    `final Int32List _arcOffsets = Int32List.fromList(<int>[${arcOffsets.join(",")}]);`,
    "",
    `const List<List<List<int>>> _landArcs = <List<List<int>>>[${usRemappedPolys
      .map((p) => `<List<int>>[${p.map((r) => `<int>[${r.join(",")}]`).join(",")}]`)
      .join(",")}];`,
    "",
    "List<GeoPosition> _decodeArc(int arcIndex) {",
    "  final rev = arcIndex < 0;",
    "  final idx = rev ? ~arcIndex : arcIndex;",
    "  final start = _arcOffsets[idx];",
    "  final end = _arcOffsets[idx + 1];",
    "  final pts = <GeoPosition>[];",
    "  var x = 0;",
    "  var y = 0;",
    "  for (var i = start; i < end; i += 2) {",
    "    x += _arcDeltas[i];",
    "    y += _arcDeltas[i + 1];",
    "    pts.add((x * _sx + _tx, y * _sy + _ty));",
    "  }",
    "  return rev ? pts.reversed.toList() : pts;",
    "}",
    "",
    "GeoFeature<void>? _usLandCache;",
    "",
    "/// Exact `us-10m.json` `objects.land` feature decoded without `dart:io`.",
    "GeoFeature<void> get usLandFeature => _usLandCache ??= GeoFeature<void>(",
    "  geometry: GeoMultiPolygon(<List<List<GeoPosition>>>[",
    "    for (final poly in _landArcs)",
    "      <List<GeoPosition>>[",
    "        for (final ring in poly)",
    "          <GeoPosition>[",
    "            for (var i = 0; i < ring.length; ++i)",
    "              ..._decodeArc(ring[i]).skip(i == 0 ? 0 : 1),",
    "          ],",
    "      ],",
    "  ]),",
    ");",
    "",
  ];
  writeFileSync(path.join(pkg, "test/data/us_land_data.dart"), lines.join("\n"));
}
writeUsLandDart();

// --- 2. Simplify ny.json while preserving geoCentroid within 1e-5 ---
const nyRaw = JSON.parse(
  readFileSync(path.join(repo, "third_party/d3-geo/test/data/ny.json"), "utf8"),
);
console.log("nyRaw centroid:", d3.geoCentroid(nyRaw));

function dpSimplify(pts, eps) {
  if (pts.length <= 4) return pts;
  let maxD = 0;
  let idx = 0;
  const [x1, y1] = pts[0];
  const [x2, y2] = pts[pts.length - 1];
  const dx = x2 - x1;
  const dy = y2 - y1;
  const len2 = dx * dx + dy * dy;
  for (let i = 1; i < pts.length - 1; ++i) {
    const [x, y] = pts[i];
    let d;
    if (len2 === 0) {
      d = Math.hypot(x - x1, y - y1);
    } else {
      const t = ((x - x1) * dx + (y - y1) * dy) / len2;
      d = Math.hypot(x - (x1 + t * dx), y - (y1 + t * dy));
    }
    if (d > maxD) {
      maxD = d;
      idx = i;
    }
  }
  if (maxD > eps) {
    const a = dpSimplify(pts.slice(0, idx + 1), eps);
    const b = dpSimplify(pts.slice(idx), eps);
    return a.slice(0, -1).concat(b);
  }
  return [pts[0], pts[pts.length - 1]];
}

let nySimplified = null;
for (const eps of [0.0005, 0.0003, 0.00015, 0.00008, 0.00005]) {
  const feats = nyRaw.features.map((f) => ({
    type: "Feature",
    geometry: {
      type: "MultiPolygon",
      coordinates: f.geometry.coordinates
        .map((poly) =>
          poly
            .map((ring) => {
              const open = ring.slice(0, -1);
              const s = open.length > 4 ? dpSimplify(open, eps) : open;
              if (s.length < 3) return null;
              return [...s, s[0]];
            })
            .filter(Boolean),
        )
        .filter((p) => p.length > 0),
    },
  }));
  const fc = {type: "FeatureCollection", features: feats};
  const c = d3.geoCentroid(fc);
  let pts = 0;
  for (const f of feats) for (const p of f.geometry.coordinates) for (const r of p) pts += r.length;
  console.log({eps, pts, centroid: c, dx: Math.abs(c[0] - (-73.93079)), dy: Math.abs(c[1] - 40.69447)});
  nySimplified = fc;
  if (Math.abs(c[0] - (-73.93079)) < 9e-6 && Math.abs(c[1] - 40.69447) < 9e-6) {
    break;
  }
}

function writeNyDart(fc) {
  const flatCoords = [];
  const ringLens = [];
  const polyRingCounts = [];
  const featPolyCounts = [];
  for (const f of fc.features) {
    featPolyCounts.push(f.geometry.coordinates.length);
    for (const poly of f.geometry.coordinates) {
      polyRingCounts.push(poly.length);
      for (const ring of poly) {
        ringLens.push(ring.length);
        for (const [lon, lat] of ring) {
          flatCoords.push(Math.round(lon * 1e6), Math.round(lat * 1e6));
        }
      }
    }
  }
  const lines = [
    "// Original code, not ported from d3-geo: web-safe embedded NYC fixture.",
    "",
    "import 'dart:typed_data';",
    "",
    "import 'package:flutter_d3_geo_port/d3_geo.dart';",
    "",
    `final Int32List _nyCoords = Int32List.fromList(<int>[${flatCoords.join(",")}]);`,
    `const List<int> _nyRingLens = <int>[${ringLens.join(",")}];`,
    `const List<int> _nyPolyRingCounts = <int>[${polyRingCounts.join(",")}];`,
    `const List<int> _nyFeatPolyCounts = <int>[${featPolyCounts.join(",")}];`,
    "",
    "GeoFeatureCollection<void>? _nyCache;",
    "",
    "/// Simplified NYC boroughs GeoJSON preserving upstream `ny.json` centroid.",
    "GeoFeatureCollection<void> get nyFeatureCollection {",
    "  if (_nyCache != null) return _nyCache!;",
    "  final features = <GeoFeature<void>>[];",
    "  var coordIdx = 0;",
    "  var ringIdx = 0;",
    "  var polyIdx = 0;",
    "  for (final polyCount in _nyFeatPolyCounts) {",
    "    final polys = <List<List<GeoPosition>>>[];",
    "    for (var p = 0; p < polyCount; ++p) {",
    "      final ringCount = _nyPolyRingCounts[polyIdx++];",
    "      final rings = <List<GeoPosition>>[];",
    "      for (var r = 0; r < ringCount; ++r) {",
    "        final len = _nyRingLens[ringIdx++];",
    "        final ring = <GeoPosition>[];",
    "        for (var i = 0; i < len; ++i) {",
    "          ring.add((_nyCoords[coordIdx] / 1e6, _nyCoords[coordIdx + 1] / 1e6));",
    "          coordIdx += 2;",
    "        }",
    "        rings.add(ring);",
    "      }",
    "      polys.add(rings);",
    "    }",
    "    features.add(GeoFeature<void>(geometry: GeoMultiPolygon(polys)));",
    "  }",
    "  return _nyCache = GeoFeatureCollection<void>(features);",
    "}",
    "",
  ];
  writeFileSync(path.join(pkg, "test/data/ny_data.dart"), lines.join("\n"));
}
writeNyDart(nySimplified);

// --- 3. Compact Natural Earth-style low-res world landmass MultiPolygon ---
// Polygons in [lon, lat] degrees (normalized to D3 clockwise spherical winding).
const rawContinents = [
  // North America
  [
    [-168, 65], [-162, 70], [-141, 70], [-125, 70], [-110, 68], [-95, 68],
    [-82, 66], [-78, 62], [-64, 60], [-56, 52], [-60, 46], [-67, 45],
    [-70, 42], [-75, 38], [-80, 32], [-81, 25], [-83, 30], [-90, 29],
    [-97, 26], [-96, 19], [-88, 21], [-83, 15], [-83, 10], [-78, 8],
    [-80, 9], [-85, 11], [-92, 15], [-105, 20], [-110, 24], [-114, 31],
    [-117, 33], [-122, 37], [-124, 42], [-124, 48], [-130, 54], [-138, 59],
    [-150, 60], [-160, 56], [-165, 60], [-168, 65],
  ],
  // Greenland
  [
    [-44, 60], [-52, 64], [-55, 70], [-68, 76], [-62, 81], [-35, 83],
    [-18, 81], [-20, 74], [-25, 70], [-36, 65], [-44, 60],
  ],
  // South America
  [
    [-78, 9], [-72, 11], [-62, 10], [-50, 2], [-35, -6], [-38, -14],
    [-42, -23], [-52, -33], [-58, -38], [-65, -43], [-68, -55], [-74, -52],
    [-73, -40], [-71, -30], [-70, -18], [-81, -5], [-79, 2], [-78, 9],
  ],
  // Africa
  [
    [-17, 15], [-13, 28], [-6, 36], [10, 37], [15, 32], [25, 32], [33, 31],
    [40, 20], [43, 12], [51, 11], [41, -2], [40, -15], [35, -24], [28, -33],
    [18, -34], [14, -22], [12, -6], [9, 4], [2, 6], [-8, 5], [-16, 11], [-17, 15],
  ],
  // Madagascar
  [
    [49, -12], [50, -16], [47, -25], [44, -25], [44, -18], [49, -12],
  ],
  // Eurasia
  [
    [-9, 37], [-9, 43], [-2, 43], [-4, 48], [2, 51], [8, 54], [10, 58],
    [5, 61], [15, 68], [28, 71], [40, 67], [55, 69], [70, 73], [104, 77],
    [140, 73], [178, 66], [170, 60], [160, 56], [140, 53], [135, 44],
    [129, 35], [122, 39], [122, 31], [114, 22], [108, 16], [105, 10],
    [100, 13], [103, 2], [98, 8], [90, 22], [80, 8], [73, 19], [66, 25],
    [56, 26], [59, 22], [44, 13], [35, 29], [36, 36], [27, 37], [23, 38],
    [14, 45], [8, 44], [3, 42], [-5, 36], [-9, 37],
  ],
  // Great Britain
  [
    [-5, 50], [-3, 54], [-5, 58], [-2, 58], [1, 53], [1, 51], [-5, 50],
  ],
  // Iceland
  [
    [-24, 65], [-18, 66], [-14, 65], [-19, 63.5], [-24, 65],
  ],
  // Japan
  [
    [130, 31], [135, 34], [141, 36], [141, 41], [145, 43], [141, 45],
    [139, 40], [136, 37], [131, 34], [130, 31],
  ],
  // Australia
  [
    [114, -22], [122, -18], [131, -12], [136, -12], [142, -11], [149, -20],
    [153, -28], [150, -37], [141, -38], [135, -34], [129, -32], [115, -34],
    [113, -26], [114, -22],
  ],
  // New Zealand
  [
    [173, -35], [178, -38], [175, -41], [171, -44], [167, -46], [170, -41],
    [174, -39], [173, -35],
  ],
  // Indonesia (Sumatra + Java + Borneo simplified)
  [
    [95, 5], [100, 1], [106, -6], [114, -8], [105, -7], [99, -1], [95, 5],
  ],
  [
    [109, 1], [117, 6], [119, 1], [116, -3], [110, -3], [109, 1],
  ],
  // New Guinea
  [
    [132, -1], [141, -3], [150, -10], [142, -9], [135, -5], [132, -1],
  ],
  // Antarctica
  [
    [-180, -72], [-120, -73], [-60, -64], [-40, -72], [0, -70], [60, -67],
    [120, -67], [165, -72], [180, -72], [180, -85], [0, -85], [-180, -85],
    [-180, -72],
  ],
];

const normalizedWorldPolys = rawContinents.map((ring) => {
  const poly = {type: "Polygon", coordinates: [ring]};
  const a = d3.geoArea(poly);
  const cwRing = a > 2 * Math.PI ? ring.slice().reverse() : ring;
  return [cwRing];
});
const worldLandGeoJson = {
  type: "Feature",
  geometry: {type: "MultiPolygon", coordinates: normalizedWorldPolys},
};

function writeWorldLandDart() {
  const lines = [
    "// Original code, not ported from d3-geo: lightweight world land fixture.",
    "",
    "import 'package:flutter_d3_geo_port/d3_geo.dart';",
    "",
    "/// Lightweight world landmass MultiPolygon feature for web-safe tests.",
    "const GeoFeature<void> worldLandFeature = GeoFeature<void>(",
    "  geometry: GeoMultiPolygon(<List<List<GeoPosition>>>[",
    ...normalizedWorldPolys.map(
      ([ring]) =>
        `    <List<GeoPosition>>[<GeoPosition>[${ring.map(([x, y]) => `(${x}, ${y})`).join(", ")}]],`,
    ),
    "  ]),",
    ");",
    "",
  ];
  writeFileSync(path.join(pkg, "test/data/world_land_data.dart"), lines.join("\n"));
}
writeWorldLandDart();

// --- 4. Compute exact Node.js reference values for fit-test, snapshots & reference_test ---
const fitCases = [
  ["world equirectangular", () => d3.geoEquirectangular().fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world azimuthalEqualArea", () => d3.geoAzimuthalEqualArea().fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world azimuthalEquidistant", () => d3.geoAzimuthalEquidistant().fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world conicConformal", () => d3.geoConicConformal().clipAngle(30).parallels([30, 60]).rotate([0, -45]).fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world conicEqualArea", () => d3.geoConicEqualArea().fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world conicEquidistant", () => d3.geoConicEquidistant().fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world fitSize equirectangular", () => d3.geoEquirectangular().fitSize([900, 900], worldLandGeoJson)],
  ["world gnomonic", () => d3.geoGnomonic().clipAngle(45).fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world mercator", () => d3.geoMercator().fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world orthographic", () => d3.geoOrthographic().fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world fitSize orthographic", () => d3.geoOrthographic().fitSize([900, 900], worldLandGeoJson)],
  ["world stereographic", () => d3.geoStereographic().fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world transverseMercator", () => d3.geoTransverseMercator().fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world custom", () => d3.geoProjection((x, y) => [x, Math.pow(y, 3)]).fitExtent([[50, 50], [950, 950]], worldLandGeoJson)],
  ["world fitWidth equirectangular", () => d3.geoEquirectangular().fitWidth(900, worldLandGeoJson)],
  ["world fitWidth transverseMercator", () => d3.geoTransverseMercator().fitWidth(900, worldLandGeoJson)],
  ["world fitHeight equirectangular", () => d3.geoEquirectangular().fitHeight(900, worldLandGeoJson)],
  ["world fitHeight transverseMercator", () => d3.geoTransverseMercator().fitHeight(900, worldLandGeoJson)],
];

const fitRef = {};
for (const [name, fn] of fitCases) {
  const p = fn();
  fitRef[name] = {scale: p.scale(), translate: p.translate()};
}

const width = 960;
const height = 500;
const snapshotSpecs = [
  ["azimuthalEqualArea", () => d3.geoAzimuthalEqualArea().precision(0.1), worldLandGeoJson],
  ["azimuthalEquidistant", () => d3.geoAzimuthalEquidistant().precision(0.1), worldLandGeoJson],
  ["conicConformal", () => d3.geoConicConformal().precision(0.1), worldLandGeoJson],
  ["conicEqualArea", () => d3.geoConicEqualArea().precision(0.1), worldLandGeoJson],
  ["conicEquidistant", () => d3.geoConicEquidistant().precision(0.1), worldLandGeoJson],
  ["equalEarth", () => d3.geoEqualEarth().precision(0.1), worldLandGeoJson],
  ["equirectangular", () => d3.geoEquirectangular().precision(0.1), worldLandGeoJson],
  ["gnomonic", () => d3.geoGnomonic().precision(0.1), worldLandGeoJson],
  ["mercator", () => d3.geoMercator().precision(0.1), worldLandGeoJson],
  ["naturalEarth1", () => d3.geoNaturalEarth1().precision(0.1), worldLandGeoJson],
  ["angleorient30", () => d3.geoEquirectangular().clipAngle(90).angle(-30).precision(0.1).fitExtent([[0, 0], [width, height]], {type: "Sphere"}), worldLandGeoJson],
  ["orthographic", () => d3.geoOrthographic().precision(0.1), worldLandGeoJson],
  ["stereographic", () => d3.geoStereographic().precision(0.1), worldLandGeoJson],
  ["transverseMercator", () => d3.geoTransverseMercator().precision(0.1), worldLandGeoJson],
  ["albers", () => d3.geoAlbers().precision(0.1), usLandGeoJson],
  ["albersUsa", () => d3.geoAlbersUsa().precision(0.1), usLandGeoJson],
];

const snapshotRef = {};
const graticule10 = d3.geoGraticule10();
for (const [name, makeProj, land] of snapshotSpecs) {
  const proj = makeProj();
  const pathGen = d3.geoPath(proj);
  snapshotRef[name] = {
    landArea: pathGen.area(land),
    landBounds: pathGen.bounds(land),
    landCentroid: pathGen.centroid(land),
    landMeasure: pathGen.measure(land),
    gratMeasure: pathGen.measure(graticule10),
    sphereArea: pathGen.area({type: "Sphere"}),
  };
}

// Reference parity vectors for d3_geo_reference.dart
const refPts = [
  [0, 0], [-122.4194, 37.7749], [-74.0059, 40.7128], [-0.1276, 51.5072],
  [139.6917, 35.6895], [151.2093, -33.8688], [-43.1729, -22.9068],
  [18.4241, -33.9249], [37.6173, 55.7558], [-149.9003, 61.2181],
  [-157.8583, 21.3069], [174.7762, -41.2865],
];

const projFactories = [
  ["albers", () => d3.geoAlbers()],
  ["albersUsa", () => d3.geoAlbersUsa()],
  ["azimuthalEqualArea", () => d3.geoAzimuthalEqualArea()],
  ["azimuthalEquidistant", () => d3.geoAzimuthalEquidistant()],
  ["conicConformal", () => d3.geoConicConformal()],
  ["conicEqualArea", () => d3.geoConicEqualArea()],
  ["conicEquidistant", () => d3.geoConicEquidistant()],
  ["equalEarth", () => d3.geoEqualEarth()],
  ["equirectangular", () => d3.geoEquirectangular()],
  ["gnomonic", () => d3.geoGnomonic()],
  ["mercator", () => d3.geoMercator()],
  ["naturalEarth1", () => d3.geoNaturalEarth1()],
  ["orthographic", () => d3.geoOrthographic().rotate([-10, -20, 5])],
  ["stereographic", () => d3.geoStereographic()],
  ["transverseMercator", () => d3.geoTransverseMercator()],
];

const projRef = {};
for (const [name, fn] of projFactories) {
  const p = fn();
  projRef[name] = refPts.map((pt) => {
    const fwd = p(pt);
    const inv = fwd ? p.invert(fwd) : null;
    return {fwd, inv};
  });
}

function fmtNum(v) {
  if (Number.isNaN(v)) return "double.nan";
  if (v === Infinity) return "double.infinity";
  if (v === -Infinity) return "double.negativeInfinity";
  return Object.is(v, -0) ? "0.0" : String(v);
}

function fmtPos(p) {
  if (p == null) return "null";
  return `(${fmtNum(p[0])}, ${fmtNum(p[1])})`;
}

function fmtExtent(e) {
  return `(${fmtPos(e[0])}, ${fmtPos(e[1])})`;
}

function wrapDartString(str, indent = "  ") {
  const chunks = [];
  const maxLen = 74 - indent.length;
  for (let i = 0; i < str.length; i += maxLen) {
    chunks.push(`${indent}'${str.slice(i, i + maxLen)}'`);
  }
  return chunks.join("\n");
}

const refLines = [
  "// Original code, not ported from d3-geo: Node.js v3.1.1 reference vectors.",
  "",
  "import 'package:flutter_d3_geo_port/d3_geo.dart';",
  "",
  `const List<GeoPosition> refTestPoints = <GeoPosition>[`,
  ...refPts.map((p) => `  (${p[0]}, ${p[1]}),`),
  `];`,
  "",
  "/// Node.js d3-geo v3.1.1 fit-test reference scale/translate for world.",
  "const Map<String, (double, GeoPosition)> refWorldFit =",
  "    <String, (double, GeoPosition)>{",
  ...Object.entries(fitRef).map(
    ([k, v]) => `  '${k}': (${fmtNum(v.scale)}, ${fmtPos(v.translate)}),`,
  ),
  "};",
  "",
  "/// Node.js d3-geo v3.1.1 numerical snapshot geometry references.",
  "const Map<String, (double, GeoExtent, GeoPosition, double, double, double)>",
  "refSnapshots =",
  "    <String, (double, GeoExtent, GeoPosition, double, double, double)>{",
  ...Object.entries(snapshotRef).map(
    ([k, v]) =>
      `  '${k}': (\n    ${fmtNum(v.landArea)},\n    ${fmtExtent(v.landBounds)},\n    ${fmtPos(v.landCentroid)},\n    ${fmtNum(v.landMeasure)},\n    ${fmtNum(v.gratMeasure)},\n    ${fmtNum(v.sphereArea)},\n  ),`,
  ),
  "};",
  "",
  "/// Node.js d3-geo v3.1.1 forward & inverse projection parity vectors.",
  "const Map<String, List<(GeoPosition?, GeoPosition?)>> refProjections =",
  "    <String, List<(GeoPosition?, GeoPosition?)>>{",
  ...Object.entries(projRef).map(
    ([k, arr]) =>
      `  '${k}': <(GeoPosition?, GeoPosition?)>[\n${arr
        .map((r) => `    (${fmtPos(r.fwd)}, ${fmtPos(r.inv)}),`)
        .join("\n")}\n  ],`,
  ),
  "};",
  "",
  `const double refWorldArea = ${fmtNum(d3.geoArea(worldLandGeoJson))};`,
  `const GeoExtent refWorldBounds = ${fmtExtent(d3.geoBounds(worldLandGeoJson))};`,
  `const GeoPosition refWorldCentroid = ${fmtPos(d3.geoCentroid(worldLandGeoJson))};`,
  `const double refWorldLength = ${fmtNum(d3.geoLength(worldLandGeoJson))};`,
  `const double refUsArea = ${fmtNum(d3.geoArea(usLandGeoJson))};`,
  `const GeoExtent refUsBounds = ${fmtExtent(d3.geoBounds(usLandGeoJson))};`,
  `const GeoPosition refUsCentroid = ${fmtPos(d3.geoCentroid(usLandGeoJson))};`,
  `const double refLondonTokyoDist = ${fmtNum(d3.geoDistance([-0.1276, 51.5072], [139.6917, 35.6895]))};`,
  `const GeoPosition refLondonTokyoMid = ${fmtPos(d3.geoInterpolate([-0.1276, 51.5072], [139.6917, 35.6895])(0.5))};`,
  `const String refWorldNaturalEarthSvg =\n${wrapDartString(d3.geoPath(d3.geoNaturalEarth1()).digits(2)(worldLandGeoJson))};`,
  `const String refWorldOrthoSvg =\n${wrapDartString(d3.geoPath(d3.geoOrthographic().rotate([-10, -20, 0])).digits(2)(worldLandGeoJson))};`,
  `const String refGrat10MercatorSvg =\n${wrapDartString(d3.geoPath(d3.geoMercator()).digits(1)(d3.geoGraticule().step([30, 30])()))};`,
  "",
];
writeFileSync(path.join(pkg, "test/port/d3_geo_reference.dart"), refLines.join("\n"));
console.log("Generated test/data/{us_land,ny,world_land}_data.dart and test/port/d3_geo_reference.dart");
