// Ported from d3-geo v3.1.1 src/projection/mercator.js (ISC, Mike Bostock).

/// Port of `src/projection/mercator.js` of d3-geo 3.1.1: [geoMercator],
/// [geoMercatorRaw], and [GeoMercatorProjection].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/index.dart';
import 'package:flutter_d3_geo_port/src/rotation.dart';

/// `projection/mercator.js:5` `mercatorRaw`.
final GeoRawProjection geoMercatorRaw = geoRawProjection(
  (lambda, phi) => (lambda, math.log(math.tan((geoHalfPi + phi) / 2))),
  invert: (x, y) => (x, 2 * math.atan(math.exp(y)) - geoHalfPi),
);

/// `projection/mercator.js:18` `mercatorProjection`: a [GeoProjection] that
/// automatically intersects its clip extent with the world square `[±π·scale]`.
class GeoMercatorProjection(super.project) extends GeoProjection {
  /// Creates a [GeoMercatorProjection] for `project`.
  this {
    reclip();
  }

  final bool _isMercatorRaw = identical(project, geoMercatorRaw);
  double? _userX0;
  double _userY0 = 0;
  double _userX1 = 0;
  double _userY1 = 0;

  @override
  set scale(double value) {
    super.scale = value;
    reclip();
  }

  @override
  set translate(GeoPosition value) {
    super.translate = value;
    reclip();
  }

  @override
  set center(GeoPosition value) {
    super.center = value;
    reclip();
  }

  @override
  GeoExtent? get clipExtent =>
      _userX0 == null ? null : ((_userX0!, _userY0), (_userX1, _userY1));

  @override
  set clipExtent(GeoExtent? value) {
    if (value == null) {
      _userX0 = null;
    } else {
      _userX0 = value.$1.$1;
      _userY0 = value.$1.$2;
      _userX1 = value.$2.$1;
      _userY1 = value.$2.$2;
    }
    reclip();
  }

  /// Recomputes the automatic world-square clip extent intersected with any
  /// user-specified [clipExtent].
  void reclip() {
    final k = geoPi * scale;
    final r = rotate;
    final t = this(geoRotation(r.$1, r.$2, r.$3).invert(const (0, 0)))!;
    super.clipExtent = _userX0 == null
        ? ((t.$1 - k, t.$2 - k), (t.$1 + k, t.$2 + k))
        : _isMercatorRaw
        ? (
            (math.max(t.$1 - k, _userX0!), _userY0),
            (math.min(t.$1 + k, _userX1), _userY1),
          )
        : (
            (_userX0!, math.max(t.$2 - k, _userY0)),
            (_userX1, math.min(t.$2 + k, _userY1)),
          );
  }
}

/// `projection/mercator.js:18` `mercatorProjection(project)`.
GeoMercatorProjection geoMercatorProjection(GeoRawProjection project) =>
    GeoMercatorProjection(project);

/// `projection/mercator.js:13` `geoMercator()`: spherical Mercator projection.
GeoMercatorProjection geoMercator() =>
    geoMercatorProjection(geoMercatorRaw)..scale = 961 / geoTau;
