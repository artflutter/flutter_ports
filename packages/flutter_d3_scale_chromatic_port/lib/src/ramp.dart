// Ported from d3-scale-chromatic v3.1.0 src/ramp.js (ISC, Mike Bostock).

/// Port of `src/ramp.js` of d3-scale-chromatic 3.1.0: builds a continuous RGB
/// B-spline interpolator from the largest palette of a ColorBrewer scheme.
library;

import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';

/// ramp.js:3 the default export: returns a uniform cubic B-spline RGB
/// interpolator over the largest palette of [scheme].
///
/// Produces bit-identical channels to `interpolateRgbBasis(scheme.last!)`
/// while computing the spline weights once across all three channels over
/// padded channel tables.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-color-values, typed Rgb list.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-fast-forms, fused RGB spline.
Rgb Function(double t) ramp(List<List<Rgb>?> scheme) {
  final palette = scheme.last!;
  final len = palette.length;
  if (len < 2) return interpolateRgbBasis(palette);
  final n = len - 1;
  // Pad by one reflected phantom control point on each side:
  // p[0] = 2 * c[0] - c[1], p[1..len] = c[0..len-1],
  // p[len + 1] = 2 * c[n] - c[n - 1].
  final pr = Float64List(len + 2);
  final pg = Float64List(len + 2);
  final pb = Float64List(len + 2);
  for (var k = 0; k < len; k++) {
    final c = palette[k];
    pr[k + 1] = c.r.isNaN || c.r == 0 ? 0.0 : c.r;
    pg[k + 1] = c.g.isNaN || c.g == 0 ? 0.0 : c.g;
    pb[k + 1] = c.b.isNaN || c.b == 0 ? 0.0 : c.b;
  }
  pr[0] = 2 * pr[1] - pr[2];
  pg[0] = 2 * pg[1] - pg[2];
  pb[0] = 2 * pb[1] - pb[2];
  pr[len + 1] = 2 * pr[len] - pr[len - 1];
  pg[len + 1] = 2 * pg[len] - pg[len - 1];
  pb[len + 1] = 2 * pb[len] - pb[len - 1];
  return (t) {
    final double x;
    final int i;
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
      return Rgb(double.nan, double.nan, double.nan);
    }
    final t1 = (x - i / n) * n;
    final t2 = t1 * t1;
    final t3 = t2 * t1;
    final w0 = 1 - 3 * t1 + 3 * t2 - t3;
    final w1 = 4 - 6 * t2 + 3 * t3;
    final w2 = 1 + 3 * t1 + 3 * t2 - 3 * t3;
    return Rgb(
      (w0 * pr[i] + w1 * pr[i + 1] + w2 * pr[i + 2] + t3 * pr[i + 3]) / 6,
      (w0 * pg[i] + w1 * pg[i + 1] + w2 * pg[i + 2] + t3 * pg[i + 3]) / 6,
      (w0 * pb[i] + w1 * pb[i + 1] + w2 * pb[i + 2] + t3 * pb[i + 3]) / 6,
    );
  };
}
