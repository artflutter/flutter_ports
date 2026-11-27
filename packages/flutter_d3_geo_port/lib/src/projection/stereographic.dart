// Ported from d3-geo v3.1.1 src/projection/stereographic.js (ISC, Mike Bostock).

/// Port of `src/projection/stereographic.js` of d3-geo 3.1.1:
/// [geoStereographic] and [geoStereographicRaw].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/projection/azimuthal.dart';
import 'package:flutter_d3_geo_port/src/projection/index.dart';

/// `projection/stereographic.js:5` `stereographicRaw`.
final GeoRawProjection geoStereographicRaw = geoRawProjection((x, y) {
  final cy = math.cos(y);
  final k = 1 + math.cos(x) * cy;
  return (cy * math.sin(x) / k, math.sin(y) / k);
}, invert: geoAzimuthalInvert((z) => 2 * math.atan(z)));

/// `projection/stereographic.js:14` `geoStereographic()`: stereographic
/// conformal azimuthal projection.
GeoProjection geoStereographic() => geoProjection(geoStereographicRaw)
  ..scale = 250
  ..clipAngle = 142;
