// Ported from d3-geo v3.1.1 src/rotation.js (ISC, Mike Bostock).

/// Port of `src/rotation.js` of d3-geo 3.1.1: [GeoRotation], [geoRotation],
/// and [geoRotateRadians].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';

final class _RotationIdentity() implements GeoRawProjection {
  @override
  @pragma('vm:prefer-inline')
  GeoPosition call(double lambda, double phi) {
    var l = lambda;
    if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
    return (l, phi);
  }

  @override
  bool get canInvert => true;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition invert(double lambda, double phi) => call(lambda, phi);
}

final GeoRawProjection _rotationIdentity = _RotationIdentity();

final class _RotationLambda(final double _deltaLambda)
    implements GeoRawProjection {
  @override
  @pragma('vm:prefer-inline')
  GeoPosition call(double lambda, double phi) {
    var l = lambda + _deltaLambda;
    if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
    return (l, phi);
  }

  @override
  bool get canInvert => true;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition invert(double lambda, double phi) {
    var l = lambda - _deltaLambda;
    if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
    return (l, phi);
  }
}

final class _RotationPhiGamma(double deltaPhi, double deltaGamma)
    implements GeoRawProjection {
  final double _cosDeltaPhi = math.cos(deltaPhi);
  final double _sinDeltaPhi = math.sin(deltaPhi);
  final double _cosDeltaGamma = math.cos(deltaGamma);
  final double _sinDeltaGamma = math.sin(deltaGamma);

  @override
  @pragma('vm:prefer-inline')
  GeoPosition call(double lambda, double phi) {
    final cosPhi = math.cos(phi);
    final x = math.cos(lambda) * cosPhi;
    final y = math.sin(lambda) * cosPhi;
    final z = math.sin(phi);
    final k = z * _cosDeltaPhi + x * _sinDeltaPhi;
    return (
      math.atan2(
        y * _cosDeltaGamma - k * _sinDeltaGamma,
        x * _cosDeltaPhi - z * _sinDeltaPhi,
      ),
      geoAsin(k * _cosDeltaGamma + y * _sinDeltaGamma),
    );
  }

  @override
  bool get canInvert => true;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition invert(double lambda, double phi) {
    final cosPhi = math.cos(phi);
    final x = math.cos(lambda) * cosPhi;
    final y = math.sin(lambda) * cosPhi;
    final z = math.sin(phi);
    final k = z * _cosDeltaGamma - y * _sinDeltaGamma;
    return (
      math.atan2(
        y * _cosDeltaGamma + z * _sinDeltaGamma,
        x * _cosDeltaPhi + k * _sinDeltaPhi,
      ),
      geoAsin(k * _cosDeltaPhi - x * _sinDeltaPhi),
    );
  }
}

// DIVERGES(d3-geo): adapt-geo-fast-forms, fuses lambda + phi/gamma rotation
// into one unboxed class to avoid intermediate geoCompose record allocation.
final class _RotationLambdaPhiGamma(
  final double _deltaLambda,
  double deltaPhi,
  double deltaGamma,
) implements GeoRawProjection {
  final double _cosDeltaPhi = math.cos(deltaPhi);
  final double _sinDeltaPhi = math.sin(deltaPhi);
  final double _cosDeltaGamma = math.cos(deltaGamma);
  final double _sinDeltaGamma = math.sin(deltaGamma);

  @override
  @pragma('vm:prefer-inline')
  GeoPosition call(double lambda, double phi) {
    var l = lambda + _deltaLambda;
    if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
    final cosPhi = math.cos(phi);
    final x = math.cos(l) * cosPhi;
    final y = math.sin(l) * cosPhi;
    final z = math.sin(phi);
    final k = z * _cosDeltaPhi + x * _sinDeltaPhi;
    return (
      math.atan2(
        y * _cosDeltaGamma - k * _sinDeltaGamma,
        x * _cosDeltaPhi - z * _sinDeltaPhi,
      ),
      geoAsin(k * _cosDeltaGamma + y * _sinDeltaGamma),
    );
  }

  @override
  bool get canInvert => true;

  @override
  @pragma('vm:prefer-inline')
  GeoPosition invert(double lambda, double phi) {
    final cosPhi = math.cos(phi);
    final x = math.cos(lambda) * cosPhi;
    final y = math.sin(lambda) * cosPhi;
    final z = math.sin(phi);
    final k = z * _cosDeltaGamma - y * _sinDeltaGamma;
    var l =
        math.atan2(
          y * _cosDeltaGamma + z * _sinDeltaGamma,
          x * _cosDeltaPhi + k * _sinDeltaPhi,
        ) -
        _deltaLambda;
    if (l.abs() > geoPi) l -= geoJsRound(l / geoTau) * geoTau;
    return (l, geoAsin(k * _cosDeltaPhi - x * _sinDeltaPhi));
  }
}

/// `rotation.js:11` `rotateRadians(deltaLambda, deltaPhi, deltaGamma)`:
/// returns a radian-space spherical rotation [GeoRawProjection].
GeoRawProjection geoRotateRadians(
  double deltaLambda,
  double deltaPhi,
  double deltaGamma,
) {
  final dl = deltaLambda.remainder(geoTau);
  if (dl != 0) {
    if (deltaPhi != 0 || deltaGamma != 0) {
      return _RotationLambdaPhiGamma(dl, deltaPhi, deltaGamma);
    }
    return _RotationLambda(dl);
  }
  if (deltaPhi != 0 || deltaGamma != 0) {
    return _RotationPhiGamma(deltaPhi, deltaGamma);
  }
  return _rotationIdentity;
}

/// A typed spherical rotation operating on degree coordinates `(lon, lat)`
/// (D3 ADR 0024).
// DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoRotation class replaces JS
// function with `.invert` expando property.
final class GeoRotation(
  double deltaLambda,
  double deltaPhi, [
  double deltaGamma = 0,
]) {
  /// Creates a [GeoRotation] for angles `[lambda, phi, gamma]` in degrees.
  this;

  final GeoRawProjection _rotate = geoRotateRadians(
    deltaLambda * geoRadians,
    deltaPhi * geoRadians,
    deltaGamma * geoRadians,
  );

  /// Rotates [coordinates] `(lon, lat)` in degrees forward.
  GeoPosition call(GeoPosition coordinates) {
    final r = _rotate(coordinates.$1 * geoRadians, coordinates.$2 * geoRadians);
    return (r.$1 * geoDegrees, r.$2 * geoDegrees);
  }

  /// Rotates [coordinates] `(lon, lat)` in degrees inversely.
  GeoPosition invert(GeoPosition coordinates) {
    final r = _rotate.invert(
      coordinates.$1 * geoRadians,
      coordinates.$2 * geoRadians,
    )!;
    return (r.$1 * geoDegrees, r.$2 * geoDegrees);
  }
}

/// `rotation.js:65` `geoRotation([lambda, phi, gamma])`: creates a
/// [GeoRotation] for the specified Euler angles in degrees.
GeoRotation geoRotation(
  double deltaLambda,
  double deltaPhi, [
  double deltaGamma = 0,
]) => GeoRotation(deltaLambda, deltaPhi, deltaGamma);
