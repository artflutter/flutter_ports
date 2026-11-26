// Ported from d3-shape v3.2.0 src/pointRadial.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/pointRadial.js` of d3-shape 3.2.0.
library;

import 'dart:math' as math;

/// `pointRadial.js:1` default export: converts polar `(angle, radius)` (where
/// `angle = 0` is at 12 o'clock and increases clockwise) to Cartesian `(x, y)`.
// DIVERGES(d3-shape): adapt-shape-typed-api, returns a (double, double) record.
@pragma('vm:prefer-inline')
(double, double) pointRadial(double angle, double radius) {
  final a = angle - math.pi / 2;
  return (radius * math.cos(a), radius * math.sin(a));
}
