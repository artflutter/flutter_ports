// Ported from d3-geo v3.1.1 src/path/centroid.js (ISC, Mike Bostock).

/// Port of `src/path/centroid.js` of d3-geo 3.1.1: [GeoPathCentroidStream].
library;

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

/// `path/centroid.js:19` `centroidStream`: computes the projected planar
/// centroid `(x, y)` (area-weighted, falling back to length-weighted, then
/// point arithmetic mean).
final class GeoPathCentroidStream() extends GeoStream {
  /// Creates a [GeoPathCentroidStream].
  this;

  double _x0Sum = 0;
  double _y0Sum = 0;
  double _z0Sum = 0;
  double _x1Sum = 0;
  double _y1Sum = 0;
  double _z1Sum = 0;
  double _x2Sum = 0;
  double _y2Sum = 0;
  double _z2Sum = 0;
  double _x00 = 0;
  double _y00 = 0;
  double _x0 = 0;
  double _y0 = 0;

  // 0 = point, 1 = firstLine, 2 = line, 3 = firstRing, 4 = ring
  int _pointMode = 0;
  bool _inPolygon = false;

  @override
  void point(double x, double y, [double? z]) {
    switch (_pointMode) {
      case 0:
        _centroidPoint(x, y);
      case 1:
        _pointMode = 2;
        _centroidPoint(_x0 = x, _y0 = y);
      case 2:
        _centroidPointLine(x, y);
      case 3:
        _pointMode = 4;
        _centroidPoint(_x00 = _x0 = x, _y00 = _y0 = y);
      case 4:
        _centroidPointRing(x, y);
    }
  }

  @override
  void lineStart() {
    _pointMode = _inPolygon ? 3 : 1;
  }

  @override
  void lineEnd() {
    if (_inPolygon) {
      _centroidPointRing(_x00, _y00);
    } else {
      _pointMode = 0;
    }
  }

  @override
  void polygonStart() {
    _inPolygon = true;
  }

  @override
  void polygonEnd() {
    _inPolygon = false;
    _pointMode = 0;
  }

  @pragma('vm:prefer-inline')
  void _centroidPoint(double x, double y) {
    _x0Sum += x;
    _y0Sum += y;
    ++_z0Sum;
  }

  void _centroidPointLine(double x, double y) {
    final dx = x - _x0;
    final dy = y - _y0;
    final len = math.sqrt(dx * dx + dy * dy);
    _x1Sum += len * (_x0 + x) / 2;
    _y1Sum += len * (_y0 + y) / 2;
    _z1Sum += len;
    _centroidPoint(_x0 = x, _y0 = y);
  }

  void _centroidPointRing(double x, double y) {
    final dx = x - _x0;
    final dy = y - _y0;
    final len = math.sqrt(dx * dx + dy * dy);
    _x1Sum += len * (_x0 + x) / 2;
    _y1Sum += len * (_y0 + y) / 2;
    _z1Sum += len;

    final cross = _y0 * x - _x0 * y;
    _x2Sum += cross * (_x0 + x);
    _y2Sum += cross * (_y0 + y);
    _z2Sum += cross * 3;
    _centroidPoint(_x0 = x, _y0 = y);
  }

  /// Returns the planar centroid and resets the accumulators.
  GeoPosition result() {
    final GeoPosition centroid;
    if (_z2Sum != 0) {
      centroid = (_x2Sum / _z2Sum, _y2Sum / _z2Sum);
    } else if (_z1Sum != 0) {
      centroid = (_x1Sum / _z1Sum, _y1Sum / _z1Sum);
    } else if (_z0Sum != 0) {
      centroid = (_x0Sum / _z0Sum, _y0Sum / _z0Sum);
    } else {
      centroid = (double.nan, double.nan);
    }
    _x0Sum = _y0Sum = _z0Sum = 0;
    _x1Sum = _y1Sum = _z1Sum = 0;
    _x2Sum = _y2Sum = _z2Sum = 0;
    return centroid;
  }
}
