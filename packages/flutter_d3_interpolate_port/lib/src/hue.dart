// Ported from d3-interpolate v3.0.1 src/hue.js (ISC, Mike Bostock).

/// Port of `src/hue.js` of d3-interpolate 3.0.1: the interpolator of two
/// angles in degrees.
library;

import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// hue.js:3 the default export (`interpolateHue` of index.js:7): the
/// interpolator from the angle [a] to the angle [b] in degrees, along the
/// shortest path.
///
/// Each result is in [0, 360). A NaN angle takes the other angle, and two
/// NaN angles give NaN.
///
/// ```dart
/// final i = interpolateHue(10, 350);
/// i(0.2); // 6.0
/// i(0.6); // 358.0
/// ```
double Function(double t) interpolateHue(double a, double b) {
  // DIVERGES(d3-interpolate): adapt-interpolate-typed-values, no +a.
  final i = hue(a, b);
  return (t) {
    final x = i(t);
    return x - 360 * (x / 360).floorToDouble();
  };
}
