# d3-geo port differences

This file lists the hunks of ported code that do not translate the upstream lines. Each hunk
carries the line comment `// DIVERGES(d3-geo): <ID>, <reason>`. `check:headers` pairs each
marker with a row of this file. A port-only file is not a row.

The ID starts with its category: `adapt`, `platform`, `js-semantics`, `harness` or `not-followed`,
as in the [D3 port](../../flutter_d3_port/doc/differences.md). The column "Upstream
file@version:lines" names the pin at which the porter last checked the row. Each bump checks every
row.

The port uses no JS runtime ([D3 ADR 0007](../../flutter_d3_port/doc/adr/0007-native-dart-forms.md)).
The rows `adapt-geo-*` record the native forms of
[D3 ADR 0024](../../flutter_d3_port/doc/adr/0024-geo-native-forms.md).

| ID | Dart file and symbol | Upstream file@version:lines | Category | Reason | Upstream reference | Pinning test | Re-check on bump |
|---|---|---|---|---|---|---|---|
| <a id="adapt-geo-typed-api"></a>`adapt-geo-typed-api` | `lib/src/**/*.dart`, `test/**/*_test.dart` | d3-geo `src/**/*.js`@v3.1.1, `test/**/*-test.js`@v3.1.1 | adapt | Native statically typed Dart APIs with zero `dynamic`, zero `Object?` escape hatches where generics apply, and zero JS runtime ([D3 ADR 0024](../../flutter_d3_port/doc/adr/0024-geo-native-forms.md)): sealed `GeoJsonObject` hierarchy (`GeoSphere`, `GeoPoint`, `GeoMultiPoint`, `GeoLineString`, `GeoMultiLineString`, `GeoPolygon`, `GeoMultiPolygon`, `GeoGeometryCollection`, `GeoFeature<P>`, `GeoFeatureCollection<P>`), `GeoPosition` `(double, double)` and `GeoExtent` `((double, double), (double, double))` records, typed `GeoStream`/`GeoStreamable`/`GeoTransform`, typed `GeoRawProjection`/`GeoProjection`/`GeoConicProjection`/`GeoMercatorProjection`/`GeoTransverseMercatorProjection`/`GeoIdentityProjection`/`GeoAlbersUsaProjection`, typed `GeoPath` with `draw(object, CanvasPath)` and typed `pointRadius`/`pointRadiusAccessor`/`digits`, typed `GeoInterpolator`/`GeoRotation`/`GeoGraticuleGenerator`/`GeoCircleGenerator`, and `geo*`-prefixed internal helpers avoiding bundle symbol collisions. | — | `test/**/*_test.dart`, `test/port/reference_test.dart` | Check signatures and defaults when the pin changes. |
| <a id="adapt-geo-fast-forms"></a>`adapt-geo-fast-forms` | `lib/src/**/*.dart` | d3-geo `src/**/*.js`@v3.1.1 | adapt | Faster native Dart forms with bit-identical outputs ([performance.md](performance.md)): integer-state-machine `GeoStream` implementations avoiding closure swapping, unboxed `double` Cartesian and trig math in spherical calculators (`area`, `bounds`, `centroid`, `contains`, `length`, `distance`), zero-allocation coordinate forwarding through rotation, clipping, adaptive resampling, and projection pipelines, fast integer-scaled SVG decimal formatter in `PathString`, and zero-allocation `GeoPath.draw` direct emission into `CanvasPath`/`UiPathContext`. | — | `test/port/faster_forms_test.dart`, `test/port/reference_test.dart` | Compare upstream algorithms when the pin changes. |
| <a id="adapt-geo-snapshot-numerical"></a>`adapt-geo-snapshot-numerical` | `test/snapshot_test.dart`, `test/snapshots.dart` | d3-geo `test/snapshot-test.js`@v3.1.1, `test/snapshots.js`@v3.1.1 | harness | Web-safe numerical geometry verification (`path`, `bounds`, `area`, `centroid`, `measure`, plus `UiPathContext` non-empty path check) for all 16 upstream snapshot projections instead of Node `canvas` + `pixelmatch` PNG diffing. | — | `test/snapshot_test.dart`, `test/port/reference_test.dart` | Check snapshot projection list and parameters when the pin changes. |
| <a id="platform-geo-math-last-bit"></a>`platform-geo-math-last-bit` | `lib/src/math.dart`, `lib/src/**/*.dart` | d3-geo `src/math.js`@v3.1.1 | platform | `dart:math` libm trigonometric functions (`sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`, `log`, `exp`, `pow`) can differ from V8 fdlibm in the last ULP; `geoJsRound` and `.remainder(...)` preserve JS rounding and signed remainder semantics. | — | `test/port/reference_test.dart` | Re-verify tolerances when the pin changes. |
