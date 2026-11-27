// Ported from d3-geo v3.1.1 src/path/measure.js (ISC, Mike Bostock).

/// Port of `src/path/measure.js` of d3-geo 3.1.1: [GeoPathMeasureStream].
library;

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart' show Adder;
import 'package:flutter_d3_geo_port/src/stream.dart';

/// `path/measure.js:12` `lengthStream`: computes the projected planar length
/// (or polygon perimeter) using Shewchuk summation.
final class GeoPathMeasureStream() extends GeoStream {
  /// Creates a [GeoPathMeasureStream].
  this;

  Adder _lengthSum = Adder();
  bool _lengthRing = false;
  double _x00 = 0;
  double _y00 = 0;
  double _x0 = 0;
  double _y0 = 0;

  // 0 = noop, 1 = first point, 2 = subsequent points
  int _pointMode = 0;

  @override
  void point(double x, double y, [double? z]) {
    if (_pointMode == 2) {
      final dx = _x0 - x;
      final dy = _y0 - y;
      _lengthSum.add(math.sqrt(dx * dx + dy * dy));
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
    _pointMode = 1;
  }

  @override
  void lineEnd() {
    if (_lengthRing) {
      final dx = _x0 - _x00;
      final dy = _y0 - _y00;
      _lengthSum.add(math.sqrt(dx * dx + dy * dy));
      _x0 = _x00;
      _y0 = _y00;
    }
    _pointMode = 0;
  }

  @override
  void polygonStart() {
    _lengthRing = true;
  }

  @override
  void polygonEnd() {
    _lengthRing = false;
  }

  /// Returns the accumulated planar length and resets the sum.
  double result() {
    final len = _lengthSum.valueOf();
    _lengthSum = Adder();
    return len;
  }
}
