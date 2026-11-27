# D3 ADR 0020: Native forms of d3-contour

- Status: accepted (2026-11-27): its code and the tests of section Tests pass.
- Date: 2026-11-27
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0015](0015-shape-native-forms.md), [D3 ADR 0017](0017-array-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-contour` 4.0.2 computes GeoJSON `MultiPolygon` contour geometries over 2D scalar grids via
marching squares (`contours`) and estimates 2D kernel density contours over point clouds
(`contourDensity`, backed by `d3-array`'s `blur2`, `extent`, `max`, `nice`, `thresholdSturges`,
and `ticks`).

Upstream JavaScript relies on untyped plain objects (`{type: "MultiPolygon", value, coordinates}`),
dual-purpose getter/setter methods that switch on `arguments.length`, `typeof _ === "function"`,
and `Array.isArray(_)`, `null`/`undefined`/string coercion (`+value`), a function object with a
getter property (`Object.defineProperty(contour, "max", ...)`), and sparse JS arrays indexed by
integer vertex keys for marching-squares fragment stitching.

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module),
[D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js reference
tests), and [D3 ADR 0010](0010-native-values-and-factories.md) (typed native parameters),
`d3-contour` 4.0.2 is ported as a standalone pure-Dart package `flutter_d3_contour_port` depending
only on `flutter_d3_array_port: ^0.1.1`, with **zero `dynamic`, zero `Object?` escape hatches where
generics apply, zero JS runtime, and zero Flutter dependency**.

## Decision

1. **Pure Dart package (`d3_contour.dart` + `flutter_d3_contour_port.dart`).**
   `package:flutter_d3_contour_port/d3_contour.dart` exports every pure file in `lib/src/` without
   `show`/`hide` combinators (ADR 0011), and
   `package:flutter_d3_contour_port/flutter_d3_contour_port.dart` re-exports `d3_contour.dart`.
   Internal helper files (`area.dart`, `array.dart`, `ascending.dart`, `constant.dart`,
   `contains.dart`, `noop.dart`) use `contour*`-prefixed public names (`contourRingArea`,
   `contourArraySlice`, `contourAscending`, `contourConstant`, `contourContains`, `contourNoop`) so
   the `flutter_d3_port` bundle re-exports all D3 modules without symbol collisions (`d3-shape`
   exports `area`; `d3-array` exports `ascending`).

2. **Typed geometry (`ContourMultiPolygon`).**
   - `typedef ContourPoint = (double, double);`
   - `typedef ContourRing = List<(double, double)>;`
   - `typedef ContourPolygon = List<List<(double, double)>>;`
   - `final class ContourMultiPolygon` exposes:
     - `String get type => 'MultiPolygon';`
     - `final double value;`
     - `final List<List<List<(double, double)>>> coordinates;`
     - `Map<String, Object> toGeoJson()` for GeoJSON interoperability with zero `dynamic`.
   - Using Dart `(double, double)` records for 2D vertices gives value equality, compile-time arity
     safety, and concise destructuring without per-point 2-element `List<double>` allocations.

3. **Typed marching-squares generator (`Contours` & `contours()`).**
   - `final class Contours` is callable (`List<ContourMultiPolygon> call(List<double> values)`) and
     provides single-threshold evaluation (`ContourMultiPolygon contour(List<double> values, double value)`).
   - Configuration uses typed properties with optional named constructor arguments on `contours(...)`:
     - `(int, int) get size` / `set size((num, num) value)` — floors both dimensions and throws
       `RangeError('invalid size')` when either is negative or non-finite; defaults to `(1, 1)`.
     - `bool get smooth` / `set smooth(bool value)` — toggles `smoothLinear` linear interpolation;
       defaults to `true`.
     - Explicit, statically separated threshold modes instead of untyped union arguments:
       - `int? get thresholdsCount` / `set thresholdsCount(int? count)` — uniform nice ticks.
       - `List<double>? get thresholdsValues` / `set thresholdsValues(List<double>? values)` —
         explicit thresholds (defensively copied and sorted ascending per invocation).
       - `ContourThresholdsValues? get thresholdsGenerator` /
         `set thresholdsGenerator(ContourThresholdsValues? fn)` — callback
         `List<double> Function(List<double>)` returning explicit threshold values.
       - `ContourThresholdsCount? get thresholdsCountGenerator` /
         `set thresholdsCountGenerator(ContourThresholdsCount? fn)` — callback
         `int Function(List<double>)` returning an approximate threshold count (defaults to
         `thresholdSturges`).
   - `contour(values, value)` throws `ArgumentError` (`invalid value`) when `value.isNaN`.
     Non-numeric inputs (`null`, `undefined`, strings) are rejected at compile time by `double`.
   - Missing/invalid grid cells are represented natively by `double.nan` or
     `double.negativeInfinity`, both treated as holes below every finite threshold.

4. **Typed 2D kernel density estimator (`ContourDensity<T>`, `DensityContours`, `contourDensity`).**
   - `typedef DensityAccessor<T> = double Function(T d);`
   - `typedef DensityIndexedAccessor<T> = double Function(T d, int index, Iterable<T> data);`
   - `final class ContourDensity<T>` is callable (`List<ContourMultiPolygon> call(Iterable<T> data)`)
     and provides reusable grid evaluation (`DensityContours contours(Iterable<T> data)`), where
     `DensityContours` exposes `double get max` and `ContourMultiPolygon call(double value)`
     (preserving the exact threshold `value` matching upstream `density.contours(data)`).
   - Typed configuration properties and factory named parameters:
     - `x` / `y` / `weight` (`DensityAccessor<T>`), plus `xIndexed` / `yIndexed` / `weightIndexed`
       and `xConst` / `yConst` / `weightConst` setters. Default weight is constant `1.0` with a
       fast-path flag skipping closure calls.
     - `(double, double) get size` / `set size((num, num) value)` — preserves floating-point
       dimensions, throws `RangeError('invalid size')` for negative/non-finite dimensions; defaults
       to `(960.0, 500.0)`.
     - `int get cellSize` / `set cellSize(num value)` — floors `log2(value)` to power-of-two grid
       stride `1 << k`, throws `RangeError('invalid cell size')` for `< 1`; defaults to `4`.
     - `double get bandwidth` / `set bandwidth(num value)` — converts Gaussian standard deviation to
       3-pass box-blur radius `r = (sqrt(4 * b^2 + 1) - 1) / 2`, throws
       `RangeError('invalid bandwidth')` for `< 0`; defaults to `sqrt(20 * 21) ≈ 20.4939`.
     - `thresholdsCount` (default `20`), `thresholdsValues`, `thresholdsGenerator`, and
       `thresholdsCountGenerator`.
   - `contourDensity<T>({required DensityAccessor<T> x, required DensityAccessor<T> y, ...})`
     requires explicit typed accessors for arbitrary `T`; `contourDensityPoints(...)` provides
     default `(d) => d.$1` and `(d) => d.$2` accessors for `Iterable<(double, double)>`.
   - Grid accumulation uses `Float64List` (for full `blur2` fast-path integration) or `Float32List`
     matching upstream precision while guarding flat-array bounds on the final grid column/row so
     points near grid edges never throw `RangeError` (matching JS typed-array silent out-of-bounds
     writes).

5. **Marching-squares fragment stitching, linear interpolation smoothing, and hole assignment.**
   - **Flat-array fragment stitching:** Upstream maintains two sparse JS arrays (`fragmentByStart`
     and `fragmentByEnd`) and allocates per-segment `[x, y]` arrays, `{start, end, ring}` fragment
     objects, and `unshift`/`concat` ring copies on every cell. The optimized Dart implementation
     replaces per-segment heap allocations with flat integer hash/lookup tables (`Int32List`) and a
     pooled flat node/coordinate store (`Float64List` X/Y + `Int32List` doubly-linked next/prev
     pointers), enabling `O(1)` head-prepend, tail-append, and fragment concatenation without
     copying intermediate rings, materializing `List<(double, double)>` only when a ring closes.
   - **Fast `smoothLinear` pass:** Operates directly on the flat coordinate buffer (or ring list)
     with unboxed `Float64List` grid indexing, inlining `valid` and `smooth1` and skipping interior
     divisions when coordinates are half-integers (`.5`), preserving exact upstream boundary
     semantics including `±Infinity` and `NaN` cells.
   - **Unboxed `contourDensity` splatting + `blur2` integration:** Splatting uses a tight unboxed
     loop with fast paths for default `weight == 1.0` and interior grid cells, feeds `Float64List`
     directly into `flutter_d3_array_port`'s specialized `blur2` `Float64List` kernel, and fuses
     the affine `x * 2^k - o` coordinate transform into ring materialization so density contours
     never allocate intermediate pre-transform vertex records.
   - **Fast polygon containment & hole assignment:** Computes axis-aligned bounding boxes `(minX,
     minY, maxX, maxY)` for exterior polygons in the same pass as `contourRingArea` so
     `contourContains` rejects non-overlapping exterior polygons in `O(1)` before running exact
     collinearity/ray-casting (`segmentContains` + even-odd rule).

## Rejected

- Representing `ContourMultiPolygon` as `Map<String, dynamic>` or `List<dynamic>`: sacrifices
  static type safety, forces casts at every call site, and allocates boxed `List<double>` pairs per
  vertex.
- Accepting `Object?` for `thresholds(...)` or `List<Object?>` for grid values: reintroduces
  runtime type-sniffing and prevents unboxed `Float64List` indexing in hot loops.
- Returning a function with an `Expando<double>` for `density.contours(data).max`: slow hash
  lookups and poor ergonomics compared to a typed callable `DensityContours` class with a `max`
  getter.

## Consequences

- Upstream spec tests for JS-specific non-numeric coercions (`contour(values, null)`,
  `contour(values, undefined)`, `contour(values, "a string")`) are enforced at compile time by
  Dart's `double` parameter type; the `double.nan` case runs directly and the JS-only coercion
  variants are documented under `adapt-contour-typed-api` in
  `packages/flutter_d3_contour_port/doc/differences.md`.
- The 2 upstream SVG/JSDOM snapshot tests (`test/snapshot.js`, `faithfulContours` and
  `faithfulContour`) depend on unported DOM/SVG modules (`d3-axis`, `d3-geo`, `d3-scale`,
  `d3-selection`, `jsdom`); their `contourDensity` threshold and polygon geometry outputs are
  verified directly with embedded web-safe `faithful.tsv` data while the SVG snapshot comparison
  skips with a valid reason.
- All non-snapshot tests have zero `dart:io` imports and pass on VM (including
  `--experimental-faster-testing`), Chrome JS, and Chrome Wasm.

## Tests

- `packages/flutter_d3_contour_port/test/contours_test.dart` (13 upstream cases)
- `packages/flutter_d3_contour_port/test/density_test.dart` (8 upstream cases, embedded `faithful` data)
- `packages/flutter_d3_contour_port/test/snapshot_test.dart` (2 upstream snapshot cases)
- `packages/flutter_d3_contour_port/test/port/reference_test.dart` (Node.js v4.0.2 reference parity)
- `packages/flutter_d3_contour_port/test/port/faster_forms_test.dart` (baseline vs optimized twin tests)
- `packages/flutter_d3_contour_port/test/upstream_test.dart` (upstream pin & `.gitmodules` tests)
- `packages/flutter_d3_port/test/port/d3/index_test.dart` (bundle re-export test)
