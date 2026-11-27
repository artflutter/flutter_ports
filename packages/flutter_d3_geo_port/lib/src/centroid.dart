// Ported from d3-geo v3.1.1 src/centroid.js (ISC, Mike Bostock).

/// Port of `src/centroid.js` of d3-geo 3.1.1: [geoCentroid].
library;

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart' show Adder;
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

final class _CentroidStream() extends GeoStream {
  double _w0 = 0;
  double _w1 = 0;
  double _x0Sum = 0;
  double _y0Sum = 0;
  double _z0Sum = 0;
  double _x1Sum = 0;
  double _y1Sum = 0;
  double _z1Sum = 0;
  final Adder _x2 = Adder();
  final Adder _y2 = Adder();
  final Adder _z2 = Adder();

  double _lambda00 = 0;
  double _phi00 = 0;
  double _x0 = 0;
  double _y0 = 0;
  double _z0 = 0;

  // 0 = point, 1 = lineFirst, 2 = line, 3 = ringFirst, 4 = ring
  int _pointMode = 0;
  bool _inPolygon = false;

  @override
  void point(double x, double y, [double? z]) {
    switch (_pointMode) {
      case 0:
        _centroidPoint(x, y);
      case 1:
        _centroidLinePointFirst(x, y);
      case 2:
        _centroidLinePoint(x, y);
      case 3:
        _centroidRingPointFirst(x, y);
      case 4:
        _centroidRingPoint(x, y);
    }
  }

  @override
  void lineStart() {
    _pointMode = _inPolygon ? 3 : 1;
  }

  @override
  void lineEnd() {
    if (_inPolygon) {
      _centroidRingPoint(_lambda00, _phi00);
    }
    _pointMode = 0;
  }

  @override
  void polygonStart() {
    _inPolygon = true;
  }

  @override
  void polygonEnd() {
    _inPolygon = false;
  }

  void _centroidPoint(double lambda, double phi) {
    final l = lambda * geoRadians;
    final p = phi * geoRadians;
    final cosPhi = math.cos(p);
    _centroidPointCartesian(
      cosPhi * math.cos(l),
      cosPhi * math.sin(l),
      math.sin(p),
    );
  }

  @pragma('vm:prefer-inline')
  void _centroidPointCartesian(double x, double y, double z) {
    ++_w0;
    _x0Sum += (x - _x0Sum) / _w0;
    _y0Sum += (y - _y0Sum) / _w0;
    _z0Sum += (z - _z0Sum) / _w0;
  }

  void _centroidLinePointFirst(double lambda, double phi) {
    final l = lambda * geoRadians;
    final p = phi * geoRadians;
    final cosPhi = math.cos(p);
    _x0 = cosPhi * math.cos(l);
    _y0 = cosPhi * math.sin(l);
    _z0 = math.sin(p);
    _pointMode = 2;
    _centroidPointCartesian(_x0, _y0, _z0);
  }

  void _centroidLinePoint(double lambda, double phi) {
    final l = lambda * geoRadians;
    final p = phi * geoRadians;
    final cosPhi = math.cos(p);
    final x = cosPhi * math.cos(l);
    final y = cosPhi * math.sin(l);
    final z = math.sin(p);
    final cx = _y0 * z - _z0 * y;
    final cy = _z0 * x - _x0 * z;
    final cz = _x0 * y - _y0 * x;
    final w = math.atan2(
      math.sqrt(cx * cx + cy * cy + cz * cz),
      _x0 * x + _y0 * y + _z0 * z,
    );
    _w1 += w;
    _x1Sum += w * (_x0 + x);
    _y1Sum += w * (_y0 + y);
    _z1Sum += w * (_z0 + z);
    _x0 = x;
    _y0 = y;
    _z0 = z;
    _centroidPointCartesian(x, y, z);
  }

  void _centroidRingPointFirst(double lambda, double phi) {
    _lambda00 = lambda;
    _phi00 = phi;
    final l = lambda * geoRadians;
    final p = phi * geoRadians;
    _pointMode = 4;
    final cosPhi = math.cos(p);
    _x0 = cosPhi * math.cos(l);
    _y0 = cosPhi * math.sin(l);
    _z0 = math.sin(p);
    _centroidPointCartesian(_x0, _y0, _z0);
  }

  void _centroidRingPoint(double lambda, double phi) {
    final l = lambda * geoRadians;
    final p = phi * geoRadians;
    final cosPhi = math.cos(p);
    final x = cosPhi * math.cos(l);
    final y = cosPhi * math.sin(l);
    final z = math.sin(p);
    final cx = _y0 * z - _z0 * y;
    final cy = _z0 * x - _x0 * z;
    final cz = _x0 * y - _y0 * x;
    final m = geoHypot3(cx, cy, cz);
    final w = geoAsin(m);
    final v = m != 0 ? -w / m : 0.0;
    _x2.add(v * cx);
    _y2.add(v * cy);
    _z2.add(v * cz);
    _w1 += w;
    _x1Sum += w * (_x0 + x);
    _y1Sum += w * (_y0 + y);
    _z1Sum += w * (_z0 + z);
    _x0 = x;
    _y0 = y;
    _z0 = z;
    _centroidPointCartesian(x, y, z);
  }

  GeoPosition finish() {
    var x = _x2.valueOf();
    var y = _y2.valueOf();
    var z = _z2.valueOf();
    var m = geoHypot3(x, y, z);

    if (m < geoEpsilon2) {
      x = _x1Sum;
      y = _y1Sum;
      z = _z1Sum;
      if (_w1 < geoEpsilon) {
        x = _x0Sum;
        y = _y0Sum;
        z = _z0Sum;
      }
      m = geoHypot3(x, y, z);
      if (m < geoEpsilon2) return (double.nan, double.nan);
    }

    return (math.atan2(y, x) * geoDegrees, geoAsin(z / m) * geoDegrees);
  }
}

/// `centroid.js:118` `geoCentroid(object)`: returns the spherical centroid
/// `(lon, lat)` in degrees of the specified GeoJSON [object].
// DIVERGES(d3-geo): adapt-geo-typed-api, returns typed GeoPosition record.
GeoPosition geoCentroid(GeoJsonObject? object) {
  final stream = _CentroidStream();
  geoStream(object, stream);
  return stream.finish();
}
