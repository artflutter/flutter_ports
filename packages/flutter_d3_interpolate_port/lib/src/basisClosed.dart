// Ported from d3-interpolate v3.0.1 src/basisClosed.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/basisClosed.js` of d3-interpolate 3.0.1: the closed uniform
/// cubic B-spline through a list of numbers.
library;

import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// basisClosed.js:3 the default export (`interpolateBasisClosed` of
/// index.js:4): a closed uniform nonrational B-spline interpolator through
/// [values].
///
/// The spline is cyclical: `t` wraps to [0, 1) by its remainder, so `t = 0`
/// and `t = 1` give the same value, and each value is a control point. An
/// empty list, a NaN `t` and an infinite `t` give NaN, as upstream.
///
/// ```dart
/// final i = interpolateBasisClosed([0, 10, 0]);
/// i(0.5); // 6.666666666666666
/// ```
double Function(double t) interpolateBasisClosed(List<double> values) {
  final n = values.length;
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, NaN reads.
  if (n == 0) return (t) => double.nan;
  return (t) {
    // `t %= 1` (D3 ADR 0007 §4), then `++t` for a negative remainder.
    // DIVERGES(d3-interpolate): adapt-interpolate-typed-loops, no fmod.
    // For t in (-1, 1) the remainder is t itself (also -0.0): the test skips
    // the call of fmod, the slow part of the call on the VM.
    var x = t > -1 && t < 1 ? t : t.remainder(1);
    if (x < 0) ++x;
    // A NaN x (a NaN or infinite t): Math.floor(NaN) is NaN upstream, so
    // each value is NaN.
    if (x.isNaN) return double.nan;
    // `i = Math.floor(t * n)` is a double upstream: -0 for an x of -0, so
    // `(t - i / n) * n` is +0. The line below keeps it as a double, and the
    // index reads take its int, the same index for -0 and 0.
    final f = (x * n).floorToDouble();
    final i = f.toInt();
    final v0 = values[(i + n - 1).remainder(n)];
    final v1 = values[i.remainder(n)];
    final v2 = values[(i + 1).remainder(n)];
    final v3 = values[(i + 2).remainder(n)];
    return basis((x - f / n) * n, v0, v1, v2, v3);
  };
}
