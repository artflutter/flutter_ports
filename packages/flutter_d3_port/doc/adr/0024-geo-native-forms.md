# D3 ADR 0024: Native forms of d3-geo

- Status: accepted (2026-11-27): its code and the tests of section Tests pass.
- Date: 2026-11-27
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0014](0014-path-native-forms.md), [D3 ADR 0015](0015-shape-native-forms.md), [D3 ADR 0017](0017-array-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-geo` 3.1.1 provides spherical geometry math (`geoArea`, `geoBounds`, `geoCentroid`,
`geoContains`, `geoDistance`, `geoInterpolate`, `geoLength`, `geoRotation`, `geoStream`),
GeoJSON generators (`geoGraticule`, `geoGraticule10`, `geoCircle`), spherical and planar clipping
(`geoClipAntimeridian`, `geoClipCircle`, `geoClipRectangle`, `geoClipExtent`), geographic path
rendering and planar measurement (`geoPath`), custom stream transforms (`geoTransform`,
`geoIdentity`), and 15 built-in map projections (`geoAlbers`, `geoAlbersUsa`,
`geoAzimuthalEqualArea`, `geoAzimuthalEquidistant`, `geoConicConformal`, `geoConicEqualArea`,
`geoConicEquidistant`, `geoEqualEarth`, `geoEquirectangular`, `geoGnomonic`, `geoMercator`,
`geoNaturalEarth1`, `geoOrthographic`, `geoStereographic`, `geoTransverseMercator`) plus all 13
`*Raw` projection primitives and `geoProjection` / `geoProjectionMutator`.

Upstream JavaScript represents GeoJSON as untyped plain objects (`{type, coordinates, ...}`),
uses mutable stream objects that dynamically swap `.point` / `.lineStart` / `.lineEnd` properties,
attaches `.invert` and `.distance` expando properties onto functions, uses dual-purpose
getter/setter methods that switch on `arguments.length`, forwards variadic `arguments` in
`geoCircle` and `geoProjectionMutator`, and coerces strings to numbers via unary `+`.

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module),
[D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js reference
tests), [D3 ADR 0014](0014-path-native-forms.md) (`CanvasPath` and `UiPathContext`), and
[D3 ADR 0017](0017-array-native-forms.md) (`Adder` and `range`), `d3-geo` 3.1.1 is ported as its
own standalone package `flutter_d3_geo_port` depending on `flutter_d3_array_port: ^0.1.1` and
`flutter_d3_path_port: ^0.1.2`, with **zero `dynamic`, zero `Object?` escape hatches where
generics apply, and zero JS runtime**.

## Decision

1. **Pure Dart core (`d3_geo.dart`) + direct Flutter `Canvas` layer (`flutter_d3_geo_port.dart`).**
   `package:flutter_d3_geo_port/d3_geo.dart` imports only `flutter_d3_array_port/d3_array.dart`
   and `flutter_d3_path_port/d3_path.dart` (zero Flutter imports) and exports every pure file in
   `lib/src/` without `show`/`hide` combinators (ADR 0011) so it compiles for the Dart VM, AOT,
   dart2js, and dart2wasm without the Flutter engine.
   Internal helper files (`math.dart`, `cartesian.dart`, `compose.dart`, `constant.dart`,
   `identity.dart`, `noop.dart`, `pointEqual.dart`, `polygonContains.dart`, `clip/*`, `path/*`,
   `projection/*`) use `geo*`-prefixed public names so `flutter_d3_port` re-exports all D3 modules
   without symbol collisions.
   `package:flutter_d3_geo_port/flutter_d3_geo_port.dart` exports `d3_geo.dart` plus
   `lib/src/ui/geo_ui.dart` with direct Flutter `dart:ui.Path` helpers (`GeoPathUi.toUiPath`,
   `GeoPathUi.drawToUiPath`) backed by `UiPathContext`.

2. **Sealed typed GeoJSON hierarchy (`lib/src/geojson.dart`).**
   - `typedef GeoPosition = (double lon, double lat);`
   - `typedef GeoExtent = (GeoPosition min, GeoPosition max);`
   - `typedef GeoRotationAngles = (double lambda, double phi, double gamma);`
   - `sealed class GeoJsonObject` with `String get type`, `Map<String, Object?> toJson()`, and
     `static GeoJsonObject fromJson(Map<String, Object?> json)`.
   - `sealed class GeoGeometry extends GeoJsonObject`:
     - `final class const GeoSphere extends GeoGeometry`
     - `final class const GeoPoint extends GeoGeometry` (`coordinates: GeoPosition`, optional `elevation: double?`)
     - `final class const GeoMultiPoint extends GeoGeometry` (`coordinates: List<GeoPosition>`, optional `elevations`)
     - `final class const GeoLineString extends GeoGeometry` (`coordinates: List<GeoPosition>`, optional `elevations`)
     - `final class const GeoMultiLineString extends GeoGeometry` (`coordinates: List<List<GeoPosition>>`, optional `elevations`)
     - `final class const GeoPolygon extends GeoGeometry` (`coordinates: List<List<GeoPosition>>`, optional `elevations`)
     - `final class const GeoMultiPolygon extends GeoGeometry` (`coordinates: List<List<List<GeoPosition>>>`, optional `elevations`)
     - `final class const GeoGeometryCollection extends GeoGeometry` (`geometries: List<GeoGeometry?>`)
   - `final class const GeoFeature<P> extends GeoJsonObject` (`geometry: GeoGeometry?`,
     `properties: P?`, `id: String?`) with typed `fromJson`/`toJson` converters.
   - `final class const GeoFeatureCollection<P> extends GeoJsonObject`
     (`features: List<GeoFeature<P>>`) with typed `fromJson`/`toJson` converters.
   - Optional `elevation` / `elevations` preserve 3D coordinates passed to `GeoStream.point(x, y, z)`
     while keeping the common 2D path completely unboxed.

3. **Typed stream pipeline (`lib/src/stream.dart`, `lib/src/transform.dart`).**
   - `abstract class GeoStream` with `void point(double x, double y, [double? z])`,
     `void lineStart()`, `void lineEnd()`, `void polygonStart()`, `void polygonEnd()`, and
     `void sphere()`.
   - `final class GeoStreamCallbacks extends GeoStream` for inline callback listeners.
   - `abstract interface class GeoStreamable` defining `GeoStream stream(GeoStream sink)` —
     implemented by `GeoTransform`, `GeoProjection`, `GeoIdentityProjection`,
     `GeoAlbersUsaProjection`, and `GeoClipExtent`.
   - `typedef GeoStreamTransformer = GeoStream Function(GeoStream sink);`
   - `final class GeoTransform implements GeoStreamable` and factory `geoTransform(...)`.
   - `void geoStream(GeoJsonObject? object, GeoStream stream)` switches exhaustively over the
     sealed `GeoJsonObject` hierarchy.

4. **Typed spherical geometry, interpolator, rotation, and generators.**
   - `double geoArea(GeoJsonObject? object)`
   - `GeoExtent geoBounds(GeoJsonObject? object)`
   - `GeoPosition geoCentroid(GeoJsonObject? object)`
   - `bool geoContains(GeoJsonObject? object, GeoPosition point)`
   - `double geoDistance(GeoPosition a, GeoPosition b)`
   - `double geoLength(GeoJsonObject? object)`
   - `final class GeoInterpolator` (`final double distance`, `GeoPosition call(double t)`) via
     `geoInterpolate(GeoPosition a, GeoPosition b)`.
   - `final class GeoRotation` (`GeoPosition call(GeoPosition)`, `GeoPosition invert(GeoPosition)`)
     via `geoRotation(double lambda, double phi, [double gamma = 0])`.
   - `final class GeoGraticuleGenerator` (`call() -> GeoMultiLineString`, `lines() -> List<GeoLineString>`,
     `outline() -> GeoPolygon`, typed properties `extent`, `extentMajor`, `extentMinor`, `step`,
     `stepMajor`, `stepMinor`, `precision`) via `geoGraticule()` and `geoGraticule10()`.
   - `final class GeoCircleGenerator<T>` (`call([T? datum]) -> GeoPolygon`, typed constant
     properties `center`, `radius`, `precision` and optional datum accessors `centerAccessor`,
     `radiusAccessor`, `precisionAccessor`) via `geoCircle()` and `geoCircleBy<T>(...)`.

5. **Typed clipping and raw/full projections (`lib/src/clip/*.dart`, `lib/src/projection/*.dart`).**
   - `GeoStream geoClipAntimeridian(GeoStream sink)`
   - `GeoStreamTransformer geoClipCircle(double radius)`
   - `GeoStreamTransformer geoClipRectangle(double x0, double y0, double x1, double y1)`
   - `final class GeoClipExtent implements GeoStreamable` via `geoClipExtent()`.
   - `abstract interface class GeoRawProjection` (`GeoPosition call(double x, double y)`,
     `GeoPosition? invert(double x, double y)`, `bool get canInvert`) and `geoRawProjection(...)`,
     plus all 13 `*Raw` primitives (`geoAzimuthalEqualAreaRaw`, `geoAzimuthalEquidistantRaw`,
     `geoConicConformalRaw`, `geoConicEqualAreaRaw`, `geoConicEquidistantRaw`, `geoEqualEarthRaw`,
     `geoEquirectangularRaw`, `geoGnomonicRaw`, `geoMercatorRaw`, `geoNaturalEarth1Raw`,
     `geoOrthographicRaw`, `geoStereographicRaw`, `geoTransverseMercatorRaw`).
   - `abstract interface class GeoProjector implements GeoStreamable` providing `call`, `invert`,
     `canInvert`, `scale`, `translate`, `clipExtent`, `fitExtent`, `fitSize`, `fitWidth`, and
     `fitHeight`.
   - `class GeoProjection implements GeoProjector` with typed getter/setter properties (`preclip`,
     `postclip`, `clipAngle`, `clipExtent`, `scale`, `translate`, `center`, `rotate`, `angle`,
     `reflectX`, `reflectY`, `precision`) and `rotateTo(lambda, phi, [gamma = 0])`.
   - `final class GeoConicProjection extends GeoProjection` adding `GeoPosition parallels`.
   - `final class GeoMercatorProjection extends GeoProjection` and
     `final class GeoTransverseMercatorProjection extends GeoMercatorProjection`.
   - `final class GeoIdentityProjection implements GeoProjector` via `geoIdentity()`.
   - `final class GeoAlbersUsaProjection implements GeoProjector` via `geoAlbersUsa()`.
   - `GeoProjection geoProjection(GeoRawProjection project)` and typed
     `GeoProjection Function(A args) geoProjectionMutator<A>(GeoRawProjection Function(A args) projectAt)`.
   - All 15 projection factories (`geoAlbers`, `geoAlbersUsa`, `geoAzimuthalEqualArea`,
     `geoAzimuthalEquidistant`, `geoConicConformal`, `geoConicEqualArea`, `geoConicEquidistant`,
     `geoEqualEarth`, `geoEquirectangular`, `geoGnomonic`, `geoMercator`, `geoNaturalEarth1`,
     `geoOrthographic`, `geoStereographic`, `geoTransverseMercator`).

6. **Typed `GeoPath` and direct Flutter `Canvas` rendering (`lib/src/path/index.dart`, `lib/src/ui/geo_ui.dart`).**
   - `final class GeoPath`:
     - `String? call(GeoJsonObject? object)`
     - `void draw(GeoJsonObject? object, CanvasPath context)`
     - `double area(GeoJsonObject? object)`
     - `double measure(GeoJsonObject? object)`
     - `GeoExtent bounds(GeoJsonObject? object)`
     - `GeoPosition centroid(GeoJsonObject? object)`
     - Typed properties: `GeoStreamable? projection`, `CanvasPath? context`, `double pointRadius`,
       `GeoPointRadiusAccessor? pointRadiusAccessor`, `int? digits`.
   - `extension GeoPathUi on GeoPath` (`toUiPath`, `drawToUiPath`) emitting directly into
     `UiPathContext` with zero SVG string formatting.

7. **Hot-path optimizations (row `adapt-geo-fast-forms`).**
   - Integer-state-machine `GeoStream` implementations replacing per-segment JS method swapping.
   - Unboxed `double` Cartesian and trig math in `geoArea`, `geoBounds`, `geoCentroid`,
     `geoContains`, `geoLength`, `geoDistance`, `geoRotation`, `clip/antimeridian`,
     `clip/circle`, `clip/rectangle`, and adaptive `resample`.
   - Direct coordinate forwarding (`point(x, y)`) through stream stages avoiding per-point
     list/record allocations in rotation, resampling, projection, and path emission.
   - Fast integer-scaled SVG decimal formatter in `PathString` matching JS `Number.toString()`
     semantics bit-for-bit across VM, Wasm, and dart2js.
   - Zero-allocation `GeoPath.draw(object, CanvasPath)` and `GeoPathUi.drawToUiPath` direct emission
     into `UiPathContext`.

## Rejected

- Representing GeoJSON as `Map<String, dynamic>` or untyped lists: loses compile-time geometry
  exhaustiveness, forces dynamic indexing on every coordinate, and allocates hash maps.
- Using JS-style expando properties (`.invert` on closures, `.distance` on interpolator closures,
  `.point = ...` dynamic method mutation): unsupported in statically typed Dart and prevents
  devirtualization and inlining.
- Comparing rendered PNG snapshots with `canvas`/`pixelmatch`: non-portable across OS font/AA
  rasterizers and incompatible with pure Dart / web tests; instead, all 16 upstream snapshot
  projections are verified numerically against upstream reference geometry (`path`, `bounds`,
  `area`, `centroid`, `measure`).

## Consequences

- Upstream tests that exercise JS-only dynamic inputs (`{type: "Unknown"}`, `{type: "__proto__"}`,
  string-to-number coercion like `.digits("3")` or `.stepMajor(["45", "11.25"])`, or `undefined`
  arguments) are adapted or skipped under `adapt-geo-typed-api` in
  `packages/flutter_d3_geo_port/doc/differences.md`.
- Large upstream GeoJSON/TopoJSON test fixtures (`ny.json`, `us-10m.json`, `world-atlas/50m.json`)
  are embedded or represented web-safely with zero `dart:io` so all tests pass on VM, Chrome JS,
  and Chrome Wasm.
- Flutter apps render interactive 2D maps and spinning 3D globes directly to `Canvas` via
  `GeoPath.draw` / `GeoPathUi.drawToUiPath` and `UiPathContext`.

## Tests

- All 32 upstream test files (343 cases) in `packages/flutter_d3_geo_port/test/`
- `packages/flutter_d3_geo_port/test/port/reference_test.dart` (Node.js v3.1.1 reference parity)
- `packages/flutter_d3_geo_port/test/port/faster_forms_test.dart` (baseline vs optimized twin tests)
- `packages/flutter_d3_geo_port/test/port/ui_path_context_test.dart` (direct Flutter `UiPathContext` rendering tests)
- `packages/flutter_d3_geo_port/test/upstream_test.dart` (upstream pin & `.gitmodules` tests)
- `packages/flutter_d3_port/test/port/d3/index_test.dart` (bundle re-export test)
