// Ported from d3-geo v3.1.1 src/projection/conicEquidistant.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/projection/conicEquidistant.js` of d3-geo 3.1.1:
/// [geoConicEquidistant] and [geoConicEquidistantRaw].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/conic.dart';
import 'package:flutter_d3_geo_port/src/projection/equirectangular.dart';

/// `projection/conicEquidistant.js:5` `conicEquidistantRaw(y0, y1)`.
GeoRawProjection geoConicEquidistantRaw(double y0, double y1) {
  final cy0 = math.cos(y0);
  final n = y0 == y1 ? math.sin(y0) : (cy0 - math.cos(y1)) / (y1 - y0);
  if (n.abs() < geoEpsilon) return geoEquirectangularRaw;
  final g = cy0 / n + y0;

  return geoRawProjection(
    (x, y) {
      final gy = g - y;
      final nx = n * x;
      return (gy * math.sin(nx), g - gy * math.cos(nx));
    },
    invert: (x, y) {
      final gy = g - y;
      var l = math.atan2(x, gy.abs()) * geoSign(gy);
      if (gy * n < 0) {
        l -= geoPi * geoSign(x) * geoSign(gy);
      }
      return (l / n, g - geoSign(n) * math.sqrt(x * x + gy * gy));
    },
  );
}

/// `projection/conicEquidistant.js:28` `geoConicEquidistant()`.
GeoConicProjection geoConicEquidistant() =>
    geoConicProjection(geoConicEquidistantRaw)
      ..scale = 131.154
      ..center = const (0, 13.9389);
