// Ported from d3-geo v3.1.1 src/projection/azimuthal.js (ISC, Mike Bostock).

/// Port of `src/projection/azimuthal.js` of d3-geo 3.1.1: [geoAzimuthalRaw]
/// and [geoAzimuthalInvert].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';

/// `projection/azimuthal.js:3` `azimuthalRaw(scale)`: builds a forward
/// azimuthal projection function from [scale].
GeoPosition Function(double x, double y) geoAzimuthalRaw(
  double Function(double cxcy) scale,
) => (x, y) {
  final cx = math.cos(x);
  final cy = math.cos(y);
  final k = scale(cx * cy);
  if (k == double.infinity) return const (2.0, 0.0);
  return (k * cy * math.sin(x), k * math.sin(y));
};

/// `projection/azimuthal.js:16` `azimuthalInvert(angle)`: builds an inverse
/// azimuthal projection function from [angle].
GeoPosition Function(double x, double y) geoAzimuthalInvert(
  double Function(double z) angle,
) => (x, y) {
  final z = math.sqrt(x * x + y * y);
  final c = angle(z);
  final sc = math.sin(c);
  final cc = math.cos(c);
  return (math.atan2(x * sc, z * cc), geoAsin(z != 0 ? y * sc / z : 0.0));
};
