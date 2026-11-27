// Ported from d3-geo v3.1.1 src/projection/conic.js (ISC, Mike Bostock).

/// Port of `src/projection/conic.js` of d3-geo 3.1.1: [GeoConicProjection] and
/// [geoConicProjection].
library;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/index.dart';

/// A conic [GeoProjection] with configurable standard [parallels]
/// `(phi0, phi1)` in degrees (D3 ADR 0024).
final class GeoConicProjection(
  final GeoRawProjection Function(double y0, double y1) _projectAt, [
  double phi0 = 0,
  double phi1 = geoPi / 3,
]) extends GeoProjection {
  /// Creates a [GeoConicProjection] backed by [_projectAt].
  this : super(_projectAt(phi0, phi1));

  double _phi0 = phi0;
  double _phi1 = phi1;

  /// The two standard parallels `(phi0, phi1)` in degrees.
  GeoPosition get parallels => (_phi0 * geoDegrees, _phi1 * geoDegrees);

  /// Sets the two standard parallels `(phi0, phi1)` in degrees.
  set parallels(GeoPosition value) {
    _phi0 = value.$1 * geoRadians;
    _phi1 = value.$2 * geoRadians;
    setRawProjection(_projectAt(_phi0, _phi1));
  }
}

/// `projection/conic.js:4` `conicProjection(projectAt)`.
GeoConicProjection geoConicProjection(
  GeoRawProjection Function(double y0, double y1) projectAt,
) => GeoConicProjection(projectAt);
