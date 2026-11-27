// Ported from d3-geo v3.1.1 test/distance-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('geoDistance(a, b) computes the great-arc distance in radians between the two points a and b', () {
    expect(geoDistance(const (0, 0), const (0, 0)), 0);
    assertInDelta(
      geoDistance(
        const (118 + 24 / 60, 33 + 57 / 60),
        const (73 + 47 / 60, 40 + 38 / 60),
      ),
      3973 / 6371,
      0.5,
    );
  });

  test('geoDistance(a, b) correctly computes small distances', () {
    expect(geoDistance(const (0, 0), const (0, 1e-12)), greaterThan(0));
  });
}
