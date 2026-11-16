// Ported from d3-interpolate v3.0.1 src/discrete.js (ISC, Mike Bostock).

/// Port of `src/discrete.js` of d3-interpolate 3.0.1: the interpolator of a
/// list of discrete values.
library;

import 'dart:math' as math;

/// discrete.js:1 the default export (`interpolateDiscrete` of index.js:6): a
/// discrete interpolator over [range].
///
/// For `n` values, `t` in [i / n, (i + 1) / n) gives the value at the index
/// `i`. A `t` below 0 gives the first value and a `t` at or above 1 the last
/// value. The values can be of any type: they do not interpolate.
///
/// A NaN `t` has no value: upstream returns `undefined`, and here the call
/// throws an [UnsupportedError] (the `toInt()` of NaN). An empty [range]
/// throws a [RangeError] at each call, where upstream returns `undefined`.
///
/// ```dart
/// final i = interpolateDiscrete(['red', 'green', 'blue']);
/// i(0.5); // 'green'
/// ```
T Function(double t) interpolateDiscrete<T>(List<T> range) {
  final n = range.length;
  return (t) {
    // The index in doubles: the floor of an infinite t is infinite, and the
    // clamp gives a whole number before toInt().
    final i = math.max<double>(0, math.min(n - 1.0, (t * n).floorToDouble()));
    // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no undefined.
    return range[i.toInt()];
  };
}
