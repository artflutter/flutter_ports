// Original code, not ported from d3-delaunay: Node.js reference vector generator.
//
// Compiles robust-predicates macros into a temporary directory, loads the
// pinned upstream delaunator v5.1.0 and d3-delaunay v6.0.4 modules from
// third_party/, and writes test/port/d3_delaunay_reference.dart.

import { readFileSync, writeFileSync, mkdirSync, rmSync, cpSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const repoRoot = resolve(import.meta.dirname, '../../../..');
const outFile = resolve(import.meta.dirname, '../../test/port/d3_delaunay_reference.dart');

// Stage pinned upstream sources into a temp directory with robust-predicates
// macros compiled and ES module paths wired cleanly (never mutating third_party/).
const stage = join(tmpdir(), `d3_delaunay_ref_${process.pid}`);
rmSync(stage, { recursive: true, force: true });
mkdirSync(join(stage, 'node_modules/robust-predicates/esm'), { recursive: true });
mkdirSync(join(stage, 'node_modules/delaunator'), { recursive: true });
mkdirSync(join(stage, 'd3-delaunay'), { recursive: true });

// Compile robust-predicates macros (exact macro definitions from compile.js).
const rpRoot = join(repoRoot, 'third_party/robust-predicates');
cpSync(join(rpRoot, 'src'), join(stage, 'node_modules/robust-predicates/src'), { recursive: true });
cpSync(join(rpRoot, 'index.js'), join(stage, 'node_modules/robust-predicates/index.js'));
cpSync(join(rpRoot, 'package.json'), join(stage, 'node_modules/robust-predicates/package.json'));
cpSync(join(rpRoot, 'compile.js'), join(stage, 'node_modules/robust-predicates/compile.js'));

const prevCwd = process.cwd();
process.chdir(join(stage, 'node_modules/robust-predicates'));
await import(pathToFileURL(join(stage, 'node_modules/robust-predicates/compile.js')).href);
process.chdir(prevCwd);

// Stage delaunator & d3-delaunay.
cpSync(join(repoRoot, 'third_party/delaunator/index.js'), join(stage, 'node_modules/delaunator/index.js'));
cpSync(join(repoRoot, 'third_party/delaunator/package.json'), join(stage, 'node_modules/delaunator/package.json'));
cpSync(join(repoRoot, 'third_party/d3-delaunay/src'), join(stage, 'd3-delaunay/src'), { recursive: true });
cpSync(join(repoRoot, 'third_party/d3-delaunay/package.json'), join(stage, 'd3-delaunay/package.json'));

const { Delaunay } = await import(pathToFileURL(join(stage, 'd3-delaunay/src/index.js')).href);
const { default: Delaunator } = await import(pathToFileURL(join(stage, 'node_modules/delaunator/index.js')).href);
const { orient2d } = await import(pathToFileURL(join(stage, 'node_modules/robust-predicates/index.js')).href);

// Deterministic Park-Miller LCG matching Dart.
function makeLcg(seed) {
  let s = seed;
  return () => {
    s = (s * 48271) % 2147483647;
    return s / 2147483647.0;
  };
}

const rand = makeLcg(20261127);

// 1. 40 uniform random points in [0, 500] x [0, 400].
const uniform40 = [];
for (let i = 0; i < 40; i++) {
  uniform40.push([Math.round(rand() * 50000) / 100, Math.round(rand() * 40000) / 100]);
}
const dUniform = Delaunay.from(uniform40);
const vUniform = dUniform.voronoi([0, 0, 500, 400]);

// 2. 30 clustered points with coincident duplicates.
const clustered30 = [];
const centers = [[100, 100], [380, 120], [250, 300]];
for (let i = 0; i < 27; i++) {
  const [cx, cy] = centers[i % 3];
  clustered30.push([
    Math.round((cx + (rand() - 0.5) * 90) * 100) / 100,
    Math.round((cy + (rand() - 0.5) * 90) * 100) / 100,
  ]);
}
clustered30.push(clustered30[0], clustered30[5], clustered30[12]);
const dClustered = Delaunay.from(clustered30);
const vClustered = dClustered.voronoi([0, 0, 500, 400]);

// 3. 16 collinear points.
const collinear16 = Array.from({ length: 16 }, (_, i) => [10 + i * 25, 20 + i * 12.5]);
const dCollinear = Delaunay.from(collinear16);
const vCollinear = dCollinear.voronoi([0, 0, 500, 400]);

// 4. 30 find queries on uniform40.
const findQueries = [];
for (let i = 0; i < 30; i++) {
  const qx = Math.round((rand() * 600 - 50) * 100) / 100;
  const qy = Math.round((rand() * 500 - 50) * 100) / 100;
  findQueries.push([qx, qy, dUniform.find(qx, qy)]);
}

// 5. Hard orient2d fixtures (first 50 lines of robust-predicates orient2d.txt).
const orientLines = readFileSync(join(rpRoot, 'test/fixtures/orient2d.txt'), 'utf8')
  .trim()
  .split(/\r?\n/)
  .slice(0, 50);
const orientVectors = orientLines.map((line) => {
  const [, ax, ay, bx, by, cx, cy] = line.split(' ').map(Number);
  const res = orient2d(ax, ay, bx, by, cx, cy);
  return [ax, ay, bx, by, cx, cy, Math.sign(res)];
});

// 6. Ukraine Delaunator reference summary.
const ukraine = JSON.parse(readFileSync(join(repoRoot, 'third_party/delaunator/test/fixtures/ukraine.json'), 'utf8'));
const dUkraine = Delaunator.from(ukraine);

const fmtDouble = (v) => {
  if (Object.is(v, -0) || v === 0) return '0';
  if (!Number.isFinite(v)) {
    return v > 0 ? 'double.infinity' : v < 0 ? 'double.negativeInfinity' : 'double.nan';
  }
  if (Number.isSafeInteger(v) && Math.abs(v) <= 1e15) {
    return String(v);
  }
  const s = String(v);
  return s.includes('.') || s.includes('e') || s.includes('E') ? s : `${s}.0`;
};
const fmtString = (s) => `'${s.replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;
const fmtPairList = (arr) => arr.map(([x, y]) => `(${fmtDouble(x)}, ${fmtDouble(y)})`).join(', ');
const fmtPoly = (poly) => poly == null ? 'null' : `<(double, double)>[${fmtPairList(poly)}]`;

const lines = [
  '// Original code, not ported from d3-delaunay: Node.js reference vectors.',
  '',
  '// Generated numeric reference tables.',
  '// ignore_for_file: lines_longer_than_80_chars',
  '',
  '/// Generated by `node tool/reference/generate_reference.mjs` against pinned',
  '/// upstream `d3-delaunay` v6.0.4, `delaunator` v5.1.0, and',
  '/// `robust-predicates` v3.0.3.',
  'library;',
  '',
  `const List<(double, double)> refUniform40Points = <(double, double)>[${fmtPairList(uniform40)}];`,
  `const List<int> refUniform40Triangles = <int>[${Array.from(dUniform.triangles).join(', ')}];`,
  `const List<int> refUniform40Halfedges = <int>[${Array.from(dUniform.halfedges).join(', ')}];`,
  `const List<int> refUniform40Hull = <int>[${Array.from(dUniform.hull).join(', ')}];`,
  `const List<int> refUniform40Inedges = <int>[${Array.from(dUniform.inedges).join(', ')}];`,
  `const List<double> refUniform40Circumcenters = <double>[${Array.from(vUniform.circumcenters).map(fmtDouble).join(', ')}];`,
  `const List<double> refUniform40Vectors = <double>[${Array.from(vUniform.vectors).map(fmtDouble).join(', ')}];`,
  `const String refUniform40DelaunaySvg = ${fmtString(dUniform.render())};`,
  `const String refUniform40HullSvg = ${fmtString(dUniform.renderHull())};`,
  `const String refUniform40VoronoiSvg = ${fmtString(vUniform.render())};`,
  `const List<List<(double, double)>?> refUniform40Cells = <List<(double, double)>?>[`,
  ...Array.from({ length: uniform40.length }, (_, i) => `  ${fmtPoly(vUniform.cellPolygon(i))},`),
  '];',
  `const List<List<int>> refUniform40VoronoiNeighbors = <List<int>>[`,
  ...Array.from({ length: uniform40.length }, (_, i) => `  <int>[${Array.from(vUniform.neighbors(i)).join(', ')}],`),
  '];',
  `const List<(double, double, int)> refUniform40Find = <(double, double, int)>[`,
  ...findQueries.map(([qx, qy, idx]) => `  (${fmtDouble(qx)}, ${fmtDouble(qy)}, ${idx}),`),
  '];',
  '',
  `const List<(double, double)> refClustered30Points = <(double, double)>[${fmtPairList(clustered30)}];`,
  `const List<int> refClustered30Triangles = <int>[${Array.from(dClustered.triangles).join(', ')}];`,
  `const List<int> refClustered30Inedges = <int>[${Array.from(dClustered.inedges).join(', ')}];`,
  `const List<int> refClustered30Hull = <int>[${Array.from(dClustered.hull).join(', ')}];`,
  `const List<int> refClustered30CellLengths = <int>[${Array.from({ length: clustered30.length }, (_, i) => (vClustered.cellPolygon(i)?.length ?? -1)).join(', ')}];`,
  '',
  `const List<(double, double)> refCollinear16Points = <(double, double)>[${fmtPairList(collinear16)}];`,
  `const List<int> refCollinear16Order = <int>[${Array.from(dCollinear.collinear).join(', ')}];`,
  `const List<int> refCollinear16CellLengths = <int>[${Array.from({ length: collinear16.length }, (_, i) => (vCollinear.cellPolygon(i)?.length ?? -1)).join(', ')}];`,
  '',
  `const List<(double, double, double, double, double, double, int)> refOrient2dHard50 = <(double, double, double, double, double, double, int)>[`,
  ...orientVectors.map(([ax, ay, bx, by, cx, cy, s]) => `  (${fmtDouble(ax)}, ${fmtDouble(ay)}, ${fmtDouble(bx)}, ${fmtDouble(by)}, ${fmtDouble(cx)}, ${fmtDouble(cy)}, ${s}),`),
  '];',
  '',
  `const int refUkraineTrianglesLen = ${dUkraine.trianglesLen};`,
  `const List<int> refUkraineHull = <int>[${Array.from(dUkraine.hull).join(', ')}];`,
  '',
];

writeFileSync(outFile, lines.join('\n'));
rmSync(stage, { recursive: true, force: true });
console.log(`Wrote ${outFile}`);
