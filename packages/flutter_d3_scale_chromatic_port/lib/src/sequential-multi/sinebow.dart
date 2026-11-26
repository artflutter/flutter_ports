// Ported from d3-scale-chromatic v3.1.0 src/sequential-multi/sinebow.js (ISC, Mike Bostock).

/// Port of `src/sequential-multi/sinebow.js` of d3-scale-chromatic 3.1.0: the
/// cyclical sinebow color scheme.
library;

import 'dart:math' as math;

import 'package:flutter_d3_color_port/d3_color.dart';

/// `sqrt(3) / 2` for `sin(a + pi/3)` and `sin(a + 2*pi/3)`.
const double _sqrt3Over2 = 0.8660254037844386;

/// sinebow.js:7 the default export (`interpolateSinebow` of index.js:42):
/// the cyclical sinebow color scheme, returning a new [Rgb] at each call.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-color-values, fresh Rgb.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-fast-forms, sin+cos identity.
Rgb interpolateSinebow(double t) {
  final a = (0.5 - t) * math.pi;
  // DIVERGES(d3-scale-chromatic): platform-chromatic-math-last-bit, math.sin.
  final s = math.sin(a);
  final c = math.cos(a);
  final halfS = 0.5 * s;
  final c3 = _sqrt3Over2 * c;
  final xg = halfS + c3;
  final xb = c3 - halfS;
  return Rgb(255 * s * s, 255 * xg * xg, 255 * xb * xb);
}
