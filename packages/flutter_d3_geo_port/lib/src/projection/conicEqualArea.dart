// Ported from d3-geo v3.1.1 src/projection/conicEqualArea.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/projection/conicEqualArea.js` of d3-geo 3.1.1:
/// [geoConicEqualArea], [geoConicEqualAreaRaw], and [GeoConicEqualAreaRaw].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/conic.dart';
import 'package:flutter_d3_geo_port/src/projection/cylindricalEqualArea.dart';

/// Concrete raw Albers equal-area conic projection storing its precomputed
/// cone constants ([n], [c], [r0]) for unboxed projection fast paths.
// DIVERGES(d3-geo): adapt-geo-fast-forms, concrete class exposes cone
// constants for unboxed projection and resampling loops.
final class GeoConicEqualAreaRaw(
  /// Cone constant `n`.
  final double n,

  /// Cone constant `c`.
  final double c,

  /// Polar radius constant `r0 = sqrt(c) / n`.
  final double r0,
) implements GeoRawProjection {
  /// Creates a [GeoConicEqualAreaRaw] from precomputed constants [n], [c],
  /// [r0].
  this;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition call(double x, double y) {
    final r = math.sqrt(c - 2 * n * math.sin(y)) / n;
    final nx = x * n;
    return (r * math.sin(nx), r0 - r * math.cos(nx));
  }

  @override
  bool get canInvert => true;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition invert(double x, double y) {
    final r0y = r0 - y;
    var l = math.atan2(x, r0y.abs()) * geoSign(r0y);
    if (r0y * n < 0) {
      l -= geoPi * geoSign(x) * geoSign(r0y);
    }
    return (l / n, geoAsin((c - (x * x + r0y * r0y) * n * n) / (2 * n)));
  }
}

/// `projection/conicEqualArea.js:5` `conicEqualAreaRaw(y0, y1)`.
GeoRawProjection geoConicEqualAreaRaw(double y0, double y1) {
  final sy0 = math.sin(y0);
  final n = (sy0 + math.sin(y1)) / 2;
  if (n.abs() < geoEpsilon) return geoCylindricalEqualAreaRaw(y0);

  final c = 1 + sy0 * (2 * n - sy0);
  final r0 = math.sqrt(c) / n;
  return GeoConicEqualAreaRaw(n, c, r0);
}

/// `projection/conicEqualArea.js:29` `geoConicEqualArea()`: Albers equal-area
/// conic projection.
GeoConicProjection geoConicEqualArea() =>
    geoConicProjection(geoConicEqualAreaRaw)
      ..scale = 155.424
      ..center = const (0, 33.6442);
