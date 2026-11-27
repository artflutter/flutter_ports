// Ported from d3-geo v3.1.1 src/projection/conicConformal.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/projection/conicConformal.js` of d3-geo 3.1.1:
/// [geoConicConformal] and [geoConicConformalRaw].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/conic.dart';
import 'package:flutter_d3_geo_port/src/projection/mercator.dart';

@pragma('vm:prefer-inline')
double _tany(double y) => math.tan((geoHalfPi + y) / 2);

/// `projection/conicConformal.js:9` `conicConformalRaw(y0, y1)`.
GeoRawProjection geoConicConformalRaw(double y0, double y1) {
  final cy0 = math.cos(y0);
  final n = y0 == y1
      ? math.sin(y0)
      : math.log(cy0 / math.cos(y1)) / math.log(_tany(y1) / _tany(y0));
  if (n == 0 || n.isNaN) return geoMercatorRaw;
  final f = cy0 * math.pow(_tany(y0), n).toDouble() / n;

  return geoRawProjection(
    (x, y) {
      var yy = y;
      if (f > 0) {
        if (yy < -geoHalfPi + geoEpsilon) yy = -geoHalfPi + geoEpsilon;
      } else {
        if (yy > geoHalfPi - geoEpsilon) yy = geoHalfPi - geoEpsilon;
      }
      final r = f / math.pow(_tany(yy), n).toDouble();
      final nx = n * x;
      return (r * math.sin(nx), f - r * math.cos(nx));
    },
    invert: (x, y) {
      final fy = f - y;
      final r = geoSign(n) * math.sqrt(x * x + fy * fy);
      var l = math.atan2(x, fy.abs()) * geoSign(fy);
      if (fy * n < 0) {
        l -= geoPi * geoSign(x) * geoSign(fy);
      }
      return (
        l / n,
        2 * math.atan(math.pow(f / r, 1 / n).toDouble()) - geoHalfPi,
      );
    },
  );
}

/// `projection/conicConformal.js:34` `geoConicConformal()`: Lambert conformal
/// conic projection.
GeoConicProjection geoConicConformal() =>
    geoConicProjection(geoConicConformalRaw)
      ..scale = 109.5
      ..parallels = const (30, 30);
