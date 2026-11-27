// Ported from d3-geo v3.1.1 src/projection/identity.js (ISC, Mike Bostock).

/// Port of `src/projection/identity.js` of d3-geo 3.1.1:
/// [GeoIdentityProjection] and [geoIdentity].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/clip/rectangle.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/fit.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';
import 'package:flutter_d3_geo_port/src/transform.dart';

/// `projection/identity.js:7` `geoIdentity`: planar affine identity transform
/// supporting scale, translate, angle, reflectX, reflectY, clipExtent, and
/// fit helpers.
final class GeoIdentityProjection() implements GeoProjector {
  /// Creates a [GeoIdentityProjection].
  this;

  double _k = 1;
  double _tx = 0;
  double _ty = 0;
  double _sx = 1;
  double _sy = 1;
  double _alpha = 0;
  double _ca = 1;
  double _sa = 0;
  double? _x0;
  double _y0 = 0;
  double _x1 = 0;
  double _y1 = 0;
  double _kx = 1;
  double _ky = 1;
  GeoStreamTransformer _postclip = geoStreamIdentity;
  GeoStream? _cache;
  GeoStream? _cacheStream;

  void _reset() {
    _kx = _k * _sx;
    _ky = _k * _sy;
    _cache = null;
    _cacheStream = null;
  }

  @override
  GeoPosition call(GeoPosition p) {
    var x = p.$1 * _kx;
    var y = p.$2 * _ky;
    if (_alpha != 0) {
      final t = y * _ca - x * _sa;
      x = x * _ca + y * _sa;
      y = t;
    }
    return (x + _tx, y + _ty);
  }

  @override
  bool get canInvert => true;

  @override
  GeoPosition invert(GeoPosition p) {
    var x = p.$1 - _tx;
    var y = p.$2 - _ty;
    if (_alpha != 0) {
      final t = y * _ca + x * _sa;
      x = x * _ca - y * _sa;
      y = t;
    }
    return (x / _kx, y / _ky);
  }

  @override
  GeoStream stream(GeoStream sink) {
    if (_cache != null && identical(_cacheStream, sink)) return _cache!;
    _cacheStream = sink;
    return _cache = _IdentityTransformStream(_postclip(sink), this);
  }

  /// Current planar post-clipping transformer.
  GeoStreamTransformer get postclip => _postclip;

  /// Sets a custom planar post-clipping transformer (clears [clipExtent]).
  set postclip(GeoStreamTransformer value) {
    _postclip = value;
    _x0 = null;
    _reset();
  }

  @override
  bool get hasClipExtent => true;

  @override
  GeoExtent? get clipExtent => _x0 == null ? null : ((_x0!, _y0), (_x1, _y1));

  @override
  set clipExtent(GeoExtent? value) {
    if (value == null) {
      _x0 = null;
      _postclip = geoStreamIdentity;
    } else {
      _x0 = value.$1.$1;
      _y0 = value.$1.$2;
      _x1 = value.$2.$1;
      _y1 = value.$2.$2;
      _postclip = geoClipRectangle(_x0!, _y0, _x1, _y1);
    }
    _reset();
  }

  @override
  double get scale => _k;

  @override
  set scale(double value) {
    _k = value;
    _reset();
  }

  @override
  GeoPosition get translate => (_tx, _ty);

  @override
  set translate(GeoPosition value) {
    _tx = value.$1;
    _ty = value.$2;
    _reset();
  }

  /// Planar rotation angle in degrees.
  double get angle => _alpha * geoDegrees;

  /// Sets the planar rotation angle in degrees.
  set angle(double degrees) {
    _alpha = degrees.remainder(360) * geoRadians;
    _sa = math.sin(_alpha);
    _ca = math.cos(_alpha);
    _reset();
  }

  /// Whether the x-axis is reflected.
  bool get reflectX => _sx < 0;

  /// Sets whether the x-axis is reflected.
  set reflectX(bool value) {
    _sx = value ? -1 : 1;
    _reset();
  }

  /// Whether the y-axis is reflected.
  bool get reflectY => _sy < 0;

  /// Sets whether the y-axis is reflected.
  set reflectY(bool value) {
    _sy = value ? -1 : 1;
    _reset();
  }

  @override
  void fitExtent(GeoExtent extent, GeoJsonObject object) =>
      geoFitExtent(this, extent, object);

  @override
  void fitSize(GeoPosition size, GeoJsonObject object) =>
      geoFitSize(this, size, object);

  @override
  void fitWidth(double width, GeoJsonObject object) =>
      geoFitWidth(this, width, object);

  @override
  void fitHeight(double height, GeoJsonObject object) =>
      geoFitHeight(this, height, object);
}

final class _IdentityTransformStream(
  super.stream,
  final GeoIdentityProjection _projection,
) extends GeoTransformStream {
  @override
  void point(double x, double y, [double? z]) {
    final p = _projection((x, y));
    stream.point(p.$1, p.$2);
  }
}

/// `projection/identity.js:7` `geoIdentity()`: creates a new
/// [GeoIdentityProjection].
GeoIdentityProjection geoIdentity() => GeoIdentityProjection();
