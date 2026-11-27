// Ported from d3-geo v3.1.1 test/asserts.js (ISC, Mike Bostock).

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

final RegExp _reNumber = RegExp(
  r'[-+]?(?:\d+\.\d+|\d+\.|\.\d+|\d+)(?:[eE][-]?\d+)?',
);

String _formatNumber(Match m) {
  final s = double.parse(m.group(0)!);
  final r = geoJsRound(s);
  if ((s - r).abs() < 1e-6) {
    return r == 0 ? '0' : r.toInt().toString();
  }
  return s.toStringAsFixed(3);
}

String _normalizePath(String path) =>
    path.replaceAllMapped(_reNumber, _formatNumber);

void assertPathEqual(String? actual, String expected) {
  expect(actual, isNotNull);
  expect(_normalizePath(actual!), _normalizePath(expected));
}

void assertInDelta(double actual, double expected, [double delta = 1e-6]) {
  expect(
    actual >= expected - delta && actual <= expected + delta,
    isTrue,
    reason: '$actual should be within $delta of $expected',
  );
}

void assertPositionInDelta(
  GeoPosition actual,
  GeoPosition expected, [
  double delta = 1e-6,
]) {
  assertInDelta(actual.$1, expected.$1, delta);
  assertInDelta(actual.$2, expected.$2, delta);
}

void assertExtentInDelta(
  GeoExtent actual,
  GeoExtent expected, [
  double delta = 1e-6,
]) {
  assertPositionInDelta(actual.$1, expected.$1, delta);
  assertPositionInDelta(actual.$2, expected.$2, delta);
}

void assertRingInDelta(
  List<GeoPosition> actual,
  List<GeoPosition> expected, [
  double delta = 1e-6,
]) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    assertPositionInDelta(actual[i], expected[i], delta);
  }
}
