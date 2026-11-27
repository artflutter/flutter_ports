# D3 ADR 0022: Native forms of d3-delaunay, delaunator, and robust-predicates

- Status: accepted (2026-11-27): its code and the tests of section Tests pass.
- Date: 2026-11-27
- Related: [D3 ADR 0001](0001-upstream-sources.md), [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0014](0014-path-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-delaunay` 6.0.4 computes Delaunay triangulations and clipped Voronoi diagrams over 2D point
sets, building on two internal pure-math dependencies:

- `delaunator` 5.1.0 (`index.js`): sweep-hull Delaunay triangulation over flat `Float64Array`
  coordinates with half-edge mesh arrays (`triangles`, `halfedges`, `hull`) and in-place `update()`.
- `robust-predicates` 3.0.3 (`src/orient2d.js`, `src/util.js`): Jonathan Shewchuk's adaptive-precision
  floating-point `orient2d` orientation predicate (and `orient2dfast`).
- `d3-delaunay` 6.0.4 (`src/delaunay.js`, `src/voronoi.js`, `src/path.js`, `src/polygon.js`,
  `src/index.js`): `Delaunay` (coincident/collinear handling, `inedges`, `neighbors`, `find`,
  `render*`, `hullPolygon`, `trianglePolygons`, `voronoi`) and `Voronoi` (circumcenters, infinite
  exterior rays, Cohen–Sutherland clipping to bounds, `cellPolygon`, `cellPolygons`, `contains`,
  `neighbors`, `render*`).

Upstream JavaScript relies on untyped `[x, y]` arrays, overloaded methods returning either `void`
(when a Canvas 2D context is passed) or `String?` (when omitted), `Object.assign(polygon, {index})`
monkey-patching on array instances, out-of-bounds typed-array reads silently yielding `undefined`
(e.g. `triangles` containing `-1` in the 1-point degenerate case or `P[j]` at `j == P.length` in
`Voronoi._edge`), and build-time macro expansion in `robust-predicates`.

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module),
[D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js reference
tests), [D3 ADR 0010](0010-native-values-and-factories.md) (typed native parameters), and
[D3 ADR 0014](0014-path-native-forms.md) (`CanvasPath` / `UiPathContext`), `d3-delaunay` 6.0.4 is
ported as a standalone package `flutter_d3_delaunay_port` bundling `delaunator` 5.1.0 and
`robust-predicates` 3.0.3 (`orient2d`/`util`) internally, with **zero `dynamic`, zero `Object?`
escape hatches where generics apply, and zero JS runtime**.

## Decision

1. **Bundled pure-math dependencies inside `flutter_d3_delaunay_port`.**
   - `d3-delaunay` (`src/*.js` → `lib/src/*.dart`), `delaunator` (`index.js` →
     `lib/src/delaunator/index.dart`), and `robust-predicates` (`src/{orient2d,util}.js` →
     `lib/src/robust_predicates/{orient2d,util}.dart`) live in `packages/flutter_d3_delaunay_port`
     and move their submodule pins from `packages/flutter_d3_port/tool/port_sources.yaml` into
     `packages/flutter_d3_delaunay_port/tool/port_sources.yaml`.
   - `robust-predicates` macros (`$Fast_Two_Sum`, `$Two_Sum`, `$Two_Diff`, `$Two_Diff_Tail`,
     `$Split`, `$Two_Product`, `$Two_Product_Presplit`, `$Cross_Product`) are expanded cleanly in
     Dart per [D3 ADR 0001](0001-upstream-sources.md) item 16, and the three unused 3D/incircle
     predicates (`orient3d`, `incircle`, `insphere`) remain `n/a` per item 17.
   - `LICENSE` and `REUSE.toml` carry all three upstream notices: ISC (`Observable, Inc.` and
     `Mapbox`) for `d3-delaunay`, ISC (`Mapbox`) for `delaunator`, and `Unlicense`
     (`Vladimir Agafonkin`) for `robust-predicates` (with `LICENSES/Unlicense.txt`).

2. **Pure Dart core (`d3_delaunay.dart`) and Flutter UI layer (`flutter_d3_delaunay_port.dart`).**
   - `package:flutter_d3_delaunay_port/d3_delaunay.dart` exports every pure Dart file in
     `lib/src/` with zero Flutter import (ADR 0011), compiling cleanly on Dart VM, AOT,
     `dart2js`, and `dart2wasm`.
   - Depends on `flutter_d3_path_port: ^0.1.2` for `CanvasPath` (pure) and `UiPathContext`
     (Flutter `dart:ui.Path`).
   - `package:flutter_d3_delaunay_port/flutter_d3_delaunay_port.dart` re-exports
     `d3_delaunay.dart` and `lib/src/ui/delaunay_ui.dart`, providing typed `DelaunayUiPath` and
     `VoronoiUiPath` extensions (`toUiPath`, `hullToUiPath`, `pointsToUiPath`, `triangleToUiPath`,
     `boundsToUiPath`, `cellToUiPath`) powered by `UiPathContext`.

3. **Unboxed typed-data mesh arrays.**
   - Coordinates & circumcenters: `Float64List` (`Delaunay.points`, `Delaunator.coords`,
     `Voronoi.circumcenters`, `Voronoi.vectors`).
   - Topology arrays:
     - `Delaunator`: `Uint32List triangles`, `Int32List halfedges`, `Uint32List hull`.
     - `Delaunay`: `Int32List triangles` (zero-copy `Int32List.view` over `Delaunator.triangles`
       in normal cases, and a 3-element `Int32List` with `-1` sentinels in the 1-point degenerate
       case, matching upstream's `Int32Array(3).fill(-1)` without unsigned overflow),
       `Int32List halfedges`, `Uint32List hull`, `Int32List inedges`, and `Int32List? collinear`.

4. **Fully statically typed `Delaunay` and `Voronoi` APIs.**
   - **`Delaunay`:**
     - `Delaunay(Float64List points)` wraps `points` directly so in-place mutation + `update()` works
       without copying.
     - `Delaunay.from<T>(Iterable<T> points, {double Function(T)? x, double Function(T)? y})`
       extracts coordinates into a `Float64List` (defaulting to `$1`/`$2` when `points` is
       `Iterable<(double, double)>` and throwing `ArgumentError` otherwise if omitted).
     - `Delaunay.fromCoords(Iterable<(double, double)> points)` provides a zero-closure fast path
       for `(double, double)` coordinate sequences.
     - `Delaunay.fromIndexed<T>(Iterable<T> points, {required double Function(T, int) x, required double Function(T, int) y})`
       and `Delaunay.fromLength(int length, double Function(int) x, double Function(int) y)` cover
       index-dependent coordinate generators.
     - `Delaunay update()`, `Voronoi voronoi([(double, double, double, double) bounds])`.
     - `Iterable<int> neighbors(int i)`, `int find(double x, double y, [int i = 0])`,
       `Iterable<int> findAll(double x, double y, double radius)` (Delaunay-graph BFS radius search
       starting from `find(x, y)`, with exact coincident-point support).
     - Split typed rendering methods (no overloaded `CanvasPath? -> String?` return):
       - `void render(CanvasPath context)`, `void renderPoints(CanvasPath context, [double r = 2])`,
         `void renderHull(CanvasPath context)`, `void renderTriangle(int i, CanvasPath context)`.
       - `String? renderToSvg()`, `String? renderPointsToSvg([double r = 2])`,
         `String? renderHullToSvg()`, `String? renderTriangleToSvg(int i)`.
     - Typed `(double, double)` polygons:
       - `List<(double, double)> hullPolygon()` (closed ring, empty when `hull.isEmpty`).
       - `List<(double, double)> trianglePolygon(int i)` and
         `Iterable<List<(double, double)>> trianglePolygons()`.
   - **`Voronoi`:**
     - `Voronoi(Delaunay delaunay, [(double, double, double, double) bounds = (0, 0, 960, 500)])`
       validates `xmax >= xmin && ymax >= ymin` (throwing `ArgumentError('invalid bounds')`).
     - Fields: `final Delaunay delaunay`, `final double xmin, ymin, xmax, ymax`,
       `Float64List circumcenters`, `final Float64List vectors`.
     - `Voronoi update()`, `bool contains(int i, double x, double y)`,
       `Iterable<int> neighbors(int i)`.
     - `List<(double, double)>? cellPolygon(int i)`,
       `Iterable<List<(double, double)>> cellPolygons()`, and
       `Iterable<({int index, List<(double, double)> polygon})> cellPolygonsIndexed()` (typed
       replacement for JS `Object.assign(cell, {index: i})`).
     - Split typed rendering methods:
       - `void render(CanvasPath context)`, `void renderBounds(CanvasPath context)`,
         `void renderCell(int i, CanvasPath context)`.
       - `String? renderToSvg()`, `String? renderBoundsToSvg()`, `String? renderCellToSvg(int i)`.

5. **Hot-path optimizations across AOT, Wasm, and dart2js.**
   - Unboxed `Float64List`, `Uint32List`, and `Int32List` throughout `Delaunator`, `Delaunay`, and
     `Voronoi` with reusable scratch buffers (`_circumcenters`, `vectors`, `_edgeStack`, `_clipBuf`)
     and zero per-vertex object allocation in `update()`, `_legalize()`, `find()`, and `render*()`.
   - Inlined Shewchuk adaptive fast-path check in `orient2d` and `Delaunator.update()` so >99.9% of
     orientation predicates avoid entering `orient2dadapt`.
   - Zero-allocation `Delaunay.find()` / `_step()` using multiplication (`dx * dx + dy * dy`) instead
     of `math.pow(..., 2)` and direct `Uint32List`/`Int32List` indexing.
   - Zero-copy `Float64List` / `List<double>` clip paths in `Voronoi._clip`, `_clipFinite`,
     `_clipInfinite`, `_project`, and `_clipSegment` eliminating intermediate list allocations on
     every segment and ray.
   - Direct `CanvasPath` / `UiPathContext` rendering with zero SVG formatting or parsing.

## Rejected

- Exposing `Delaunator` and `robust-predicates` as separate pub.dev packages before any other
  package needs them: adds unnecessary workspace/publishing overhead while `d3-delaunay` is their
  sole D3 consumer. They remain cleanly organized under `lib/src/delaunator/` and
  `lib/src/robust_predicates/` and can be split later if another module requires them.
- Overloaded `String? render([CanvasPath? context])` methods: forces nullable `String?` return types
  even when drawing into a `CanvasPath` or `UiPathContext`. Splitting `render(CanvasPath)` (`void`)
  and `renderToSvg()` (`String?`) keeps both call sites strictly typed.
- Untyped `List<List<double>>` polygons with expando/wrapper `.index`: replaced by value-typed
  `List<(double, double)>` records and `cellPolygonsIndexed()`.

## Consequences

- All 41 upstream `d3-delaunay` test cases (2 files), all 14 upstream `delaunator` test cases
  (including the 8 upstream JSON fixtures on VM), and the `robust-predicates` `orient2d` /
  `orient2dfast` cases (including the 128×128 near-collinear grid and 1,000 hard fixtures on VM)
  port cleanly, alongside Node.js reference parity tests and faster-form twin tests.
- `flutter_d3_port` re-exports `flutter_d3_delaunay_port` from both `d3.dart` (pure) and
  `flutter_d3_port.dart` (with `UiPathContext` helpers).

## Tests

- `packages/flutter_d3_delaunay_port/test/delaunay_test.dart`
- `packages/flutter_d3_delaunay_port/test/voronoi_test.dart`
- `packages/flutter_d3_delaunay_port/test/delaunator/test_test.dart`
- `packages/flutter_d3_delaunay_port/test/robust_predicates/test_test.dart`
- `packages/flutter_d3_delaunay_port/test/port/delaunator_fixtures_test.dart`
- `packages/flutter_d3_delaunay_port/test/port/robust_predicates_fixtures_test.dart`
- `packages/flutter_d3_delaunay_port/test/port/reference_test.dart`
- `packages/flutter_d3_delaunay_port/test/port/faster_forms_test.dart`
- `packages/flutter_d3_delaunay_port/test/port/ui_path_test.dart`
- `packages/flutter_d3_delaunay_port/test/upstream_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
