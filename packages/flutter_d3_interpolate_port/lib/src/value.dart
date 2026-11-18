// Ported from d3-interpolate v3.0.1 src/value.js (ISC, Mike Bostock).

/// Port of `src/value.js` of d3-interpolate 3.0.1: the generic interpolator,
/// which chooses the interpolator of the type of its end value.
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// value.js:11 the default export (`interpolate` of index.js:1): the
/// interpolator from [a] to [b], of the type of [b].
///
/// The runtime type of [b] chooses the interpolator, in this order:
///
/// 1. `null` or a [bool]: the constant [b].
/// 2. A [double]: `interpolateNumber`.
/// 3. A d3-color [Color]: `interpolateRgb`, whose result is an `Rgb`.
/// 4. A [DateTime]: `interpolateDate`.
/// 5. A typed-data list of numbers (a `Float64List`, a `Uint8List`, ...):
///    `interpolateNumberArray`.
/// 6. A [List]: `interpolateArray` with the generic array, item by item.
///
/// Each other type throws an [ArgumentError] here, at the creation of the
/// interpolator: an [int] (a number is a [double], D3 ADR 0010 §6), a
/// [String] (upstream `interpolateString` and the CSS color texts) and a
/// [Map] or another object (upstream `interpolateObject` and `valueOf`).
/// The [int] rule holds on the VM and with dart2wasm. With DDC and dart2js,
/// a whole number is also a [double]: an [int] [b] takes
/// `interpolateNumber` there, so `interpolate<num>(1, 2)(0.5)` is 1.5, and
/// an [int] item of a generic list throws a [TypeError] at a call whose
/// interpolated value has a fraction, which the list of [int] cannot hold.
/// A CSS color text converts at the call site, with `color(text)!`. [a] must
/// be of the type that [b] chooses, else the creation throws a [TypeError].
/// [T] must be a supertype of the result: `interpolate<Color>` and
/// `interpolate<Rgb>` take colors, `interpolate<Hsl>` throws a [TypeError].
///
/// ```dart
/// interpolate<double>(1, 2)(0.5); // 1.5
/// interpolate<Color>(color('red')!, color('blue')!)(0.5); // rgb(128, 0, 128)
/// interpolate<List<double>>([1, 10], [2, 20])(0.5); // [1.5, 15.0]
/// ```
T Function(double t) interpolate<T>(T a, T b) {
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, typed values.
  if (b == null || b is bool) return constant<T>(b);
  final Object f;
  if (b is double) {
    f = interpolateNumber(a! as double, b);
  } else if (b is Color) {
    f = interpolateRgb(a! as Color, b);
  } else if (b is DateTime) {
    f = interpolateDate(a! as DateTime, b);
  } else if (isNumberArray(b)) {
    return numberArray<T>(a! as List<num>, b as List<num>);
  } else if (b is List) {
    return genericArray<T>(a! as List<Object?>, b);
  } else {
    throw ArgumentError.value(
      b,
      'b',
      'not a value of d3-interpolate: a double, a Color, a DateTime, a list, '
          'a bool or null',
    );
  }
  return f as T Function(double t);
}
