// Ported from d3-geo v3.1.1 src/projection/equalEarth.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/projection/equalEarth.js` of d3-geo 3.1.1: [geoEqualEarth]
/// and [geoEqualEarthRaw].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/index.dart';

const double _a1 = 1.340264;
const double _a2 = -0.081106;
const double _a3 = 0.000893;
const double _a4 = 0.003796;
final double _m = math.sqrt(3) / 2;
const int _iterations = 12;

/// `projection/equalEarth.js:11` `equalEarthRaw`.
final GeoRawProjection geoEqualEarthRaw = geoRawProjection(
  (lambda, phi) {
    final l = geoAsin(_m * math.sin(phi));
    final l2 = l * l;
    final l6 = l2 * l2 * l2;
    return (
      lambda *
          math.cos(l) /
          (_m * (_a1 + 3 * _a2 * l2 + l6 * (7 * _a3 + 9 * _a4 * l2))),
      l * (_a1 + _a2 * l2 + l6 * (_a3 + _a4 * l2)),
    );
  },
  invert: (x, y) {
    var l = y;
    var l2 = l * l;
    var l6 = l2 * l2 * l2;
    for (var i = 0; i < _iterations; ++i) {
      final fy = l * (_a1 + _a2 * l2 + l6 * (_a3 + _a4 * l2)) - y;
      final fpy = _a1 + 3 * _a2 * l2 + l6 * (7 * _a3 + 9 * _a4 * l2);
      final delta = fy / fpy;
      l -= delta;
      l2 = l * l;
      l6 = l2 * l2 * l2;
      if (delta.abs() < geoEpsilon2) break;
    }
    return (
      _m *
          x *
          (_a1 + 3 * _a2 * l2 + l6 * (7 * _a3 + 9 * _a4 * l2)) /
          math.cos(l),
      geoAsin(math.sin(l) / _m),
    );
  },
);

/// `projection/equalEarth.js:33` `geoEqualEarth()`: Equal Earth
/// pseudocylindrical equal-area projection.
GeoProjection geoEqualEarth() =>
    geoProjection(geoEqualEarthRaw)..scale = 177.158;
