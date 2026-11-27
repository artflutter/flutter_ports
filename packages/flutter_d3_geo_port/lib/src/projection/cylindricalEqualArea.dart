// Ported from d3-geo v3.1.1 src/projection/cylindricalEqualArea.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/projection/cylindricalEqualArea.js` of d3-geo 3.1.1:
/// [geoCylindricalEqualAreaRaw].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/math.dart';

/// `projection/cylindricalEqualArea.js:3` `cylindricalEqualAreaRaw(phi0)`.
GeoRawProjection geoCylindricalEqualAreaRaw(double phi0) {
  final cosPhi0 = math.cos(phi0);
  return geoRawProjection(
    (lambda, phi) => (lambda * cosPhi0, math.sin(phi) / cosPhi0),
    invert: (x, y) => (x / cosPhi0, geoAsin(y * cosPhi0)),
  );
}
