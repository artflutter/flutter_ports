// Ported from d3-geo v3.1.1 src/projection/azimuthalEqualArea.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/projection/azimuthalEqualArea.js` of d3-geo 3.1.1:
/// [geoAzimuthalEqualArea] and [geoAzimuthalEqualAreaRaw].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/azimuthal.dart';
import 'package:flutter_d3_geo_port/src/projection/index.dart';

/// `projection/azimuthalEqualArea.js:5` `azimuthalEqualAreaRaw`.
final GeoRawProjection geoAzimuthalEqualAreaRaw = geoRawProjection(
  geoAzimuthalRaw((cxcy) => math.sqrt(2 / (1 + cxcy))),
  invert: geoAzimuthalInvert((z) => 2 * geoAsin(z / 2)),
);

/// `projection/azimuthalEqualArea.js:13` `geoAzimuthalEqualArea()`: Lambert
/// azimuthal equal-area projection.
GeoProjection geoAzimuthalEqualArea() => geoProjection(geoAzimuthalEqualAreaRaw)
  ..scale = 124.75
  ..clipAngle = 180 - 1e-3;
