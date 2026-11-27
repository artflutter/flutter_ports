// Ported from d3-geo v3.1.1 src/compose.js (ISC, Mike Bostock).

/// Port of `src/compose.js` of d3-geo 3.1.1: [GeoRawProjection],
/// [GeoRawProjectionFn], [geoRawProjection], and [geoCompose].
library;

import 'package:flutter_d3_geo_port/src/geojson.dart';

/// A raw spherical-to-planar or spherical-to-spherical coordinate transform
/// operating in radians (D3 ADR 0024).
// DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoRawProjection interface
// replaces JS functions with optional `.invert` expando property.
abstract interface class GeoRawProjection() {
  /// Projects `(x, y)` forward.
  GeoPosition call(double x, double y);

  /// Whether this raw projection supports [invert].
  bool get canInvert;

  /// Projects `(x, y)` inversely, or returns `null` when unsupported or
  /// undefined.
  GeoPosition? invert(double x, double y);
}

/// A function-backed [GeoRawProjection].
final class GeoRawProjectionFn(
  final GeoPosition Function(double x, double y) _forward, [
  final GeoPosition? Function(double x, double y)? _invert,
]) implements GeoRawProjection {
  /// Creates a [GeoRawProjectionFn] from [_forward] and optional [_invert].
  this;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition call(double x, double y) => _forward(x, y);

  @override
  bool get canInvert => _invert != null;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition? invert(double x, double y) => _invert?.call(x, y);
}

/// Creates a [GeoRawProjection] from [forward] and optional [invert] functions.
GeoRawProjection geoRawProjection(
  GeoPosition Function(double x, double y) forward, {
  GeoPosition? Function(double x, double y)? invert,
}) => GeoRawProjectionFn(forward, invert);

/// `compose.js:1` default export: composes two raw projections `b(a(x, y))`
/// and their inverses `a.invert(b.invert(x, y))` when both are invertible.
GeoRawProjection geoCompose(GeoRawProjection a, GeoRawProjection b) =>
    _ComposedRawProjection(a, b);

final class _ComposedRawProjection(
  final GeoRawProjection _a,
  final GeoRawProjection _b,
) implements GeoRawProjection {
  @override
  @pragma('vm:prefer-inline')
  GeoPosition call(double x, double y) {
    final p = _a(x, y);
    return _b(p.$1, p.$2);
  }

  @override
  bool get canInvert => _a.canInvert && _b.canInvert;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition? invert(double x, double y) {
    if (!_a.canInvert || !_b.canInvert) return null;
    final p = _b.invert(x, y);
    if (p == null) return null;
    return _a.invert(p.$1, p.$2);
  }
}
