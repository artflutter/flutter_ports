// Ported from d3-geo v3.1.1 src/projection/azimuthalEquidistant.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/projection/azimuthalEquidistant.js` of d3-geo 3.1.1:
/// [geoAzimuthalEquidistant] and [geoAzimuthalEquidistantRaw].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/azimuthal.dart';
import 'package:flutter_d3_geo_port/src/projection/index.dart';

/// `projection/azimuthalEquidistant.js:5` `azimuthalEquidistantRaw`.
final GeoRawProjection geoAzimuthalEquidistantRaw = geoRawProjection(
  geoAzimuthalRaw((c) {
    final a = geoAcos(c);
    return a == 0 ? 0.0 : a / math.sin(a);
  }),
  invert: geoAzimuthalInvert((z) => z),
);

/// `projection/azimuthalEquidistant.js:13` `geoAzimuthalEquidistant()`.
GeoProjection geoAzimuthalEquidistant() =>
    geoProjection(geoAzimuthalEquidistantRaw)
      ..scale = 79.4188
      ..clipAngle = 180 - 1e-3;
