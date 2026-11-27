// Ported from d3-geo v3.1.1 src/clip/circle.js (ISC, Mike Bostock).

/// Port of `src/clip/circle.js` of d3-geo 3.1.1: [geoClipCircle].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/circle.dart';
import 'package:flutter_d3_geo_port/src/clip/index.dart';
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

/// `clip/circle.js:7` `geoClipCircle(radius)`: returns a spherical small-circle
/// clipping [GeoStreamTransformer] for angular [radius] in radians.
// DIVERGES(d3-geo): adapt-geo-fast-forms, unboxes point state and Cartesian
// intersection math in _ClipCircleLine to avoid per-vertex record allocations.
GeoStreamTransformer geoClipCircle(double radius) {
  final cr = math.cos(radius);
  const delta = 2 * geoRadians;
  final smallRadius = cr > 0;
  final notHemisphere = cr.abs() > geoEpsilon;
  final codeR = smallRadius ? radius : geoPi - radius;

  void interpolate(
    GeoPosition? from,
    GeoPosition? to,
    double direction,
    GeoStream stream,
  ) {
    geoCircleStream(stream, radius, delta, direction, from, to);
  }

  bool visible(double lambda, double phi) =>
      math.cos(lambda) * math.cos(phi) > cr;

  return geoClip(
    visible,
    (stream) => _ClipCircleLine(
      stream,
      cr: cr,
      codeR: codeR,
      smallRadius: smallRadius,
      notHemisphere: notHemisphere,
    ),
    interpolate,
    smallRadius ? (0.0, -radius) : (-geoPi, radius - geoPi),
  );
}

final class _ClipCircleLine(
  final GeoStream _stream, {
  required final double cr,
  required final double codeR,
  required final bool smallRadius,
  required final bool notHemisphere,
}) extends GeoClipLineStream {
  bool _hasPoint0 = false;
  double _x0 = 0;
  double _y0 = 0;
  int _c0 = 0;
  bool _v0 = false;
  bool _v00 = false;
  int _clean = 1;

  // Scratch outputs for unboxed intersection calculations.
  double _ix0 = 0;
  double _iy0 = 0;
  double _ix1 = 0;
  double _iy1 = 0;

  @pragma('vm:prefer-inline')
  bool _visible(double lambda, double phi) =>
      math.cos(lambda) * math.cos(phi) > cr;

  @pragma('vm:prefer-inline')
  int _code(double lambda, double phi) {
    var c = 0;
    if (lambda < -codeR) {
      c |= 1;
    } else if (lambda > codeR) {
      c |= 2;
    }
    if (phi < -codeR) {
      c |= 4;
    } else if (phi > codeR) {
      c |= 8;
    }
    return c;
  }

  bool _intersectOne(double ax, double ay, double bx, double by) {
    final cpa = math.cos(ay);
    final paz = math.sin(ay);
    final pax = cpa * math.cos(ax);
    final pay = cpa * math.sin(ax);
    final cpb = math.cos(by);
    final pbz = math.sin(by);
    final pbx = cpb * math.cos(bx);
    final pby = cpb * math.sin(bx);

    // n2 = pa x pb, n1 = (1, 0, 0)
    final n2x = pay * pbz - paz * pby;
    final n2y = paz * pbx - pax * pbz;
    final n2z = pax * pby - pay * pbx;
    final n2n2 = n2x * n2x + n2y * n2y + n2z * n2z;
    final determinant = n2n2 - n2x * n2x;
    if (determinant == 0) {
      _ix0 = ax;
      _iy0 = ay;
      return true;
    }

    final c1 = cr * n2n2 / determinant;
    final c2 = -cr * n2x / determinant;
    // u = n1 x n2 = (0, -n2z, n2y)
    final uy = -n2z;
    final uz = n2y;
    // aVec = c1 * n1 + c2 * n2 = (c1 + c2*n2x, c2*n2y, c2*n2z)
    final avx = c1 + c2 * n2x;
    final avy = c2 * n2y;
    final avz = c2 * n2z;
    final w = avy * uy + avz * uz;
    final uu = uy * uy + uz * uz;
    final t2 = w * w - uu * (avx * avx + avy * avy + avz * avz - 1);
    if (t2 < 0) return false;

    final t = math.sqrt(t2);
    final s = (-w - t) / uu;
    final qx = avx;
    final qy = s * uy + avy;
    final qz = s * uz + avz;
    _ix0 = math.atan2(qy, qx);
    _iy0 = geoAsin(qz);
    return true;
  }

  bool _intersectTwo(double ax, double ay, double bx, double by) {
    final cpa = math.cos(ay);
    final paz = math.sin(ay);
    final pax = cpa * math.cos(ax);
    final pay = cpa * math.sin(ax);
    final cpb = math.cos(by);
    final pbz = math.sin(by);
    final pbx = cpb * math.cos(bx);
    final pby = cpb * math.sin(bx);

    final n2x = pay * pbz - paz * pby;
    final n2y = paz * pbx - pax * pbz;
    final n2z = pax * pby - pay * pbx;
    final n2n2 = n2x * n2x + n2y * n2y + n2z * n2z;
    final determinant = n2n2 - n2x * n2x;
    if (determinant == 0) return false;

    final c1 = cr * n2n2 / determinant;
    final c2 = -cr * n2x / determinant;
    final uy = -n2z;
    final uz = n2y;
    final avx = c1 + c2 * n2x;
    final avy = c2 * n2y;
    final avz = c2 * n2z;
    final w = avy * uy + avz * uz;
    final uu = uy * uy + uz * uz;
    final t2 = w * w - uu * (avx * avx + avy * avy + avz * avz - 1);
    if (t2 < 0) return false;

    final t = math.sqrt(t2);
    final s0 = (-w - t) / uu;
    final qlon = math.atan2(s0 * uy + avy, avx);
    final qlat = geoAsin(s0 * uz + avz);

    var lambda0 = ax;
    var lambda1 = bx;
    var phi0 = ay;
    var phi1 = by;
    if (lambda1 < lambda0) {
      final z = lambda0;
      lambda0 = lambda1;
      lambda1 = z;
    }

    final d = lambda1 - lambda0;
    final polar = (d - geoPi).abs() < geoEpsilon;
    final meridian = polar || d < geoEpsilon;

    if (!polar && phi1 < phi0) {
      final z = phi0;
      phi0 = phi1;
      phi1 = z;
    }

    final between = meridian
        ? (polar
              ? (phi0 + phi1 > 0) !=
                    (qlat < ((qlon - lambda0).abs() < geoEpsilon ? phi0 : phi1))
              : phi0 <= qlat && qlat <= phi1)
        : (d > geoPi) != (lambda0 <= qlon && qlon <= lambda1);

    if (between) {
      final s1 = (-w + t) / uu;
      _ix0 = qlon;
      _iy0 = qlat;
      _ix1 = math.atan2(s1 * uy + avy, avx);
      _iy1 = geoAsin(s1 * uz + avz);
      return true;
    }
    return false;
  }

  @override
  void lineStart() {
    _v00 = _v0 = false;
    _clean = 1;
  }

  @override
  void point(double x, double y, [double? z]) {
    final v = _visible(x, y);
    final c = smallRadius
        ? (v ? 0 : _code(x, y))
        : (v ? _code(x + (x < 0 ? geoPi : -geoPi), y) : 0);

    if (!_hasPoint0) {
      _v00 = _v0 = v;
      if (v) _stream.lineStart();
    }

    if (v != _v0) {
      _clean = 0;
      if (v) {
        _stream.lineStart();
        _intersectOne(x, y, _x0, _y0);
        _stream.point(_ix0, _iy0);
      } else {
        _intersectOne(_x0, _y0, x, y);
        _stream
          ..point(_ix0, _iy0, 2)
          ..lineEnd();
      }
      _x0 = _ix0;
      _y0 = _iy0;
      _hasPoint0 = true;
    } else if (notHemisphere && _hasPoint0 && (smallRadius != v)) {
      if ((c & _c0) == 0 && _intersectTwo(x, y, _x0, _y0)) {
        _clean = 0;
        if (smallRadius) {
          _stream
            ..lineStart()
            ..point(_ix0, _iy0)
            ..point(_ix1, _iy1)
            ..lineEnd();
        } else {
          _stream
            ..point(_ix1, _iy1)
            ..lineEnd()
            ..lineStart()
            ..point(_ix0, _iy0, 3);
        }
      }
    }

    if (v &&
        (!_hasPoint0 ||
            (_x0 - x).abs() >= geoEpsilon ||
            (_y0 - y).abs() >= geoEpsilon)) {
      _stream.point(x, y);
    }
    _x0 = x;
    _y0 = y;
    _hasPoint0 = true;
    _v0 = v;
    _c0 = c;
  }

  @override
  void lineEnd() {
    if (_v0) _stream.lineEnd();
    _hasPoint0 = false;
  }

  @override
  int clean() => _clean | ((_v00 && _v0) ? 2 : 0);
}
