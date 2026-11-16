# D3 ADR 0011: Native forms of d3-interpolate

- Status: accepted (2026-11-16): its code and the tests of section Tests pass.
- Date: 2026-11-16
- Supersedes: [D3 ADR 0010](0010-native-values-and-factories.md) §6, the bullet of the parameter types (`double r`, `String specifier`), for the parameters of d3-interpolate
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0010](0010-native-values-and-factories.md)

## Context

d3-interpolate 3.0.1 returns and takes JS values that typed Dart has no form for. A color
interpolator returns a CSS text, and each call writes one shared color object. `interpolate(a, b)`
dispatches on `typeof b`: a CSS color text, any other string, an object, an object with `valueOf`.
`interpolateRgb`, `interpolateCubehelix` and `interpolateZoom` are functions with the properties
`gamma`, `rho` and `duration`. `interpolateTransformCss` and `interpolateTransformSvg` parse a
transform text through the DOM. D3 ADR 0010 §6 gives a parameter the Dart type of the values that
the upstream docs allow, and the d3-interpolate docs allow a CSS text for a color and any string or
object for `interpolate`. On 2026-11-16 the maintainer chose the narrower native forms below. The
port is the package `flutter_d3_interpolate_port`, which depends on `flutter_d3_color_port`.

## Decision

1. `Rgb Function(double t) call(Color start, Color end)`: a color interpolator returns the
   d3-color `Color` of its space (`Rgb`, `Hsl`, `Lab`, `Hcl` or `Cubehelix`), a new object at each
   call. No two results share an object. `toString()` of a result is the upstream text.
2. `interpolateRgb(color('steelblue')!, color('brown')!)`: a color interpolator takes `Color`
   arguments only. A CSS text converts at the call site, with `color(text)!` or `Rgb.parse(text)`.
3. `T Function(double t) interpolate<T>(T a, T b)`: the generic interpolator takes typed values
   only: `double`, `Color`, `DateTime`, a `typed_data` list of numbers, a `List` of these, `bool`
   and `null` (a constant). The runtime type of `b` chooses the interpolator. Any other type,
   `String` and `Map` included, throws an `ArgumentError` at the creation of the interpolator.
   An `int` is not a number there. On JavaScript numbers (DDC, dart2js) a whole number is also a
   `double`, so an `int` `b` interpolates as a number.
   `interpolateString` (`src/string.js`) and `interpolateObject` (`src/object.js`) have no Dart
   form.
4. `interpolateArray<E>(a, b)`, `interpolateNumberArray(a, b)`: the result list is one list,
   reused across calls, as upstream. It has the class and the element type of `b`.
   `interpolateDate(a, b)` returns a new `DateTime` at each call, because a `DateTime` is
   immutable: its time keeps the microseconds of the dates, truncated toward zero, in UTC when `b`
   is.
5. `interpolateRgb.gamma(2.2)(a, b)`: a function with properties is a const object of a final
   callable class. `InterpolateRgb` and `InterpolateCubehelix` have `call(start, end)` and
   `gamma(y)`, `InterpolateZoom` has `call(p0, p1)` and `rho(rho)`, and the zoom interpolator
   `ZoomInterpolator` has `call(t)` and the field `duration`. `gamma` and `rho` return a new
   object. Where a function of two colors is needed, the object tears off as
   `interpolateRgb.call`.
6. `typedef ZoomView = (double, double, double)`: a zoom view `[ux, uy, w]` is a record. The
   port of `interpolateZoom` is complete.
7. `TransformParts decompose(a, b, c, d, e, f)` and
   `TransformParts Function(double t) interpolateTransform(TransformParts a, TransformParts b)`:
   the transform interpolator takes and returns the six parts of `decompose` (`translateX`,
   `translateY`, `rotate`, `skewX`, `scaleX` and `scaleY`) as the immutable class
   `TransformParts`. `interpolateTransform` is the name of the inner upstream function.
   `src/transform/parse.js` has no Dart file. The Flutter layer converts a `Matrix4` with
   `toTransformParts()` and `toMatrix4()`; the pure library `d3_interpolate.dart` has no Flutter
   import.

The `doc/differences.md` of the package has one row for each item:
`adapt-interpolate-color-values` (1 and 2), `adapt-interpolate-typed-values` (3),
`adapt-interpolate-date-value` (4), `adapt-interpolate-function-properties` (5),
`adapt-interpolate-zoom-records` (6) and `adapt-interpolate-typed-transform` (7).

## Rejected

- A `String` or `Map` dispatch in `interpolate`: a JS union in Dart, with no static type check.
- A CSS text as the result of a color interpolator: a caller that needs the color parses the text
  again, and the typed `Color` gives the text with `toString()`.
- A parse of CSS and SVG transform texts: Flutter has no DOM, and a Flutter app holds a `Matrix4`,
  not a transform text.
- `AffineMatrix` of `vector_graphics_compiler` as the input of the transform: it adds seven
  packages of an SVG compiler (the package and its six dependencies) for one 2D matrix that the
  `Matrix4` of Flutter holds.

## Consequences

- The spec cases with strings, objects, `undefined`, `arguments`, `new Number` or a gamma to
  coerce skip as `diverges: adapt-interpolate-typed-values`. The case of the reused date skips as
  `diverges: adapt-interpolate-date-value`.
- Each call of a color interpolator allocates one color object.
- The package depends on `flutter_d3_color_port` and on `vector_math`, the matrix package of
  Flutter.
- A later D3 module that interpolates (d3-scale, d3-transition) takes these typed interpolators.

## Tests

- `packages/flutter_d3_interpolate_port/test/value_test.dart`
- `packages/flutter_d3_interpolate_port/test/rgb_test.dart`
- `packages/flutter_d3_interpolate_port/test/cubehelix_test.dart`
- `packages/flutter_d3_interpolate_port/test/date_test.dart`
- `packages/flutter_d3_interpolate_port/test/zoom_test.dart`
- `packages/flutter_d3_interpolate_port/test/port/transform_test.dart`
- `packages/flutter_d3_interpolate_port/test/port/transform_matrix_test.dart`
- `packages/flutter_d3_interpolate_port/test/port/reference_test.dart`
- `packages/flutter_d3_interpolate_port/test/port/native_numbers_test.dart`
