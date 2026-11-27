// Ported from d3-geo v3.1.1 src/circle.js (ISC, Mike Bostock).

/// Port of `src/circle.js` of d3-geo 3.1.1: [geoCircleStream],
/// [GeoCircleGenerator], [geoCircle], and [geoCircleBy].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/cartesian.dart';
import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/rotation.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

/// `circle.js:7` `circleStream(stream, radius, delta, direction, t0, t1)`:
/// generates a circle centered at `[0°, 0°]` in radians with [radius] and
/// angular step [delta].
void geoCircleStream(
  GeoStream stream,
  double radius,
  double delta,
  double direction, [
  GeoPosition? t0Point,
  GeoPosition? t1Point,
]) {
  if (delta == 0) return;
  final cosRadius = math.cos(radius);
  final sinRadius = math.sin(radius);
  final step = direction * delta;
  double t0;
  double t1;
  if (t0Point == null) {
    t0 = radius + direction * geoTau;
    t1 = radius - step / 2;
  } else {
    t0 = _circleRadius(cosRadius, t0Point);
    t1 = _circleRadius(cosRadius, t1Point!);
    if (direction > 0 ? t0 < t1 : t0 > t1) t0 += direction * geoTau;
  }
  for (var t = t0; direction > 0 ? t > t1 : t < t1; t -= step) {
    final point = geoSpherical((
      cosRadius,
      -sinRadius * math.cos(t),
      -sinRadius * math.sin(t),
    ));
    stream.point(point.$1, point.$2);
  }
}

double _circleRadius(double cosRadius, GeoPosition point) {
  final c = geoCartesian(point);
  final n = geoCartesianNormalize((c.$1 - cosRadius, c.$2, c.$3));
  final radius = geoAcos(-n.$2);
  return ((-n.$3 < 0 ? -radius : radius) + geoTau - geoEpsilon).remainder(
    geoTau,
  );
}

final class _CircleRingStream(
  final List<GeoPosition> _ring,
  final GeoRawProjection _rotate,
) extends GeoStream {
  @override
  void point(double x, double y, [double? z]) {
    final p = _rotate.invert(x, y)!;
    _ring.add((p.$1 * geoDegrees, p.$2 * geoDegrees));
  }
}

/// Typed spherical circle polygon generator (`circle.js:34`, D3 ADR 0024).
// DIVERGES(d3-geo): adapt-geo-typed-api, typed generic GeoCircleGenerator<T>
// with constant properties and optional datum accessors replaces JS variadic
// `arguments` forwarding.
final class GeoCircleGenerator<T>({
  GeoPosition center = (0, 0),
  double radius = 90,
  double precision = 2,

  /// Optional datum-driven circle center accessor.
  var GeoPosition Function(T datum)? centerAccessor,

  /// Optional datum-driven radius accessor (degrees).
  var double Function(T datum)? radiusAccessor,

  /// Optional datum-driven precision accessor (degrees).
  var double Function(T datum)? precisionAccessor,
}) {
  /// Creates a [GeoCircleGenerator] with optional initial parameters.
  this;

  GeoPosition _center = center;
  double _radius = radius;
  double _precision = precision;

  /// Constant circle center `(lon, lat)` in degrees.
  GeoPosition get center => _center;

  /// Sets a constant circle [center] and clears [centerAccessor].
  set center(GeoPosition value) {
    _center = value;
    centerAccessor = null;
  }

  /// Constant circle radius in degrees (default `90`).
  double get radius => _radius;

  /// Sets a constant [radius] in degrees and clears [radiusAccessor].
  set radius(double value) {
    _radius = value;
    radiusAccessor = null;
  }

  /// Constant circle angular precision in degrees (default `2`).
  double get precision => _precision;

  /// Sets a constant [precision] in degrees and clears [precisionAccessor].
  set precision(double value) {
    _precision = value;
    precisionAccessor = null;
  }

  /// Generates a spherical circle [GeoPolygon].
  ///
  /// When any `*Accessor` is configured, [datum] is passed to it.
  GeoPolygon call([T? datum]) {
    final c = centerAccessor != null ? centerAccessor!(datum as T) : _center;
    final r =
        (radiusAccessor != null ? radiusAccessor!(datum as T) : _radius) *
        geoRadians;
    final p =
        (precisionAccessor != null
            ? precisionAccessor!(datum as T)
            : _precision) *
        geoRadians;
    final ring = <GeoPosition>[];
    final rotate = geoRotateRadians(-c.$1 * geoRadians, -c.$2 * geoRadians, 0);
    geoCircleStream(_CircleRingStream(ring, rotate), r, p, 1);
    return GeoPolygon(<List<GeoPosition>>[ring]);
  }
}

/// `circle.js:34` `geoCircle()`: creates a [GeoCircleGenerator] with default
/// center `(0, 0)`, radius `90°`, and precision `2°`.
GeoCircleGenerator<void> geoCircle({
  GeoPosition center = (0, 0),
  double radius = 90,
  double precision = 2,
}) => GeoCircleGenerator<void>(
  center: center,
  radius: radius,
  precision: precision,
);

/// Creates a datum-driven [GeoCircleGenerator<T>] with typed accessors.
GeoCircleGenerator<T> geoCircleBy<T>({
  GeoPosition center = (0, 0),
  double radius = 90,
  double precision = 2,
  GeoPosition Function(T datum)? centerAccessor,
  double Function(T datum)? radiusAccessor,
  double Function(T datum)? precisionAccessor,
}) => GeoCircleGenerator<T>(
  center: center,
  radius: radius,
  precision: precision,
  centerAccessor: centerAccessor,
  radiusAccessor: radiusAccessor,
  precisionAccessor: precisionAccessor,
);
