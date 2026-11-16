# flutter_d3_interpolate_port

A native Dart port of d3-interpolate 3.0.1, the interpolation module of D3, for Dart and Flutter.
Each interpolator is a typed Dart function. The package runs no JavaScript and uses no WebView. It
depends on `flutter_d3_color_port`, the port of d3-color, and converts a Flutter `Matrix4` to and
from the parts of a 2D transform.

This module provides a variety of interpolation methods for blending between two values. Values
may be numbers, colors, dates, lists, zoom views or 2D transforms. For example:

```dart
final i = d3.interpolateNumber(10, 20);
i(0.0); // 10.0
i(0.2); // 12.0
i(0.5); // 15.0
i(1.0); // 20.0
```

The returned function `i` is called an *interpolator*. Given a starting value *a* and an ending
value *b*, it takes a parameter *t* in the domain [0, 1] and returns the corresponding interpolated
value between *a* and *b*. An interpolator typically returns a value equivalent to *a* at *t* = 0
and a value equivalent to *b* at *t* = 1.

You can interpolate more than just numbers. To find the perceptual midpoint between steelblue and
brown:

```dart
d3.interpolateLab(d3.color('steelblue')!, d3.color('brown')!)(0.5); // rgb(139, 93, 108)
```

The result is a d3-color `Lab` color, and its `toString()` is the RGB text of d3-interpolate. Here’s
a more elaborate example demonstrating the type inference of `interpolate`:

```dart
final i = d3.interpolate<List<d3.Color>>(
  [d3.color('red')!, d3.color('blue')!],
  [d3.color('white')!, d3.color('black')!],
);
i(0.0); // [rgb(255, 0, 0), rgb(0, 0, 255)]
i(0.5); // [rgb(255, 128, 128), rgb(0, 0, 128)]
i(1.0); // [rgb(255, 255, 255), rgb(0, 0, 0)]
```

The generic value interpolator detects nested lists and colors. It takes typed values only: a
string or a map has no interpolator in Dart.

## Installing

```sh
flutter pub add flutter_d3_interpolate_port
```

```dart
import 'package:flutter_d3_color_port/d3_color.dart' as d3;
import 'package:flutter_d3_interpolate_port/flutter_d3_interpolate_port.dart' as d3;
```

`package:flutter_d3_interpolate_port/d3_interpolate.dart` has the same API with no Flutter import,
for code that runs without the Flutter engine. The colors come from `flutter_d3_color_port`.

## API Reference

### d3.interpolate<*T*>(*a*, *b*)

Returns an interpolator between the two values *a* and *b*. The interpolator implementation is
based on the runtime type of the end value *b*, using the following algorithm:

1. If *b* is null or a `bool`, use the constant *b*.
2. If *b* is a `double`, use interpolateNumber.
3. If *b* is a d3-color `Color`, use interpolateRgb.
4. If *b* is a `DateTime`, use interpolateDate.
5. If *b* is a typed-data list of numbers, for example a `Float64List`, use
   interpolateNumberArray.
6. If *b* is a `List`, use interpolateArray.
7. Else throw an `ArgumentError`, also for a `String` and a `Map`.

*a* must be of the type that *b* chooses, else the creation throws a `TypeError`. *T* must be a
supertype of the result: `interpolate<d3.Color>` and `interpolate<d3.Rgb>` take colors, and
`interpolate<d3.Hsl>` throws, because the result is an `Rgb`. An `int` is not a number here: write
`interpolate<double>(1, 2)`. On the VM and with WebAssembly an `int` *b* throws an
`ArgumentError`. When the code compiles to JavaScript, a whole number is also a `double`, so an
`int` *b* takes interpolateNumber, and an `int` item of a generic list throws a `TypeError` at a
call that gives a fraction.

### d3.interpolateNumber(*a*, *b*)

Returns an interpolator between the two numbers *a* and *b*. The returned interpolator is
equivalent to:

```dart
double interpolator(double t) => a * (1 - t) + b * t;
```

### d3.interpolateRound(*a*, *b*)

Returns an interpolator between the two numbers *a* and *b*; the interpolator is similar to
interpolateNumber, except it will round the resulting value to the nearest integer. The result is a
`double`, and a half rounds up, as `Math.round` does: `-2.5` gives `-2`.

```dart
d3.interpolateRound(10, 20)(0.26); // 13.0
```

### d3.interpolateString(*a*, *b*)

Has no Dart form. A text with numbers in it is a template in Dart code: interpolate the numbers and
write the text, for example `'${d3.interpolateRound(12, 36)(t).toInt()}px'`.

### d3.interpolateDate(*a*, *b*)

Returns an interpolator between the two dates *a* and *b*. Each call returns a new `DateTime`,
because a `DateTime` is immutable: d3-interpolate returns the same `Date` instance for every
evaluation. The result keeps the microseconds of the dates, truncated toward zero, and is in UTC
when *b* is.

```dart
final i = d3.interpolateDate(DateTime.utc(2026), DateTime.utc(2026, 1, 2));
i(0.25); // 2026-01-01 06:00:00.000Z
```

### d3.interpolateArray<*E*>(*a*, *b*)

Returns an interpolator between the two lists *a* and *b*. If *b* is a typed-data list, for
example a `Float64List`, interpolateNumberArray is called instead.

Internally, a list template is created that is the same length as *b*, with the element type of
*b*. For each element in *b*, if there exists a corresponding element in *a*, a generic
interpolator is created for the two elements using interpolate. If there is no such element, the
static value from *b* is used in the template. Then, for the given parameter *t*, the template’s
embedded interpolators are evaluated. The updated list template is then returned.

For example, if *a* is the list `[0, 1]` and *b* is the list `[1, 10, 100]`, then the result of
the interpolator for *t* = 0.5 is the list `[0.5, 5.5, 100.0]`:

```dart
d3.interpolateArray<double>([0, 1], [1, 10, 100])(0.5); // [0.5, 5.5, 100.0]
```

Note: **no defensive copy** of the template list is created; modifications of the returned list
may adversely affect subsequent evaluation of the interpolator. No copy is made for performance
reasons; interpolators are often part of the inner loop of animated transitions.

### d3.interpolateNumberArray(*a*, *b*)

Returns an interpolator between the two lists of numbers *a* and *b*. Internally, a list template
is created that is the same class and length as *b* (`b.sublist(0)`): a `Float64List` *b* gives a
`Float64List`. For each element in *b*, if there exists a corresponding element in *a*, the values
are directly interpolated in the list template. If there is no such element, the static value from
*b* is copied. The updated list template is then returned. A list of integers, for example a
`Uint8List`, stores `value.toInt()` with the rules of its class. On the VM and with WebAssembly,
`toInt()` of a value of magnitude 2^63 or more saturates at the bounds of a 64-bit `int`: 1e20
stores 255 in a `Uint8List`, where a JavaScript `Uint8Array` stores 0.

Note: For performance reasons, **no defensive copy** is made of the template list and the
arguments *a* and *b*; modifications of these lists may affect subsequent evaluation of the
interpolator.

### d3.interpolateObject(*a*, *b*)

Has no Dart form. A Dart object has typed fields, not keys: interpolate each field, or keep the
values in a list and use interpolateArray.

### d3.interpolateTransform(*a*, *b*)

Takes the place of `interpolateTransformCss` and `interpolateTransformSvg`, which parse a CSS or
SVG transform text. Returns an interpolator between the two 2D transforms *a* and *b*, each a
`TransformParts`: the standard representation of translate, rotate, *x*-skew and scale. These
component transformations are then interpolated, as CSS standardizes it for matrix decomposition.
Each call returns a new `TransformParts`.

```dart
final i = d3.interpolateTransform(
  d3.decompose(2, 0, 0, 2, 0, 12), // translateY(12px) scale(2)
  d3.decompose(1, 0, 0, 1, 48, 0), // translateX(48px)
);
final p = i(0.5); // translate(24px, 6px) scale(1.5, 1.5)
p.translateX; // 24.0
p.scaleY; // 1.5
```

The rotation takes the shortest path between the two angles. A part that is equal in *a* and *b*
stays at its value.

### d3.decompose(*a*, *b*, *c*, *d*, *e*, *f*)

Returns the `TransformParts` of the 2D matrix `matrix(a, b, c, d, e, f)`: `translateX`,
`translateY`, `rotate` and `skewX` in degrees, `scaleX` and `scaleY`. A matrix that flips gives a
negative `scaleX`. The Flutter layer (below) reads the six numbers from a `Matrix4`.

### d3.interpolateZoom(*a*, *b*)

Returns an interpolator between the two views *a* and *b* of a two-dimensional plane, based on
“Smooth and efficient zooming and panning” by Jarke J. van Wijk and Wim A.A. Nuij. Each view is a
`ZoomView`, the record of three numbers `(cx, cy, width)`. The first two coordinates *cx*, *cy*
represent the center of the viewport; the last coordinate *width* represents the size of the
viewport.

The returned interpolator exposes a *duration* property which encodes the recommended transition
duration in milliseconds. This duration is based on the path length of the curved trajectory
through *x,y* space. If you want a slower or faster transition, multiply this by an arbitrary
scale factor (*V* as described in the original paper).

```dart
final i = d3.interpolateZoom((30, 30, 40), (135, 85, 60));
final (cx, cy, width) = i(0.5); // (72.0…, 52.0…, 126.04…)
i.duration; // 2291.315684447223
```

### *interpolateZoom*.rho(*rho*)

Given a zoom interpolator, returns a new zoom interpolator using the specified curvature *rho*.
When *rho* is close to 0, the interpolator is almost linear. The default curvature is sqrt(2).

```dart
final i = d3.interpolateZoom.rho(0.5)((30, 30, 40), (135, 85, 60));
```

### d3.interpolateDiscrete(*values*)

Returns a discrete interpolator for the given list of *values*. The returned interpolator maps *t*
in [0, 1 / *n*) to *values*[0], *t* in [1 / *n*, 2 / *n*) to *values*[1], and so on, where *n* =
*values*.length. In effect, this is a lightweight quantize scale with a fixed domain of [0, 1].

```dart
final i = d3.interpolateDiscrete(['red', 'green', 'blue']);
i(0.4); // green
```

### Sampling

### d3.quantize(*interpolator*, *n*)

Returns *n* uniformly-spaced samples from the specified *interpolator*, where *n* is an integer
greater than one. The first sample is always at *t* = 0, and the last sample is always at *t* = 1.
This can be useful in generating a fixed number of samples from a given interpolator, such as to
derive the range of a quantize scale from a continuous interpolator.

```dart
d3.quantize(d3.interpolateNumber(0, 100), 5); // [0.0, 25.0, 50.0, 75.0, 100.0]
```

Caution: this method will not work with interpolators that do not return defensive copies of their
output, such as d3.interpolateArray and d3.interpolateNumberArray. For those interpolators, you
must wrap the interpolator and create a copy for each returned value. The date, color, zoom and
transform interpolators return a new value at each call.

### Color Spaces

Each color interpolator takes two d3-color `Color` values and returns a new color of its space at
each call. A CSS text converts at the call site with `d3.color(text)!`. The `toString()` of a
result is the RGB text of d3-interpolate.

### d3.interpolateRgb(*a*, *b*)

Returns an RGB color space interpolator between the two colors *a* and *b* with a configurable
gamma. If the gamma is not specified, it defaults to 1.0. The colors *a* and *b* need not be in
RGB; they will be converted to RGB using `d3.Rgb.from`. The return value of the interpolator is a
`d3.Rgb`.

```dart
d3.interpolateRgb(d3.color('purple')!, d3.color('orange')!)(0.5); // rgb(192, 83, 64)
```

### d3.interpolateRgbBasis(*colors*)

Returns a uniform nonrational B-spline interpolator through the specified list of *colors*, which
are converted to RGB color space. Implicit control points are generated such that the interpolator
returns *colors*[0] at *t* = 0 and *colors*[*colors*.length - 1] at *t* = 1. Opacity interpolation
is not currently supported. See also d3.interpolateBasis.

### d3.interpolateRgbBasisClosed(*colors*)

Returns a uniform nonrational B-spline interpolator through the specified list of *colors*, which
are converted to RGB color space. The control points are implicitly repeated such that the
resulting spline has cyclical C² continuity when repeated around *t* in [0,1]; this is useful, for
example, to create cyclical color scales. Opacity interpolation is not currently supported. See
also d3.interpolateBasisClosed.

### d3.interpolateHsl(*a*, *b*)

Returns an HSL color space interpolator between the two colors *a* and *b*. The colors *a* and *b*
need not be in HSL; they will be converted to HSL using `d3.Hsl.from`. If either color’s hue or
saturation is NaN, the opposing color’s channel value is used. The shortest path between hues is
used. The return value of the interpolator is a `d3.Hsl`.

### d3.interpolateHslLong(*a*, *b*)

Like interpolateHsl, but does not use the shortest path between hues.

### d3.interpolateLab(*a*, *b*)

Returns a CIELAB color space interpolator between the two colors *a* and *b*. The colors *a* and
*b* need not be in CIELAB; they will be converted to CIELAB using `d3.Lab.from`. The return value
of the interpolator is a `d3.Lab`.

### d3.interpolateHcl(*a*, *b*)

Returns a CIELCh<sub>ab</sub> color space interpolator between the two colors *a* and *b*. The
colors *a* and *b* need not be in CIELCh<sub>ab</sub>; they will be converted to
CIELCh<sub>ab</sub> using `d3.Hcl.from`. If either color’s hue or chroma is NaN, the opposing
color’s channel value is used. The shortest path between hues is used. The return value of the
interpolator is a `d3.Hcl`.

### d3.interpolateHclLong(*a*, *b*)

Like interpolateHcl, but does not use the shortest path between hues.

### d3.interpolateCubehelix(*a*, *b*)

Returns a Cubehelix color space interpolator between the two colors *a* and *b* using a
configurable gamma. If the gamma is not specified, it defaults to 1.0. The colors *a* and *b* need
not be in Cubehelix; they will be converted to Cubehelix using `d3.Cubehelix.from`. If either
color’s hue or saturation is NaN, the opposing color’s channel value is used. The shortest path
between hues is used. The return value of the interpolator is a `d3.Cubehelix`.

### d3.interpolateCubehelixLong(*a*, *b*)

Like interpolateCubehelix, but does not use the shortest path between hues.

### *interpolate*.gamma(*gamma*)

Given that *interpolate* is one of interpolateRgb, interpolateCubehelix or
interpolateCubehelixLong, returns a new interpolator factory of the same type using the specified
*gamma*. For example, to interpolate from purple to orange with a gamma of 2.2 in RGB space:

```dart
final interpolator = d3.interpolateRgb.gamma(2.2)(d3.color('purple')!, d3.color('orange')!);
interpolator(0.5); // rgb(204, 120, 93)
```

A gamma of 3.0 for Cubehelix emphasizes high-intensity values: `d3.interpolateCubehelix.gamma(3)`.

### d3.interpolateHue(*a*, *b*)

Returns an interpolator between the two hue angles *a* and *b*. If either hue is NaN, the opposing
value is used. The shortest path between hues is used. The return value of the interpolator is a
number in [0, 360).

```dart
d3.interpolateHue(350, 10)(0.75); // 5.0
```

### Splines

Whereas standard interpolators blend from a starting value *a* at *t* = 0 to an ending value *b*
at *t* = 1, spline interpolators smoothly blend multiple input values for *t* in [0,1] using
piecewise polynomial functions. Only cubic uniform nonrational B-splines are currently supported,
also known as basis splines.

### d3.interpolateBasis(*values*)

Returns a uniform nonrational B-spline interpolator through the specified list of *values*, which
must be numbers. Implicit control points are generated such that the interpolator returns
*values*[0] at *t* = 0 and *values*[*values*.length - 1] at *t* = 1.

### d3.interpolateBasisClosed(*values*)

Returns a uniform nonrational B-spline interpolator through the specified list of *values*, which
must be numbers. The control points are implicitly repeated such that the resulting
one-dimensional spline has cyclical C² continuity when repeated around *t* in [0,1].

### Piecewise

### d3.piecewise(*values*[, *interpolate*: *interpolate*])

Returns a piecewise interpolator, composing interpolators for each adjacent pair of *values*. The
returned interpolator maps *t* in [0, 1 / (*n* - 1)] to *interpolate*(*values*[0], *values*[1]),
*t* in [1 / (*n* - 1), 2 / (*n* - 1)] to *interpolate*(*values*[1], *values*[2]), and so on, where
*n* = *values*.length. In effect, this is a lightweight linear scale. For example, to blend through
red, green and blue:

```dart
final interpolate = d3.piecewise<d3.Color>(
  [d3.color('red')!, d3.color('green')!, d3.color('blue')!],
  interpolate: d3.interpolateRgb.gamma(2.2).call,
);
```

If *interpolate* is not specified, defaults to d3.interpolate. The factory is the named parameter
`interpolate`, after the values. An interpolator factory such as `d3.interpolateRgb` is an object
with a method `call`, so it tears off as `d3.interpolateRgb.call`.

## Flutter

`toTransformParts()` gives the `TransformParts` of a `Matrix4`, and `toMatrix4()` gives the
`Matrix4` of a `TransformParts`, so a `Transform` widget can animate between two matrices:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_d3_interpolate_port/flutter_d3_interpolate_port.dart' as d3;

final i = d3.interpolateTransform(
  Matrix4.identity().toTransformParts(),
  Matrix4.translationValues(48, 0, 0).toTransformParts(),
);
Widget frame(double t, Widget child) =>
    Transform(transform: i(t).toMatrix4(), child: child);
```

`toTransformParts()` reads the 2D affine part of the matrix: the z and perspective entries do not
count. `toMatrix4()` composes the parts in the order translate, rotate, skewX, scale.

## Differences from d3-interpolate

- A color interpolator takes two d3-color `Color` values and returns a new color of its space at
  each call. d3-interpolate also takes CSS texts, and returns the CSS text of one shared color.
- `interpolate` takes typed values only. `interpolateString` and `interpolateObject` have no Dart
  form, and a string or a map throws an `ArgumentError`.
- `interpolateDate` returns a new `DateTime` at each call, with the microseconds of the dates.
- `interpolateRgb`, `interpolateCubehelix`, `interpolateCubehelixLong` and `interpolateZoom` are
  objects with a method `call`, so `gamma` and `rho` read as in d3-interpolate. A zoom view is a
  record `(cx, cy, width)`.
- `interpolateTransformCss` and `interpolateTransformSvg` parse texts in d3-interpolate. In Dart,
  `interpolateTransform` takes the `TransformParts` of `decompose` or of a `Matrix4`.
- `piecewise(interpolate, values)` is `piecewise(values, interpolate: …)`.
- `Math.exp`, `Math.log`, `Math.pow`, `Math.atan2` and `Math.atan` are those of `dart:math`. On a
  native platform their last bit can differ from the browser. On the VM and with WebAssembly,
  `pow(1, y)` is 1 for a y of NaN or ±Infinity, where `Math.pow` gives NaN: the RGB gamma 0 gives
  `rgb(1, 1, 1)` for `rgb(0, 0, 0)`, and the Cubehelix lightness of a gamma of NaN or ±Infinity is
  the end lightness at t = 1, where d3-interpolate gives NaN.

## Performance

The figures are the time of one operation in nanoseconds. A lower number is faster. On the Mac,
each figure is the mean of two runs. The benchmark runs the same 37 cases on d3-interpolate 3.0.1
and on this package, with the same inputs. "AOT" is a compiled Dart executable or a release build
of a Flutter app. "dart2js" and "dart2wasm" are the JavaScript and WebAssembly builds of this
package.

Apple M3 Max, macOS 27. d3-interpolate, dart2js and dart2wasm run in Node.js v24.22.1.

| Case | d3-interpolate in Node.js | Port, AOT | Port, dart2js | Port, dart2wasm |
|---|---:|---:|---:|---:|
| `call.number` | 7.9 | 7.5 | 4.7 | 15 |
| `call.round` | 20 | 8.7 | 17 | 16 |
| `call.hue` | 24 | 9.9 | 21 | 17 |
| `call.basis` | 20 | 21 | 20 | 54 |
| `call.basisClosed` | 18 | 18 | 20 | 52 |
| `call.discrete` | 12 | 11 | 16 | 21 |
| `call.date` | 24 | 18 | 80 | 29 |
| `call.numberArray` | 34 | 34 | 25 | 239 |
| `call.array` | 64 | 57 | 26 | 166 |
| `call.rgb` | 112 | 13 | 17 | 16 |
| `call.rgbGamma` | 155 | 37 | 43 | 43 |
| `call.rgbBasis` | 123 | 32 | 53 | 148 |
| `call.hsl` | 134 | 13 | 16 | 16 |
| `call.hslLong` | 130 | 13 | 16 | 16 |
| `call.lab` | 148 | 13 | 16 | 17 |
| `call.hcl` | 181 | 13 | 16 | 16 |
| `call.hclLong` | 189 | 13 | 16 | 16 |
| `call.cubehelix` | 159 | 14 | 28 | 28 |
| `call.cubehelixGamma` | 162 | 14 | 29 | 28 |
| `call.piecewise` | 139 | 26 | 28 | 37 |
| `call.zoom` | 41 | 27 | 37 | 42 |
| `call.transform` | 395 | 14 | 21 | 27 |
| `text.rgb` | 112 | 40 | 34 | 39 |
| `text.hsl` | 131 | 55 | 60 | 58 |
| `text.lab` | 148 | 86 | 89 | 86 |
| `text.hcl` | 180 | 108 | 118 | 116 |
| `text.cubehelix` | 158 | 76 | 83 | 86 |
| `create.number` | 14 | 3.6 | 11 | 11 |
| `create.rgb` | 141 | 55 | 52 | 39 |
| `create.hcl` | 452 | 219 | 216 | 177 |
| `create.valueNumber` | 12 | 13 | 27 | 28 |
| `create.valueColor` | 164 | 60 | 82 | 54 |
| `create.valueArray` | 305 | 154 | 235 | 316 |
| `create.zoom` | 77 | 81 | 99 | 88 |
| `create.transform` | 2070 | 27 | 42 | 52 |
| `decompose` | 26 | 22 | 41 | 22 |
| `quantize.rgb` | 852 | 139 | 112 | 105 |

Pixel 8a (Android 17) and iPhone 17 Pro (iOS 27). The browser builds run in Chrome 157 on the
Pixel. A phone does background work, so these figures are the lower result of two or three runs.

| Case | Pixel 8a: d3-interpolate in Chrome | Pixel 8a: port, AOT | Pixel 8a: port, dart2js in Chrome | Pixel 8a: port, dart2wasm in Chrome | iPhone 17 Pro: port, AOT |
|---|---:|---:|---:|---:|---:|
| `call.number` | 15 | 15 | 15 | 21 | 7.4 |
| `call.round` | 22 | 18 | 22 | 23 | 9.4 |
| `call.hue` | 30 | 19 | 27 | 24 | 11 |
| `call.basis` | 30 | 41 | 30 | 68 | 19 |
| `call.basisClosed` | 32 | 42 | 35 | 70 | 19 |
| `call.discrete` | 22 | 21 | 27 | 31 | 12 |
| `call.date` | 80 | 95 | 59 | 48 | 20 |
| `call.numberArray` | 64 | 63 | 42 | 157 | 36 |
| `call.array` | 97 | 123 | 43 | 423 | 64 |
| `call.rgb` | 173 | 26 | 30 | 24 | 13 |
| `call.rgbGamma` | 235 | 68 | 77 | 69 | 31 |
| `call.rgbBasis` | 199 | 63 | 71 | 154 | 33 |
| `call.hsl` | 195 | 26 | 29 | 24 | 13 |
| `call.hslLong` | 198 | 26 | 29 | 24 | 13 |
| `call.lab` | 237 | 26 | 29 | 24 | 14 |
| `call.hcl` | 276 | 26 | 29 | 24 | 14 |
| `call.hclLong` | 279 | 25 | 29 | 23 | 13 |
| `call.cubehelix` | 227 | 27 | 48 | 40 | 14 |
| `call.cubehelixGamma` | 235 | 27 | 49 | 39 | 14 |
| `call.piecewise` | 209 | 46 | 43 | 56 | 25 |
| `call.zoom` | 64 | 42 | 57 | 62 | 28 |
| `call.transform` | 513 | 31 | 36 | 44 | 15 |
| `text.rgb` | 175 | 64 | 53 | 60 | 39 |
| `text.hsl` | 219 | 81 | 78 | 78 | 49 |
| `text.lab` | 243 | 142 | 136 | 138 | 74 |
| `text.hcl` | 285 | 155 | 172 | 179 | 92 |
| `text.cubehelix` | 236 | 103 | 116 | 125 | 63 |
| `create.number` | 26 | 7.4 | 22 | 19 | 3.9 |
| `create.rgb` | 225 | 109 | 90 | 62 | 71 |
| `create.hcl` | 696 | 324 | 339 | 278 | 206 |
| `create.valueNumber` | 30 | 26 | 51 | 46 | 16 |
| `create.valueColor` | 279 | 118 | 160 | 88 | 73 |
| `create.valueArray` | 577 | 305 | 800 | 409 | 153 |
| `create.zoom` | 106 | 111 | 138 | 117 | 65 |
| `create.transform` | 3613 | 57 | 70 | 80 | 33 |
| `decompose` | 80 | 54 | 62 | 38 | 21 |
| `quantize.rgb` | 1233 | 261 | 205 | 185 | 151 |

The cases:

- `call.*`: one call of an interpolator that exists, at another `t` each time. A color
  interpolator of d3-interpolate returns a CSS text. Here it returns a color.
- `text.*`: one call of a color interpolator and `toString()` of the color: the CSS text, as in
  d3-interpolate.
- `create.*`: a new interpolator and one call. `create.value*` use `interpolate(a, b)` with
  numbers, colors and lists of 16 numbers.
- `call.numberArray` and `call.array`: lists of 16 numbers (`Float64List` and `List<double>`).
- `call.transform` and `create.transform`: `interpolateTransformCss` of two `matrix(...)` texts in
  d3-interpolate, and `interpolateTransform` of two `TransformParts` here. d3-interpolate parses
  and decomposes the two texts at the creation and returns a CSS text at each call. This package
  takes and returns `TransformParts`, so these rows are not the same work.
- `decompose`: `decompose(a, b, c, d, e, f)`. `quantize.rgb`: eight colors of an RGB interpolator.

## License

ISC, the license of d3-interpolate. The `LICENSE` file keeps the notice of Mike Bostock. This
project is not affiliated with the D3 project.
