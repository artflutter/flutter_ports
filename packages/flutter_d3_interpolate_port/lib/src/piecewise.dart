// Ported from d3-interpolate v3.0.1 src/piecewise.js (ISC, Mike Bostock).

/// Port of `src/piecewise.js` of d3-interpolate 3.0.1: the piecewise
/// interpolator of a list of values.
library;

import 'dart:math' as math;

import 'package:flutter_d3_interpolate_port/src/value.dart' as value;

/// piecewise.js:3 the default export (`piecewise` of index.js:20): the
/// piecewise interpolator through [values], with the interpolator factory
/// [interpolate] for each pair of adjacent values.
///
/// Upstream overloads on its argument count: `piecewise(values)` and
/// `piecewise(interpolate, values)`. Here [interpolate] is a named
/// parameter, and its default is the generic `interpolate` of value.dart.
/// For `n + 1` values, `t` in [i / n, (i + 1) / n] gives the interpolator of
/// the pair at the index `i`, at `t * n - i`. A `t` outside [0, 1]
/// extrapolates the first or the last pair.
///
/// A list of fewer than two values has no pair: each call throws a
/// [RangeError], where upstream calls `undefined` and throws a `TypeError`.
/// A NaN `t` throws an [UnsupportedError] (the `toInt()` of NaN), where
/// upstream throws a `TypeError`.
///
/// ```dart
/// final i = piecewise<double>([0, 2, 10]);
/// i(0.75); // 6.0
/// final c = piecewise<Color>(
///   [color('red')!, color('green')!, color('blue')!],
///   interpolate: interpolateRgb.call,
/// );
/// ```
T Function(double t) piecewise<T>(
  List<T> values, {
  T Function(double t) Function(T a, T b)? interpolate,
}) {
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, named param.
  final factory = interpolate ?? value.interpolate<T>;
  final n = values.length - 1;
  // `while (i < n) I[i] = interpolate(v, v = values[++i])`: the pairs in
  // their order, with no read of values[0] for an empty list.
  final pairs = List<T Function(double t)>.generate(
    n < 0 ? 0 : n,
    (i) => factory(values[i], values[i + 1]),
  );
  return (t) {
    final x = t * n;
    // The index in doubles: the floor of an infinite x is infinite, and the
    // clamp gives a whole number before toInt().
    final i = math.max<double>(0, math.min(n - 1.0, x.floorToDouble())).toInt();
    return pairs[i](x - i);
  };
}
