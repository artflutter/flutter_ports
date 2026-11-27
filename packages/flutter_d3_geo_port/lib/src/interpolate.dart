// Ported from d3-geo v3.1.1 src/interpolate.js (ISC, Mike Bostock).

/// Port of `src/interpolate.js` of d3-geo 3.1.1: [GeoInterpolator] and
/// [geoInterpolate].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';

/// A great-arc spherical interpolator between two points in degrees, exposing
/// the total angular [distance] in radians (D3 ADR 0024).
// DIVERGES(d3-geo): adapt-geo-typed-api, typed callable GeoInterpolator class
// replaces JS function with `.distance` expando property.
final class GeoInterpolator(GeoPosition a, GeoPosition b) {
  /// Creates a [GeoInterpolator] between [a] and [b] in degrees `(lon, lat)`.
  this {
    final x0 = a.$1 * geoRadians;
    final y0 = a.$2 * geoRadians;
    final x1 = b.$1 * geoRadians;
    final y1 = b.$2 * geoRadians;
    final cy0 = math.cos(y0);
    final sy0 = math.sin(y0);
    final cy1 = math.cos(y1);
    final sy1 = math.sin(y1);
    _x0Deg = x0 * geoDegrees;
    _y0Deg = y0 * geoDegrees;
    _kx0 = cy0 * math.cos(x0);
    _ky0 = cy0 * math.sin(x0);
    _sy0 = sy0;
    _kx1 = cy1 * math.cos(x1);
    _ky1 = cy1 * math.sin(x1);
    _sy1 = sy1;
    final d =
        2 *
        geoAsin(
          math.sqrt(geoHaversin(y1 - y0) + cy0 * cy1 * geoHaversin(x1 - x0)),
        );
    distance = d;
    _k = math.sin(d);
  }

  /// Great-arc distance in radians between the two endpoints.
  late final double distance;

  late final double _x0Deg;
  late final double _y0Deg;
  late final double _kx0;
  late final double _ky0;
  late final double _sy0;
  late final double _kx1;
  late final double _ky1;
  late final double _sy1;
  late final double _k;

  /// Returns the interpolated `(lon, lat)` in degrees at parameter [t] in
  /// `[0, 1]`.
  GeoPosition call(double t) {
    final d = distance;
    if (d == 0) return (_x0Deg, _y0Deg);
    final td = t * d;
    final b = math.sin(td) / _k;
    final a = math.sin(d - td) / _k;
    final x = a * _kx0 + b * _kx1;
    final y = a * _ky0 + b * _ky1;
    final z = a * _sy0 + b * _sy1;
    return (
      math.atan2(y, x) * geoDegrees,
      math.atan2(z, math.sqrt(x * x + y * y)) * geoDegrees,
    );
  }
}

/// `interpolate.js:3` `geoInterpolate(a, b)`: returns a [GeoInterpolator]
/// interpolating along the great arc between [a] and [b] in degrees.
GeoInterpolator geoInterpolate(GeoPosition a, GeoPosition b) =>
    GeoInterpolator(a, b);
