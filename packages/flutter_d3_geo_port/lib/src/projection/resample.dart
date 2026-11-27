// Ported from d3-geo v3.1.1 src/projection/resample.js (ISC, Mike Bostock).

/// Port of `src/projection/resample.js` of d3-geo 3.1.1: adaptive great-circle
/// resampling [geoResample] and fused affine resampler [geoResampleAffine].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/compose.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/projection/conicEqualArea.dart';
import 'package:flutter_d3_geo_port/src/projection/equalEarth.dart';
import 'package:flutter_d3_geo_port/src/projection/mercator.dart';
import 'package:flutter_d3_geo_port/src/projection/naturalEarth1.dart';
import 'package:flutter_d3_geo_port/src/projection/orthographic.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';
import 'package:flutter_d3_geo_port/src/transform.dart';

const int _maxDepth = 16;
final double _cosMinDistance = math.cos(30 * geoRadians);

// Equal Earth polynomial constants (matching equalEarth.dart).
const double _eeA1 = 1.340264;
const double _eeA2 = -0.081106;
const double _eeA3 = 0.000893;
const double _eeA4 = 0.003796;
final double _eeM = math.sqrt(3) / 2;

const int _rawGeneric = 0;
const int _rawOrthographic = 1;
const int _rawMercator = 2;
const int _rawEqualEarth = 3;
const int _rawNaturalEarth1 = 4;
const int _rawConicEqualArea = 5;

int _classifyRaw(GeoRawProjection raw) {
  if (identical(raw, geoOrthographicRaw)) return _rawOrthographic;
  if (identical(raw, geoMercatorRaw)) return _rawMercator;
  if (identical(raw, geoEqualEarthRaw)) return _rawEqualEarth;
  if (identical(raw, geoNaturalEarth1Raw)) return _rawNaturalEarth1;
  if (raw is GeoConicEqualAreaRaw) return _rawConicEqualArea;
  return _rawGeneric;
}

/// `projection/resample.js:8` default export: returns a [GeoStreamTransformer]
/// that projects coordinates through [project] with adaptive subdivision when
/// [delta2] > 0.
GeoStreamTransformer geoResample(GeoRawProjection project, double delta2) =>
    delta2 != 0 && !delta2.isNaN
    ? (sink) => _ResampleStream(sink, project, delta2)
    : (sink) => _ResampleNoneStream(sink, project);

/// Fused raw-projection + affine-transform adaptive resampler avoiding
/// intermediate `(double, double)` record allocations on built-in projections.
// DIVERGES(d3-geo): adapt-geo-fast-forms, fuses raw projection + affine
// scale/translate/rotate into the resampler stream with unboxed double math.
GeoStreamTransformer geoResampleAffine(
  GeoRawProjection raw,
  double k,
  double dx,
  double dy,
  double sx,
  double sy,
  double alpha,
  double delta2,
) {
  final kind = _classifyRaw(raw);
  final conic = kind == _rawConicEqualArea ? raw as GeoConicEqualAreaRaw : null;
  final hasAlpha = alpha != 0;
  final double a;
  final double b;
  if (hasAlpha) {
    a = math.cos(alpha) * k;
    b = math.sin(alpha) * k;
  } else {
    a = k * sx;
    b = k * sy;
  }
  return delta2 != 0 && !delta2.isNaN
      ? (sink) => _AffineResampleStream(
          sink,
          raw,
          kind,
          conic,
          dx,
          dy,
          sx,
          sy,
          hasAlpha,
          a,
          b,
          delta2,
        )
      : (sink) => _AffineResampleNoneStream(
          sink,
          raw,
          kind,
          conic,
          dx,
          dy,
          sx,
          sy,
          hasAlpha,
          a,
          b,
        );
}

final class _ResampleNoneStream(super.stream, final GeoRawProjection _project)
    extends GeoTransformStream {
  @override
  void point(double x, double y, [double? z]) {
    final p = _project(x, y);
    stream.point(p.$1, p.$2);
  }
}

final class _ResampleStream(
  final GeoStream _stream,
  final GeoRawProjection _project,
  final double _delta2,
) extends GeoStream {
  final double _delta2x4 = 4 * _delta2;

  double _lambda00 = 0;
  double _x00 = 0;
  double _y00 = 0;
  double _a00 = 0;
  double _b00 = 0;
  double _c00 = 0;

  double _lambda0 = 0;
  double _x0 = 0;
  double _y0 = 0;
  double _a0 = 0;
  double _b0 = 0;
  double _c0 = 0;

  // 0 = point, 1 = linePoint, 2 = ringPoint
  int _pointMode = 0;
  bool _inPolygon = false;
  bool _ringEndActive = false;

  @override
  void point(double x, double y, [double? z]) {
    if (_pointMode == 1) {
      _linePoint(x, y);
    } else if (_pointMode == 2) {
      _ringPoint(x, y);
    } else {
      final p = _project(x, y);
      _stream.point(p.$1, p.$2);
    }
  }

  @override
  void lineStart() {
    if (_inPolygon) {
      _x0 = double.nan;
      _pointMode = 2;
      _ringEndActive = true;
      _stream.lineStart();
    } else {
      _x0 = double.nan;
      _pointMode = 1;
      _stream.lineStart();
    }
  }

  @override
  void lineEnd() {
    if (_ringEndActive) {
      _resampleLineTo(
        _x0,
        _y0,
        _lambda0,
        _a0,
        _b0,
        _c0,
        _x00,
        _y00,
        _lambda00,
        _a00,
        _b00,
        _c00,
        _maxDepth,
      );
      _ringEndActive = false;
    }
    _pointMode = 0;
    _stream.lineEnd();
  }

  @override
  void polygonStart() {
    _stream.polygonStart();
    _inPolygon = true;
  }

  @override
  void polygonEnd() {
    _stream.polygonEnd();
    _inPolygon = false;
  }

  void _linePoint(double lambda, double phi) {
    final cosPhi = math.cos(phi);
    final a1 = cosPhi * math.cos(lambda);
    final b1 = cosPhi * math.sin(lambda);
    final c1 = math.sin(phi);
    final p = _project(lambda, phi);
    final x1 = p.$1;
    final y1 = p.$2;
    _resampleLineTo(
      _x0,
      _y0,
      _lambda0,
      _a0,
      _b0,
      _c0,
      x1,
      y1,
      lambda,
      a1,
      b1,
      c1,
      _maxDepth,
    );
    _x0 = x1;
    _y0 = y1;
    _lambda0 = lambda;
    _a0 = a1;
    _b0 = b1;
    _c0 = c1;
    _stream.point(x1, y1);
  }

  void _ringPoint(double lambda, double phi) {
    _lambda00 = lambda;
    _linePoint(lambda, phi);
    _x00 = _x0;
    _y00 = _y0;
    _a00 = _a0;
    _b00 = _b0;
    _c00 = _c0;
    _pointMode = 1;
  }

  void _resampleLineTo(
    double x0,
    double y0,
    double lambda0,
    double a0,
    double b0,
    double c0,
    double x1,
    double y1,
    double lambda1,
    double a1,
    double b1,
    double c1,
    int depth,
  ) {
    final dx = x1 - x0;
    final dy = y1 - y0;
    final d2 = dx * dx + dy * dy;
    if (d2 > _delta2x4 && depth > 0) {
      final nextDepth = depth - 1;
      var a = a0 + a1;
      var b = b0 + b1;
      var c = c0 + c1;
      final m = math.sqrt(a * a + b * b + c * c);
      c /= m;
      final phi2 = geoAsin(c);
      final lambda2 =
          (c.abs() - 1).abs() < geoEpsilon ||
              (lambda0 - lambda1).abs() < geoEpsilon
          ? (lambda0 + lambda1) / 2
          : math.atan2(b, a);
      final p = _project(lambda2, phi2);
      final x2 = p.$1;
      final y2 = p.$2;
      final dx2 = x2 - x0;
      final dy2 = y2 - y0;
      final dz = dy * dx2 - dx * dy2;
      if (dz * dz / d2 > _delta2 ||
          ((dx * dx2 + dy * dy2) / d2 - 0.5).abs() > 0.3 ||
          a0 * a1 + b0 * b1 + c0 * c1 < _cosMinDistance) {
        a /= m;
        b /= m;
        _resampleLineTo(
          x0,
          y0,
          lambda0,
          a0,
          b0,
          c0,
          x2,
          y2,
          lambda2,
          a,
          b,
          c,
          nextDepth,
        );
        _stream.point(x2, y2);
        _resampleLineTo(
          x2,
          y2,
          lambda2,
          a,
          b,
          c,
          x1,
          y1,
          lambda1,
          a1,
          b1,
          c1,
          nextDepth,
        );
      }
    }
  }
}

final class _AffineResampleNoneStream(
  super.stream,
  final GeoRawProjection _raw,
  final int _kind,
  GeoConicEqualAreaRaw? conic,
  final double _dx,
  final double _dy,
  final double _sx,
  final double _sy,
  final bool _hasAlpha,
  final double _a,
  final double _b,
) extends GeoTransformStream {
  final double _cn = conic?.n ?? 0;
  final double _cc = conic?.c ?? 0;
  final double _cr0 = conic?.r0 ?? 0;

  @override
  void point(double x, double y, [double? z]) {
    final double rx;
    final double ry;
    switch (_kind) {
      case _rawOrthographic:
        rx = math.cos(y) * math.sin(x);
        ry = math.sin(y);
      case _rawMercator:
        rx = x;
        ry = math.log(math.tan((geoHalfPi + y) / 2));
      case _rawEqualEarth:
        final l = geoAsin(_eeM * math.sin(y));
        final l2 = l * l;
        final l6 = l2 * l2 * l2;
        rx =
            x *
            math.cos(l) /
            (_eeM *
                (_eeA1 + 3 * _eeA2 * l2 + l6 * (7 * _eeA3 + 9 * _eeA4 * l2)));
        ry = l * (_eeA1 + _eeA2 * l2 + l6 * (_eeA3 + _eeA4 * l2));
      case _rawNaturalEarth1:
        final phi2 = y * y;
        final phi4 = phi2 * phi2;
        rx =
            x *
            (0.8707 -
                0.131979 * phi2 +
                phi4 *
                    (-0.013791 + phi4 * (0.003971 * phi2 - 0.001529 * phi4)));
        ry =
            y *
            (1.007226 +
                phi2 *
                    (0.015085 +
                        phi4 *
                            (-0.044475 + 0.028874 * phi2 - 0.005916 * phi4)));
      case _rawConicEqualArea:
        final r = math.sqrt(_cc - 2 * _cn * math.sin(y)) / _cn;
        final nx = x * _cn;
        rx = r * math.sin(nx);
        ry = _cr0 - r * math.cos(nx);
      default:
        final p = _raw(x, y);
        rx = p.$1;
        ry = p.$2;
    }
    if (_hasAlpha) {
      final xs = rx * _sx;
      final ys = ry * _sy;
      stream.point(_a * xs - _b * ys + _dx, _dy - _b * xs - _a * ys);
    } else {
      stream.point(_dx + _a * rx, _dy - _b * ry);
    }
  }
}

final class _AffineResampleStream(
  final GeoStream _stream,
  final GeoRawProjection _raw,
  final int _kind,
  GeoConicEqualAreaRaw? conic,
  final double _dx,
  final double _dy,
  final double _sx,
  final double _sy,
  final bool _hasAlpha,
  final double _a,
  final double _b,
  final double _delta2,
) extends GeoStream {
  final double _delta2x4 = 4 * _delta2;
  final double _cn = conic?.n ?? 0;
  final double _cc = conic?.c ?? 0;
  final double _cr0 = conic?.r0 ?? 0;

  double _px = 0;
  double _py = 0;

  double _lambda00 = 0;
  double _x00 = 0;
  double _y00 = 0;
  double _a00 = 0;
  double _b00 = 0;
  double _c00 = 0;

  double _lambda0 = 0;
  double _x0 = 0;
  double _y0 = 0;
  double _a0 = 0;
  double _b0 = 0;
  double _c0 = 0;

  // 0 = point, 1 = linePoint, 2 = ringPoint
  int _pointMode = 0;
  bool _inPolygon = false;
  bool _ringEndActive = false;

  @pragma('vm:prefer-inline')
  void _projectInto(double lambda, double phi) {
    final double rx;
    final double ry;
    switch (_kind) {
      case _rawOrthographic:
        rx = math.cos(phi) * math.sin(lambda);
        ry = math.sin(phi);
      case _rawMercator:
        rx = lambda;
        ry = math.log(math.tan((geoHalfPi + phi) / 2));
      case _rawEqualEarth:
        final l = geoAsin(_eeM * math.sin(phi));
        final l2 = l * l;
        final l6 = l2 * l2 * l2;
        rx =
            lambda *
            math.cos(l) /
            (_eeM *
                (_eeA1 + 3 * _eeA2 * l2 + l6 * (7 * _eeA3 + 9 * _eeA4 * l2)));
        ry = l * (_eeA1 + _eeA2 * l2 + l6 * (_eeA3 + _eeA4 * l2));
      case _rawNaturalEarth1:
        final phi2 = phi * phi;
        final phi4 = phi2 * phi2;
        rx =
            lambda *
            (0.8707 -
                0.131979 * phi2 +
                phi4 *
                    (-0.013791 + phi4 * (0.003971 * phi2 - 0.001529 * phi4)));
        ry =
            phi *
            (1.007226 +
                phi2 *
                    (0.015085 +
                        phi4 *
                            (-0.044475 + 0.028874 * phi2 - 0.005916 * phi4)));
      case _rawConicEqualArea:
        final r = math.sqrt(_cc - 2 * _cn * math.sin(phi)) / _cn;
        final nx = lambda * _cn;
        rx = r * math.sin(nx);
        ry = _cr0 - r * math.cos(nx);
      default:
        final p = _raw(lambda, phi);
        rx = p.$1;
        ry = p.$2;
    }
    if (_hasAlpha) {
      final xs = rx * _sx;
      final ys = ry * _sy;
      _px = _a * xs - _b * ys + _dx;
      _py = _dy - _b * xs - _a * ys;
    } else {
      _px = _dx + _a * rx;
      _py = _dy - _b * ry;
    }
  }

  @override
  void point(double x, double y, [double? z]) {
    if (_pointMode == 1) {
      _linePoint(x, y);
    } else if (_pointMode == 2) {
      _ringPoint(x, y);
    } else {
      _projectInto(x, y);
      _stream.point(_px, _py);
    }
  }

  @override
  void lineStart() {
    if (_inPolygon) {
      _x0 = double.nan;
      _pointMode = 2;
      _ringEndActive = true;
      _stream.lineStart();
    } else {
      _x0 = double.nan;
      _pointMode = 1;
      _stream.lineStart();
    }
  }

  @override
  void lineEnd() {
    if (_ringEndActive) {
      _resampleLineTo(
        _x0,
        _y0,
        _lambda0,
        _a0,
        _b0,
        _c0,
        _x00,
        _y00,
        _lambda00,
        _a00,
        _b00,
        _c00,
        _maxDepth,
      );
      _ringEndActive = false;
    }
    _pointMode = 0;
    _stream.lineEnd();
  }

  @override
  void polygonStart() {
    _stream.polygonStart();
    _inPolygon = true;
  }

  @override
  void polygonEnd() {
    _stream.polygonEnd();
    _inPolygon = false;
  }

  void _linePoint(double lambda, double phi) {
    final cosPhi = math.cos(phi);
    final sinPhi = math.sin(phi);
    final sinLambda = math.sin(lambda);
    final cosLambda = math.cos(lambda);
    final a1 = cosPhi * cosLambda;
    final b1 = cosPhi * sinLambda;
    final c1 = sinPhi;
    final double x1;
    final double y1;
    if (_kind == _rawOrthographic && !_hasAlpha) {
      // Reuse cosPhi, sinLambda, sinPhi already computed for Cartesian coords.
      x1 = _dx + _a * (cosPhi * sinLambda);
      y1 = _dy - _b * sinPhi;
    } else {
      _projectInto(lambda, phi);
      x1 = _px;
      y1 = _py;
    }
    _resampleLineTo(
      _x0,
      _y0,
      _lambda0,
      _a0,
      _b0,
      _c0,
      x1,
      y1,
      lambda,
      a1,
      b1,
      c1,
      _maxDepth,
    );
    _x0 = x1;
    _y0 = y1;
    _lambda0 = lambda;
    _a0 = a1;
    _b0 = b1;
    _c0 = c1;
    _stream.point(x1, y1);
  }

  void _ringPoint(double lambda, double phi) {
    _lambda00 = lambda;
    _linePoint(lambda, phi);
    _x00 = _x0;
    _y00 = _y0;
    _a00 = _a0;
    _b00 = _b0;
    _c00 = _c0;
    _pointMode = 1;
  }

  void _resampleLineTo(
    double x0,
    double y0,
    double lambda0,
    double a0,
    double b0,
    double c0,
    double x1,
    double y1,
    double lambda1,
    double a1,
    double b1,
    double c1,
    int depth,
  ) {
    final dx = x1 - x0;
    final dy = y1 - y0;
    final d2 = dx * dx + dy * dy;
    if (d2 > _delta2x4 && depth > 0) {
      final nextDepth = depth - 1;
      var a = a0 + a1;
      var b = b0 + b1;
      var c = c0 + c1;
      final m = math.sqrt(a * a + b * b + c * c);
      c /= m;
      final phi2 = geoAsin(c);
      final lambda2 =
          (c.abs() - 1).abs() < geoEpsilon ||
              (lambda0 - lambda1).abs() < geoEpsilon
          ? (lambda0 + lambda1) / 2
          : math.atan2(b, a);
      _projectInto(lambda2, phi2);
      final x2 = _px;
      final y2 = _py;
      final dx2 = x2 - x0;
      final dy2 = y2 - y0;
      final dz = dy * dx2 - dx * dy2;
      if (dz * dz / d2 > _delta2 ||
          ((dx * dx2 + dy * dy2) / d2 - 0.5).abs() > 0.3 ||
          a0 * a1 + b0 * b1 + c0 * c1 < _cosMinDistance) {
        a /= m;
        b /= m;
        _resampleLineTo(
          x0,
          y0,
          lambda0,
          a0,
          b0,
          c0,
          x2,
          y2,
          lambda2,
          a,
          b,
          c,
          nextDepth,
        );
        _stream.point(x2, y2);
        _resampleLineTo(
          x2,
          y2,
          lambda2,
          a,
          b,
          c,
          x1,
          y1,
          lambda1,
          a1,
          b1,
          c1,
          nextDepth,
        );
      }
    }
  }
}
