// Ported from d3-interpolate v3.0.1 src/constant.js (ISC, Mike Bostock).

/// Port of `src/constant.js` of d3-interpolate 3.0.1: the interpolator of
/// one value.
library;

/// constant.js:1 the default export, `x => () => x`: an interpolator that
/// returns [x] for each `t`.
///
/// Upstream returns a function with no parameter. A Dart interpolator is a
/// `T Function(double t)`, so the function takes `t` and does not read it.
T Function(double t) constant<T>(T x) =>
    (t) => x;
