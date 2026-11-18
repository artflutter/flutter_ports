// Ported from d3-interpolate v3.0.1 src/array.js (ISC, Mike Bostock).

/// Port of `src/array.js` of d3-interpolate 3.0.1: the interpolator of two
/// lists.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// array.js:4 the default export (`interpolateArray` of index.js:2): the
/// interpolator from the items of [a] to the items of [b].
///
/// A typed-data list of numbers [b] (a `Float64List`, a `Uint8List`, ...)
/// takes `interpolateNumberArray`. Each other [b] takes the generic array:
/// each item of [a] interpolates to the item of [b] at its index with the
/// generic `interpolate`, so the items can be numbers, colors, dates and
/// nested lists. The items of [b] past the end of [a] stay as they are, and
/// the items of [a] past the end of [b] do not count.
///
/// The result is a list of the class and element type of [b]
/// (`b.toList()` for the generic array): one list that each call writes and
/// returns, as upstream.
///
/// ```dart
/// final i = interpolateArray<double>([2, 12], [4, 24, 12]);
/// i(0.5); // [3.0, 18.0, 12.0]
/// ```
List<E> Function(double t) interpolateArray<E>(List<E> a, List<E> b) =>
    isNumberArray(b)
    ? numberArray<List<E>>(a as List<num>, b as List<num>)
    : genericArray<List<E>>(a, b);

/// array.js:8 `genericArray(a, b)`: the generic array interpolator of
/// [interpolateArray], whose result is typed as [R].
///
/// The result is `b.toList()`, a list with the element type of [b]: the
/// items of [b] past the end of [a] are already in place, and each call
/// writes the interpolated items into it and returns it. [R] must be a
/// supertype of that list: the generic `interpolate<T>` and
/// [interpolateArray] give the type of their result. An item interpolator
/// whose result does not fit the element type of [b] throws a [TypeError]
/// at the call, for example an `Hsl` item, which interpolates to an `Rgb`.
R Function(double t) genericArray<R>(List<Object?> a, List<Object?> b) {
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no undefined.
  final nb = b.length;
  final na = min(nb, a.length);
  if (a is List<double> && b is List<double>) {
    // DIVERGES(d3-interpolate): adapt-interpolate-typed-loops, no closures.
    // Each item interpolator is `interpolateNumber(a[i], b[i])` (value.js
    // gives a number pair to number.js), which keeps its two numbers: one
    // Float64List keeps the pairs here, and the loop has the line of
    // number.js.
    final x = Float64List(2 * na);
    for (var i = 0; i < na; ++i) {
      x[2 * i] = a[i];
      x[2 * i + 1] = b[i];
    }
    final c = b.toList();
    final result = c as R;
    return (t) {
      for (var i = 0; i < na; ++i) {
        c[i] = x[2 * i] * (1 - t) + x[2 * i + 1] * t;
      }
      return result;
    };
  }
  final x = List<Object? Function(double t)>.generate(
    na,
    (i) => interpolate<Object?>(a[i], b[i]),
  );
  // `c[i] = b[i]` for i from na to nb: the copy of b holds them.
  final c = b.toList();
  final result = c as R;
  return (t) {
    for (var i = 0; i < na; ++i) {
      c[i] = x[i](t);
    }
    return result;
  };
}
