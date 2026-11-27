// Ported from d3-geo v3.1.1 src/projection/gnomonic.js (ISC, Mike Bostock).

/// Port of `src/projection/gnomonic.js` of d3-geo 3.1.1: [geoGnomonic] and
/// [geoGnomonicRaw].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/projection/azimuthal.dart';
import 'package:flutter_d3_geo_port/src/projection/index.dart';

/// `projection/gnomonic.js:5` `gnomonicRaw`.
final GeoRawProjection geoGnomonicRaw = geoRawProjection((x, y) {
  final cy = math.cos(y);
  final k = math.cos(x) * cy;
  return (cy * math.sin(x) / k, math.sin(y) / k);
}, invert: geoAzimuthalInvert(math.atan));

/// `projection/gnomonic.js:12` `geoGnomonic()`: gnomonic azimuthal projection.
GeoProjection geoGnomonic() => geoProjection(geoGnomonicRaw)
  ..scale = 144.049
  ..clipAngle = 60;
