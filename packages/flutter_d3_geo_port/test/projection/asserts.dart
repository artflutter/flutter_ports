// Ported from d3-geo v3.1.1 test/projection/asserts.js (ISC, Mike Bostock).
// Upstream assertion message exceeds 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

bool _inDelta(double actual, double expected, double delta) =>
    (actual - expected).abs() <= delta;

bool _longitudeEqual(double actual, double expected, double delta) {
  final d = (actual - expected).abs().remainder(360);
  return d <= delta || d >= 360 - delta;
}

bool _planarEqual(GeoPosition? actual, GeoPosition expected, double delta) =>
    actual != null &&
    _inDelta(actual.$1, expected.$1, delta) &&
    _inDelta(actual.$2, expected.$2, delta);

bool _sphericalEqual(GeoPosition? actual, GeoPosition expected, double delta) =>
    actual != null &&
    _longitudeEqual(actual.$1, expected.$1, delta) &&
    _inDelta(actual.$2, expected.$2, delta);

void assertProjectionEqual(
  GeoProjector projection,
  GeoPosition location,
  GeoPosition point, [
  double? delta,
]) {
  final fwd = projection(location);
  final inv = projection.invert(point);
  expect(
    _planarEqual(fwd, point, delta ?? 1e-6) &&
        _sphericalEqual(inv, location, delta ?? 1e-3),
    isTrue,
    reason:
        '[$inv, $fwd] should be projected equivalents; expected: [$location, $point]',
  );
}
