// Ported from d3-geo v3.1.1 src/path/area.js (ISC, Mike Bostock).

/// Port of `src/path/area.js` of d3-geo 3.1.1: [GeoPathAreaStream].
library;

import 'package:flutter_d3_array_port/d3_array.dart' show Adder;
import 'package:flutter_d3_geo_port/src/stream.dart';

/// `path/area.js:12` `areaStream`: computes the projected planar area of
/// streamed polygons via the shoelace formula with Shewchuk summation.
final class GeoPathAreaStream() extends GeoStream {
  /// Creates a [GeoPathAreaStream].
  this;

  Adder _areaSum = Adder();
  Adder _areaRingSum = Adder();
  double _x00 = 0;
  double _y00 = 0;
  double _x0 = 0;
  double _y0 = 0;

  // 0 = noop, 1 = first ring point, 2 = subsequent ring points
  int _pointMode = 0;
  bool _inPolygon = false;

  @override
  void point(double x, double y, [double? z]) {
    if (_pointMode == 2) {
      _areaRingSum.add(_y0 * x - _x0 * y);
      _x0 = x;
      _y0 = y;
    } else if (_pointMode == 1) {
      _pointMode = 2;
      _x00 = _x0 = x;
      _y00 = _y0 = y;
    }
  }

  @override
  void lineStart() {
    if (_inPolygon) {
      _pointMode = 1;
    }
  }

  @override
  void lineEnd() {
    if (_inPolygon) {
      _areaRingSum.add(_y0 * _x00 - _x0 * _y00);
      _x0 = _x00;
      _y0 = _y00;
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
    _areaSum.add(_areaRingSum.valueOf().abs());
    _areaRingSum = Adder();
  }

  /// Returns the projected planar area and resets the accumulator.
  double result() {
    final area = _areaSum.valueOf() / 2;
    _areaSum = Adder();
    return area;
  }
}
