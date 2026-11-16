// Ported from d3-interpolate v3.0.1 src/basis.js (ISC, Mike Bostock).

/// Port of `src/basis.js` of d3-interpolate 3.0.1: the uniform cubic
/// B-spline through a list of numbers.
library;

import 'dart:typed_data';

/// basis.js:1 `basis(t1, v0, v1, v2, v3)`: the uniform cubic B-spline of the
/// four control values [v0] to [v3] at [t1] in [0, 1].
///
/// rgb.dart and basisClosed.dart call it; index.dart does not export it, as
/// upstream index.js does not.
double basis(double t1, double v0, double v1, double v2, double v3) {
  final t2 = t1 * t1;
  final t3 = t2 * t1;
  return ((1 - 3 * t1 + 3 * t2 - t3) * v0 +
          (4 - 6 * t2 + 3 * t3) * v1 +
          (1 + 3 * t1 + 3 * t2 - 3 * t3) * v2 +
          t3 * v3) /
      6;
}

/// basis.js:9 the default export (`interpolateBasis` of index.js:3): a
/// uniform nonrational B-spline interpolator through [values].
///
/// The first and the last value are the control points of the ends:
/// `t <= 0` gives the first value and `t >= 1` the last value. The spline
/// does not pass through the other values. With fewer than two values, each
/// result is NaN, as upstream.
///
/// ```dart
/// final i = interpolateBasis([0, 10, 0]);
/// i(0.5); // 6.666666666666667
/// ```
double Function(double t) interpolateBasis(List<double> values) {
  final n = values.length - 1;
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, NaN reads.
  if (n < 1) return (t) => double.nan;
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-loops, typed reads.
  if (values is Float64List) {
    final v = values;
    return (t) {
      double x;
      int i;
      if (t <= 0) {
        x = 0;
        i = 0;
      } else if (t >= 1) {
        x = 1;
        i = n - 1;
      } else if (t > 0) {
        x = t;
        i = (t * n).toInt();
      } else {
        return double.nan;
      }
      final v1 = v[i];
      final v2 = v[i + 1];
      final v0 = i > 0 ? v[i - 1] : 2 * v1 - v2;
      final v3 = i < n - 1 ? v[i + 2] : 2 * v2 - v1;
      return basis((x - i / n) * n, v0, v1, v2, v3);
    };
  }
  return (t) {
    double x;
    int i;
    if (t <= 0) {
      x = 0;
      i = 0;
    } else if (t >= 1) {
      x = 1;
      i = n - 1;
    } else if (t > 0) {
      x = t;
      // Math.floor of t * n in (0, n): toInt() truncates to the same int.
      i = (t * n).toInt();
    } else {
      // A NaN t: Math.floor(NaN) is NaN, so each value upstream is NaN.
      return double.nan;
    }
    final v1 = values[i];
    final v2 = values[i + 1];
    final v0 = i > 0 ? values[i - 1] : 2 * v1 - v2;
    final v3 = i < n - 1 ? values[i + 2] : 2 * v2 - v1;
    return basis((x - i / n) * n, v0, v1, v2, v3);
  };
}
