# d3-contour port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-contour): <ID>, <reason>`. `check:headers` pairs each
marker with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-contour-*` record the native forms of
[D3 ADR 0020](../../flutter_d3_port/doc/adr/0020-contour-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-contour-typed-api"></a>`adapt-contour-typed-api` | `lib/src/*.dart` | d3-contour `src/*.js`@v4.0.2 | adapt | Native statically typed Dart APIs with zero `dynamic`, zero `Object?` escape hatches where generics apply, and zero JS runtime ([D3 ADR 0020](../../flutter_d3_port/doc/adr/0020-contour-native-forms.md)): typed `ContourMultiPolygon` with `(double, double)` vertex records and `toGeoJson()` helper; typed `Contours` and `ContourDensity<T>` classes with explicit `thresholdsCount`/`thresholdsValues`/`thresholdsGenerator`/`thresholdsCountGenerator` properties instead of untyped union arguments; typed `DensityContours` callable with `max` getter instead of JS function expando properties; `contour*`-prefixed internal helpers (`contourRingArea`, `contourArraySlice`, `contourAscending`, `contourConstant`, `contourContains`, `contourNoop`) avoiding bundle symbol collisions; and `double.nan` / `-Infinity` for invalid grid cells. | — | `test/contours_test.dart`, `test/density_test.dart`, `test/port/reference_test.dart` | Check signatures and error contracts when the pin changes. |
| <a id="adapt-contour-fast-forms"></a>`adapt-contour-fast-forms` | `lib/src/contours.dart`, `lib/src/density.dart`, `lib/src/area.dart`, `lib/src/contains.dart` | d3-contour `src/contours.js`@v4.0.2, `src/density.js`@v4.0.2, `src/area.js`@v4.0.2, `src/contains.js`@v4.0.2 | adapt | Faster native Dart forms with identical outputs ([performance.md](performance.md)): unboxed `Float64List` grid indexing, flat `Int32List`/`Float64List` doubly-linked fragment stitching in marching squares avoiding per-segment heap allocations and `unshift`/`concat` ring copies, inlined `smoothLinear` pass with integer-coordinate fast checks, unboxed `contourDensity` splatting feeding `blur2`'s `Float64List` kernel with fused affine ring transform, and bounding-box pre-rejection before ray-casting in hole assignment. | — | `test/port/faster_forms_test.dart`, `test/port/reference_test.dart` | Compare upstream algorithms when the pin changes. |
| <a id="harness-contour-snapshots"></a>`harness-contour-snapshots` | `test/snapshot_test.dart` | d3-contour `test/snapshot.js`@v4.0.2:1-48, `test/snapshots/index.js`@v4.0.2:1-82 | harness | Upstream SVG snapshot tests render through `d3-axis`, `d3-geo`, `d3-scale`, `d3-selection`, `htl`, and `jsdom`. The underlying `contourDensity` threshold and polygon geometry outputs are verified directly against embedded web-safe `faithful.tsv` data; SVG DOM string comparison skips until those DOM/SVG modules are ported. | — | `test/snapshot_test.dart`, `test/density_test.dart` | Re-check when `d3-geo`, `d3-scale`, and `d3-axis` are ported. |
