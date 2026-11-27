# d3-delaunay port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-delaunay): <ID>, <reason>`. `check:headers` pairs each
marker with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-delaunay-*` record the native forms of
[D3 ADR 0022](../../flutter_d3_port/doc/adr/0022-delaunay-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-delaunay-typed-api"></a>`adapt-delaunay-typed-api` | `lib/src/*.dart`, `lib/src/delaunator/index.dart`, `lib/src/robust_predicates/*.dart` | d3-delaunay `src/*.js`@v6.0.4, delaunator `index.js`@v5.1.0, robust-predicates `src/{orient2d,util}.js`@v3.0.3 | adapt | Native statically typed Dart APIs with zero `dynamic`, zero `Object?` escape hatches where generics apply, and zero JS runtime ([D3 ADR 0022](../../flutter_d3_port/doc/adr/0022-delaunay-native-forms.md)): typed `Float64List` coordinates/circumcenters/vectors, `Int32List`/`Uint32List` mesh arrays (`Delaunay.triangles` as `Int32List` supporting `-1` degenerate sentinels via zero-copy view), `Delaunay.from<T>` / `Delaunay.fromCoords` / `Delaunay.fromIndexed` / `Delaunay.fromLength`, `Delaunay.findAll(x, y, radius)`, split `render*(CanvasPath)` (`void`) vs `render*ToSvg()` (`String?`), typed `List<(double, double)>` polygons and `Voronoi.cellPolygonsIndexed()`, expanded Shewchuk macros in `orient2d`/`util`, and explicit Dart bounds guards where JS silently reads `undefined`. | — | `test/delaunay_test.dart`, `test/voronoi_test.dart`, `test/delaunator/test_test.dart`, `test/robust_predicates/test_test.dart`, `test/port/reference_test.dart` | Check signatures and contracts when any pin changes. |
| <a id="adapt-delaunay-fast-forms"></a>`adapt-delaunay-fast-forms` | `lib/src/delaunay.dart`, `lib/src/voronoi.dart`, `lib/src/path.dart`, `lib/src/delaunator/index.dart`, `lib/src/robust_predicates/orient2d.dart` | d3-delaunay `src/{delaunay,voronoi,path}.js`@v6.0.4, delaunator `index.js`@v5.1.0, robust-predicates `src/orient2d.js`@v3.0.3 | adapt | Faster native Dart forms with identical triangulations, circumcenters, clipped Voronoi polygons, neighbor order, and SVG output ([performance.md](performance.md)): unboxed typed-data scratch buffers and inlined `orient2d` fast-path checks in `Delaunator`, multiplication (`dx * dx + dy * dy`) instead of `math.pow` in `Delaunay._step`, zero-allocation segment/ray clipping and reusable coordinate buffers in `Voronoi`, and direct `CanvasPath` / `UiPathContext` emission. | — | `test/port/faster_forms_test.dart`, `test/port/reference_test.dart` | Compare upstream algorithms when any pin changes. |
| <a id="not-followed-robust-predicates-3d"></a>`not-followed-robust-predicates-3d` | `test/robust_predicates/test_test.dart` | robust-predicates `test/test.js`@v3.0.3 | not-followed | Per [D3 ADR 0001](../../flutter_d3_port/doc/adr/0001-upstream-sources.md) item 17, only `orient2d`/`orient2dfast` and `util` are ported because `delaunator` calls only `orient2d`; `incircle`, `orient3d`, and `insphere` are `n/a` and their upstream test cases are skipped. | — | `test/robust_predicates/test_test.dart` | Re-check if a future D3 module uses 3D or incircle predicates. |
