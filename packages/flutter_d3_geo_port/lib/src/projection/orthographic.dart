// Ported from d3-geo v3.1.1 src/projection/orthographic.js (ISC, Mike Bostock).

/// Port of `src/projection/orthographic.js` of d3-geo 3.1.1:
/// [geoOrthographic] and [geoOrthographicRaw].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/azimuthal.dart';
import 'package:flutter_d3_geo_port/src/projection/index.dart';

/// `projection/orthographic.js:5` `orthographicRaw`.
final GeoRawProjection geoOrthographicRaw = geoRawProjection(
  (x, y) => (math.cos(y) * math.sin(x), math.sin(y)),
  invert: geoAzimuthalInvert(geoAsin),
);

/// `projection/orthographic.js:11` `geoOrthographic()`: orthographic azimuthal
/// projection.
GeoProjection geoOrthographic() => geoProjection(geoOrthographicRaw)
  ..scale = 249.5
  ..clipAngle = 90 + geoEpsilon;
