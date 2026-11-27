// Ported from d3-geo v3.1.1 src/length.js (ISC, Mike Bostock).

/// Port of `src/length.js` of d3-geo 3.1.1: [geoLength].
library;

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart' show Adder;
import 'package:flutter_d3_geo_port/src/geojson.dart';
import 'package:flutter_d3_geo_port/src/math.dart';
import 'package:flutter_d3_geo_port/src/stream.dart';

final class _LengthStream() extends GeoStream {
  final Adder _lengthSum = Adder();
  double _lambda0 = 0;
  double _sinPhi0 = 0;
  double _cosPhi0 = 0;

  // 0 = noop, 1 = first line point, 2 = subsequent line points
  int _pointMode = 0;

  @override
  void point(double x, double y, [double? z]) {
    if (_pointMode == 2) {
      final l = x * geoRadians;
      final p = y * geoRadians;
      final sinPhi = math.sin(p);
      final cosPhi = math.cos(p);
      final delta = (l - _lambda0).abs();
      final cosDelta = math.cos(delta);
      final sinDelta = math.sin(delta);
      final cx = cosPhi * sinDelta;
      final cy = _cosPhi0 * sinPhi - _sinPhi0 * cosPhi * cosDelta;
      final cz = _sinPhi0 * sinPhi + _cosPhi0 * cosPhi * cosDelta;
      _lengthSum.add(math.atan2(math.sqrt(cx * cx + cy * cy), cz));
      _lambda0 = l;
      _sinPhi0 = sinPhi;
      _cosPhi0 = cosPhi;
    } else if (_pointMode == 1) {
      final l = x * geoRadians;
      final p = y * geoRadians;
      _lambda0 = l;
      _sinPhi0 = math.sin(p);
      _cosPhi0 = math.cos(p);
      _pointMode = 2;
    }
  }

  @override
  void lineStart() {
    _pointMode = 1;
  }

  @override
  void lineEnd() {
    _pointMode = 0;
  }

  double finish() => _lengthSum.valueOf();
}

/// `length.js:49` `geoLength(object)`: returns the great-arc length of the
/// specified GeoJSON [object] in radians.
double geoLength(GeoJsonObject? object) {
  final stream = _LengthStream();
  geoStream(object, stream);
  return stream.finish();
}
