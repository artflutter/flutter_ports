// Ported from d3-geo v3.1.1 src/projection/transverseMercator.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/projection/transverseMercator.js` of d3-geo 3.1.1:
/// [geoTransverseMercator], [geoTransverseMercatorRaw], and
/// [GeoTransverseMercatorProjection].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/mercator.dart';

/// `projection/transverseMercator.js:4` `transverseMercatorRaw`.
final GeoRawProjection geoTransverseMercatorRaw = geoRawProjection(
  (lambda, phi) => (math.log(math.tan((geoHalfPi + phi) / 2)), -lambda),
  invert: (x, y) => (-y, 2 * math.atan(math.exp(x)) - geoHalfPi),
);

/// `projection/transverseMercator.js:12` `geoTransverseMercator`: transverse
/// spherical Mercator projection with 90° rotated coordinates.
final class GeoTransverseMercatorProjection() extends GeoMercatorProjection {
  /// Creates a [GeoTransverseMercatorProjection].
  this : super(geoTransverseMercatorRaw) {
    super.rotate = const (0, 0, 90);
    scale = 159.155;
  }

  @override
  GeoPosition get center {
    final c = super.center;
    return (c.$2, -c.$1);
  }

  @override
  set center(GeoPosition value) {
    super.center = (-value.$2, value.$1);
  }

  @override
  GeoRotationAngles get rotate {
    final r = super.rotate;
    return (r.$1, r.$2, r.$3 - 90);
  }

  @override
  set rotate(GeoRotationAngles value) {
    super.rotate = (value.$1, value.$2, value.$3 + 90);
  }
}

/// `projection/transverseMercator.js:12` `geoTransverseMercator()`: creates a
/// new [GeoTransverseMercatorProjection].
GeoTransverseMercatorProjection geoTransverseMercator() =>
    GeoTransverseMercatorProjection();
