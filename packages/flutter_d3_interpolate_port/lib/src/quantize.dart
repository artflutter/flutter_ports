// Ported from d3-interpolate v3.0.1 src/quantize.js (ISC, Mike Bostock).

/// Port of `src/quantize.js` of d3-interpolate 3.0.1: uniform samples of an
/// interpolator.
library;

/// quantize.js:1 the default export (`quantize` of index.js:21): [n]
/// uniformly-spaced samples of [interpolator], at `t = i / (n - 1)` for `i`
/// from 0 to `n - 1`.
///
/// The first sample is at `t = 0` and the last at `t = 1`. With `n = 1`, the
/// only sample is at `t = 0 / 0`, NaN, as upstream. The samples are the
/// results of the interpolator: an interpolator that reuses its result, as
/// `interpolateArray` does, gives the same object `n` times. A negative [n]
/// throws, as `new Array(n)` does.
///
/// ```dart
/// quantize(interpolateNumber(0, 1), 5); // [0.0, 0.25, 0.5, 0.75, 1.0]
/// ```
List<T> quantize<T>(T Function(double t) interpolator, int n) =>
    List<T>.generate(n, (i) => interpolator(i / (n - 1)));
