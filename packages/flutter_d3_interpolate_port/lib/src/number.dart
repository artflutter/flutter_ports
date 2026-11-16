// Ported from d3-interpolate v3.0.1 src/number.js (ISC, Mike Bostock).

/// Port of `src/number.js` of d3-interpolate 3.0.1: the interpolator of two
/// numbers.
library;

/// number.js:1 the default export (`interpolateNumber` of index.js:8): the
/// interpolator from the number [a] to the number [b].
///
/// The interpolator returns `a * (1 - t) + b * t`, so `t = 0` gives exactly
/// [a] and `t = 1` gives exactly [b]. A `t` outside [0, 1] extrapolates.
///
/// ```dart
/// final i = interpolateNumber(10, 42);
/// i(0.5); // 26.0
/// ```
double Function(double t) interpolateNumber(double a, double b) {
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no +a.
  return (t) => a * (1 - t) + b * t;
}
