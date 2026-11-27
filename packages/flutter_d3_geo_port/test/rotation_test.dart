// Ported from d3-geo v3.1.1 test/rotation-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('a rotation of [+90°, 0°] only rotates longitude', () {
    final rotation = geoRotation(90, 0)(const (0, 0));
    assertInDelta(rotation.$1, 90);
    assertInDelta(rotation.$2, 0);
  });

  test(
    'a rotation of [+90°, 0°] wraps around when crossing the antimeridian',
    () {
      final rotation = geoRotation(90, 0)(const (150, 0));
      assertInDelta(rotation.$1, -120);
      assertInDelta(rotation.$2, 0);
    },
  );

  test('a rotation of [-45°, 45°] rotates longitude and latitude', () {
    final rotation = geoRotation(-45, 45)(const (0, 0));
    assertInDelta(rotation.$1, -54.73561);
    assertInDelta(rotation.$2, 30);
  });

  test(
    'a rotation of [-45°, 45°] inverse rotation of longitude and latitude',
    () {
      final rotation = geoRotation(-45, 45).invert(const (-54.73561, 30));
      assertInDelta(rotation.$1, 0);
      assertInDelta(rotation.$2, 0);
    },
  );

  test('the identity rotation constrains longitudes to [-180°, 180°]', () {
    final rotate = geoRotation(0, 0);
    expect(rotate(const (180, 0)).$1, 180);
    expect(rotate(const (-180, 0)).$1, -180);
    expect(rotate(const (360, 0)).$1, 0);
    assertInDelta(rotate(const (2562, 0)).$1, 42, 1e-10);
    assertInDelta(rotate(const (-2562, 0)).$1, -42, 1e-10);
  });
}
