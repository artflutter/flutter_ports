// Ported from d3-geo v3.1.1 test/interpolate-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('geoInterpolate(a, a) returns a', () {
    expect(
      geoInterpolate(
        const (140.63289, -29.95101),
        const (140.63289, -29.95101),
      )(0.5),
      const (140.63289, -29.95101),
    );
  });

  test('geoInterpolate(a, b) returns the expected values when a and b lie on the equator', () {
    assertPositionInDelta(
      geoInterpolate(const (10, 0), const (20, 0))(0.5),
      const (15, 0),
    );
  });

  test('geoInterpolate(a, b) returns the expected values when a and b lie on a meridian', () {
    assertPositionInDelta(
      geoInterpolate(const (10, -20), const (10, 40))(0.5),
      const (10, 10),
    );
  });
}
