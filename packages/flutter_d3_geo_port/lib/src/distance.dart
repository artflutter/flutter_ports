// Ported from d3-geo v3.1.1 src/distance.js (ISC, Mike Bostock).

/// Port of `src/distance.js` of d3-geo 3.1.1: [geoDistance].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';

/// `distance.js:6` `geoDistance(a, b)`: returns the great-arc distance in
/// radians between the two points [a] and [b] specified in degrees
/// `(lon, lat)`.
// DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoPosition record parameters.
// DIVERGES(d3-geo): adapt-geo-fast-forms, direct unboxed Vincenty formula
// avoiding GeoLineString + _LengthStream + Adder allocations.
double geoDistance(GeoPosition a, GeoPosition b) {
  final l0 = a.$1 * geoRadians;
  final p0 = a.$2 * geoRadians;
  final sinPhi0 = math.sin(p0);
  final cosPhi0 = math.cos(p0);
  final l1 = b.$1 * geoRadians;
  final p1 = b.$2 * geoRadians;
  final sinPhi1 = math.sin(p1);
  final cosPhi1 = math.cos(p1);
  final delta = (l1 - l0).abs();
  final cosDelta = math.cos(delta);
  final sinDelta = math.sin(delta);
  final cx = cosPhi1 * sinDelta;
  final cy = cosPhi0 * sinPhi1 - sinPhi0 * cosPhi1 * cosDelta;
  final cz = sinPhi0 * sinPhi1 + cosPhi0 * cosPhi1 * cosDelta;
  return math.atan2(math.sqrt(cx * cx + cy * cy), cz);
}
