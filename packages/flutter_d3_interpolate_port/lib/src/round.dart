// Ported from d3-interpolate v3.0.1 src/round.js (ISC, Mike Bostock).

/// Port of `src/round.js` of d3-interpolate 3.0.1: the interpolator of two
/// numbers that rounds its result.
library;

/// round.js:1 the default export (`interpolateRound` of index.js:11): the
/// interpolator from the number [a] to the number [b] that rounds its result
/// to the nearest whole number.
///
/// The interpolator returns `Math.round(a * (1 - t) + b * t)` as a `double`:
/// a half rounds toward positive infinity (`-2.5` gives `-2`), a value in
/// [-0.5, 0) gives `-0.0`, and NaN and the infinities stay as they are. The
/// ends [a] and [b] are not rounded before the interpolation.
///
/// ```dart
/// final i = interpolateRound(10, 42);
/// i(0.3); // 20.0
/// ```
double Function(double t) interpolateRound(double a, double b) {
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no +a.
  return (t) => _mathRound(a * (1 - t) + b * t);
}

/// `Math.round(x)`: the whole number nearest to [x], where a half rounds
/// toward positive infinity.
///
/// [double.roundToDouble] rounds a half away from zero (D3 ADR 0007 §4), so
/// a negative half (`r - x` is exactly -0.5) takes the whole number above.
/// `-(-r - 1)` is that number, with -0.0 for `x = -0.5`, as `Math.round`.
/// `r - x` is exact: `r` and `x` are within a factor of two of each other,
/// or `r` is zero.
double _mathRound(double x) {
  final r = x.roundToDouble();
  return r - x == -0.5 ? -(-r - 1) : r;
}
