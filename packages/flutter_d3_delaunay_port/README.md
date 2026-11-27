# flutter_d3_delaunay_port

A native, fully statically typed Dart/Flutter port of
[d3-delaunay](https://github.com/d3/d3-delaunay) **6.0.4**, bundling its two internal pure-math
dependencies [delaunator](https://github.com/mapbox/delaunator) **5.1.0** and
[robust-predicates](https://github.com/mourner/robust-predicates) **3.0.3** (`orient2d` /
`orient2dfast`): fast Delaunay triangulation, clipped Voronoi diagrams, nearest-neighbor queries
(`find` / `findAll`), convex hull & triangle polygons, in-place `update()`, SVG path strings, and
direct Flutter `Canvas` rendering via `UiPathContext` — with **zero `dynamic`** and zero JavaScript
runtime.

```dart
import 'package:flutter_d3_delaunay_port/d3_delaunay.dart';

// 1. Build from (double, double) coordinates or typed models
final delaunay = Delaunay.fromCoords(const <(double, double)>[
  (0, 0),
  (100, 0),
  (50, 80),
  (100, 100),
  (0, 100),
]);

// Nearest-neighbor search & Delaunay adjacency
final nearest = delaunay.find(48, 76); // 2
final adjacent = delaunay.neighbors(nearest).toList();

// 2. Clipped Voronoi diagram
final voronoi = delaunay.voronoi((0, 0, 100, 100));
final cell = voronoi.cellPolygon(nearest); // List<(double, double)>?
final svg = voronoi.renderToSvg(); // SVG path string

// 3. Strongly typed custom models
typedef Site = ({String id, double x, double y});
final bySite = Delaunay.from<Site>(
  const <Site>[(id: 'a', x: 10, y: 20), (id: 'b', x: 80, y: 40), (id: 'c', x: 40, y: 90)],
  x: (s) => s.x,
  y: (s) => s.y,
);
```

Direct Flutter `Canvas` rendering with zero intermediate SVG parsing:

```dart
import 'package:flutter_d3_delaunay_port/flutter_d3_delaunay_port.dart';
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';

// Stream directly into a reusable UiPathContext or allocate a dart:ui.Path:
final ctx = UiPathContext();
voronoi.render(ctx);
canvas.drawPath(ctx.path, strokePaint);

// Or use the convenience extension helpers:
canvas.drawPath(delaunay.toUiPath(), meshPaint);
canvas.drawPath(voronoi.cellToUiPath(0), highlightPaint);
```

## Installing

```sh
dart pub add flutter_d3_delaunay_port
```

- **Pure Dart (zero Flutter import):**
  `import 'package:flutter_d3_delaunay_port/d3_delaunay.dart';`
  Compiles cleanly for Dart VM, native AOT, JavaScript (`dart2js`), and WebAssembly (`dart2wasm`).
- **Flutter helpers (`dart:ui.Path` extensions via `UiPathContext`):**
  `import 'package:flutter_d3_delaunay_port/flutter_d3_delaunay_port.dart';`

## API

- **`Delaunay`:** `Delaunay(Float64List points)`, `Delaunay.from<T>(Iterable<T> points, {x, y})`,
  `Delaunay.fromCoords(Iterable<(double, double)> points)`,
  `Delaunay.fromIndexed<T>(Iterable<T> points, {x, y})`, `Delaunay.fromLength(int length, ...)`;
  typed buffers (`points: Float64List`, `triangles: Int32List`, `halfedges: Int32List`,
  `hull: Uint32List`, `inedges: Int32List`, `collinear: Int32List?`);
  `update()`, `voronoi([(double, double, double, double) bounds])`, `neighbors(int i)`,
  `find(double x, double y, [int i = 0])`, `findAll(double x, double y, double radius)`,
  `hullPolygon()`, `trianglePolygon(int i)`, `trianglePolygons()`,
  `render(CanvasPath)` / `renderToSvg()`, `renderPoints(CanvasPath, [r])` / `renderPointsToSvg([r])`,
  `renderHull(CanvasPath)` / `renderHullToSvg()`,
  `renderTriangle(int i, CanvasPath)` / `renderTriangleToSvg(int i)`.
- **`Voronoi`:** `xmin` / `ymin` / `xmax` / `ymax`, `circumcenters: Float64List`,
  `vectors: Float64List`, `update()`, `cellPolygon(int i)`, `cellPolygons()`,
  `cellPolygonsIndexed()`, `contains(int i, double x, double y)`, `neighbors(int i)`,
  `render(CanvasPath)` / `renderToSvg()`, `renderBounds(CanvasPath)` / `renderBoundsToSvg()`,
  `renderCell(int i, CanvasPath)` / `renderCellToSvg(int i)`.
- **Bundled pure-math primitives:** `Delaunator`, `orient2d`, `orient2dfast`.
- **Flutter extensions (`flutter_d3_delaunay_port.dart`):** `DelaunayUiPath` (`toUiPath`,
  `hullToUiPath`, `pointsToUiPath`, `triangleToUiPath`) and `VoronoiUiPath` (`toUiPath`,
  `boundsToUiPath`, `cellToUiPath`).

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 157, Firefox 160,
Safari 27.0.1), iOS 27.2 (`ios-arm64` Flutter AOT release), and Pixel 8a (Android 17 AOT release,
Mobile Chrome 157, Mobile Firefox 160). All values are median **ns/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_delaunay_port/doc/performance.md)
for the complete 14-case breakdown including baseline vs optimized).

- **Native AOT:** iOS 27.2 AOT beats desktop M3 Max Node.js `d3-delaunay` on **13/14** workloads
  (up to **3.23× faster** on `delaunay.neighbors_1000` and **2.23× faster** on
  `delaunator.uniform_1000`); macOS AOT beats Node.js on **9/14** workloads (up to **2.24×
  faster**); Pixel 8a Android AOT beats Mobile Chrome upstream JS on **13/14** workloads (up to
  **3.54× faster**).
- **Web (`dart2wasm` & `dart2js`):** In browsers, Dart beats upstream JS on **12/14** workloads in
  Desktop Firefox (up to **3.00× faster**), Desktop Safari (up to **2.88× faster**), Mobile Chrome
  (up to **3.20× faster**), and Mobile Firefox (up to **3.80× faster**), and **11/14** in Desktop
  Chrome (up to **2.39× faster**).

### Native AOT vs Node.js (ns/op)

| Case | Node.js upstream | macOS AOT | iOS 27.2 AOT | Pixel 8a Android AOT |
|---|---:|---:|---:|---:|
| `orient2d.exact_10k` | 24,205 | 27,749 | **20,232** | 42,611 |
| `delaunator.uniform_1000` | 175,092 | **105,926** | **78,578** | 220,742 |
| `delaunator.uniform_5000` | 1,156,294 | **1,032,500** | **703,813** | 1,771,875 |
| `delaunator.clustered_2000` | 399,823 | **246,344** | **181,430** | 622,156 |
| `delaunator.update_1000` | 168,672 | **100,422** | **80,008** | 212,227 |
| `delaunay.from_1000` | 188,323 | **119,578** | **90,891** | 243,344 |
| `delaunay.update_1000` | 176,769 | **113,473** | **87,594** | 236,039 |
| `delaunay.find_512` | 667,546 | 780,344 | **456,281** | 1,181,688 |
| `delaunay.neighbors_1000` | 109,862 | **49,072** | **33,963** | **60,934** |
| `voronoi.build_1000` | 11,944 | 13,519 | **9,771** | 21,938 |
| `voronoi.update_1000` | 182,407 | **125,320** | **97,457** | 267,656 |
| `voronoi.cellPolygons_1000` | 156,215 | **142,719** | **124,922** | 234,945 |
| `voronoi.renderSvg_1000` | 223,380 | 614,563 | 458,219 | 1,445,375 |
| `voronoi.renderCanvas_1000` | 38,850 | 39,148 | **32,357** | 66,461 |

### Desktop & Mobile Browsers (ns/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 157 | Firefox 160 | Safari 27.0.1 | Pixel Chrome 157 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `delaunator.uniform_1000` | 142,188 / **126,563** / 134,375 | 265,625 / 265,625 / **171,875** | 125,000 / **109,375** / 164,063 | 401,563 / 415,625 / **227,344** | 531,250 / 468,750 / **359,375** |
| `delaunator.uniform_5000` | 1,012,500 / 1,006,250 / **918,750** | 1,812,500 / 1,812,500 / **1,187,500** | 937,500 / **812,500** / 1,062,500 | 2,550,000 / 2,712,625 / **1,762,563** | 3,250,000 / 2,875,000 / **2,375,000** |
| `delaunator.clustered_2000` | 350,000 / **290,625** / 300,000 | 625,000 / 593,750 / **359,375** | 312,500 / **234,375** / 375,000 | 928,125 / 937,500 / **587,500** | 1,187,500 / 1,125,000 / **875,000** |
| `delaunay.from_1000` | 180,469 / **135,938** / 139,844 | 281,250 / 265,625 / **164,063** | 125,000 / **117,188** / 179,688 | 500,000 / 392,188 / **245,297** | 562,500 / 531,250 / **390,625** |
| `delaunay.find_512` | **831,250** / 834,375 / 893,750 | 1,062,500 / 1,125,000 / **875,000** | 781,250 / **718,750** / 906,250 | 1,962,500 / 1,462,500 / **1,312,500** | 1,500,000 / 1,500,000 / **1,375,000** |
| `delaunay.neighbors_1000` | 98,438 / **41,211** / 50,781 | 164,063 / 93,750 / **54,688** | 89,844 / **39,063** / 54,688 | 202,344 / 129,688 / **63,277** | 296,875 / 171,875 / **78,125** |
| `voronoi.update_1000` | 148,438 / **132,813** / 159,375 | 281,250 / 281,250 / **179,688** | 125,000 / **117,188** / 187,500 | 393,750 / 376,578 / **287,500** | 562,500 / 531,250 / **421,875** |
| `voronoi.cellPolygons_1000` | 139,063 / **132,813** / 185,938 | 375,000 / **234,375** / 250,000 | 179,688 / **125,000** / 210,938 | 318,750 / 364,063 / **298,438** | 687,500 / **437,500** / **437,500** |
| `voronoi.renderCanvas_1000` | 38,281 / 31,055 / **28,613** | 89,844 / 58,594 / **44,922** | 70,313 / **24,414** / 42,969 | 111,719 / 131,250 / **44,922** | 164,063 / 101,563 / **97,656** |

## Upstream

- Upstream:
  - [d3/d3-delaunay](https://github.com/d3/d3-delaunay) `v6.0.4` (`d3DelaunayVersion`)
  - [mapbox/delaunator](https://github.com/mapbox/delaunator) `v5.1.0` (`delaunatorVersion`)
  - [mourner/robust-predicates](https://github.com/mourner/robust-predicates) `v3.0.3` (`robustPredicatesVersion`)
- Differences from upstream: [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_delaunay_port/doc/differences.md).
- Full benchmark report: [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_delaunay_port/doc/performance.md).

## License

ISC (matching upstream `d3-delaunay` and `delaunator`), with portions ported from
`robust-predicates` under the Unlicense. See [LICENSE](LICENSE). This project is not affiliated
with the D3 project, Observable, or Mapbox.
