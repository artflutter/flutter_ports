// Ported from d3-geo v3.1.1 src/cartesian.js (ISC, Mike Bostock).

/// Port of `src/cartesian.js` of d3-geo 3.1.1: spherical/Cartesian 3D vector
/// conversions and operations.
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';

/// A 3D unit-sphere Cartesian vector `(x, y, z)`.
typedef GeoCartesian3 = (double x, double y, double z);

/// `cartesian.js:3` `spherical(cartesian)`: converts a 3D Cartesian vector to
/// spherical radians `(lambda, phi)`.
@pragma('vm:prefer-inline')
GeoPosition geoSpherical(GeoCartesian3 cartesian) =>
    (math.atan2(cartesian.$2, cartesian.$1), geoAsin(cartesian.$3));

/// `cartesian.js:7` `cartesian(spherical)`: converts spherical radians
/// `(lambda, phi)` to a 3D unit Cartesian vector.
@pragma('vm:prefer-inline')
GeoCartesian3 geoCartesian(GeoPosition spherical) {
  final lambda = spherical.$1;
  final phi = spherical.$2;
  final cosPhi = math.cos(phi);
  return (cosPhi * math.cos(lambda), cosPhi * math.sin(lambda), math.sin(phi));
}

/// `cartesian.js:12` `cartesianDot(a, b)`: 3D dot product.
@pragma('vm:prefer-inline')
double geoCartesianDot(GeoCartesian3 a, GeoCartesian3 b) =>
    a.$1 * b.$1 + a.$2 * b.$2 + a.$3 * b.$3;

/// `cartesian.js:16` `cartesianCross(a, b)`: 3D cross product.
@pragma('vm:prefer-inline')
GeoCartesian3 geoCartesianCross(GeoCartesian3 a, GeoCartesian3 b) => (
  a.$2 * b.$3 - a.$3 * b.$2,
  a.$3 * b.$1 - a.$1 * b.$3,
  a.$1 * b.$2 - a.$2 * b.$1,
);

/// `cartesian.js:21` `cartesianAddInPlace(a, b)`: vector sum `a + b`.
// DIVERGES(d3-geo): adapt-geo-typed-api, returns an immutable GeoCartesian3
// record instead of mutating a JS array in place.
@pragma('vm:prefer-inline')
GeoCartesian3 geoCartesianAdd(GeoCartesian3 a, GeoCartesian3 b) =>
    (a.$1 + b.$1, a.$2 + b.$2, a.$3 + b.$3);

/// `cartesian.js:25` `cartesianScale(vector, k)`: scales [vector] by [k].
@pragma('vm:prefer-inline')
GeoCartesian3 geoCartesianScale(GeoCartesian3 vector, double k) =>
    (vector.$1 * k, vector.$2 * k, vector.$3 * k);

/// `cartesian.js:30` `cartesianNormalizeInPlace(d)`: normalizes [d] to unit
/// length.
// DIVERGES(d3-geo): adapt-geo-typed-api, returns a normalized GeoCartesian3
// record instead of mutating a JS array in place.
@pragma('vm:prefer-inline')
GeoCartesian3 geoCartesianNormalize(GeoCartesian3 d) {
  final l = math.sqrt(d.$1 * d.$1 + d.$2 * d.$2 + d.$3 * d.$3);
  return (d.$1 / l, d.$2 / l, d.$3 / l);
}
