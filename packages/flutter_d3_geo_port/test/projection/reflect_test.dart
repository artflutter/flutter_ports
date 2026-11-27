// Ported from d3-geo v3.1.1 test/projection/reflect-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import '../asserts.dart';
import 'asserts.dart';

void main() {
  test('projection.reflectX(…) defaults to false', () {
    final projection = geoGnomonic()
      ..scale = 1
      ..translate = const (0, 0);
    expect(projection.reflectX, isFalse);
    expect(projection.reflectY, isFalse);
    assertProjectionEqual(projection, const (0, 0), const (0, 0));
    assertProjectionEqual(
      projection,
      const (10, 0),
      const (0.17632698070846498, 0),
    );
    assertProjectionEqual(
      projection,
      const (0, 10),
      const (0, -0.17632698070846498),
    );
  });

  test('projection.reflectX(…) mirrors x after projecting', () {
    final projection = geoGnomonic()
      ..scale = 1
      ..translate = const (0, 0)
      ..reflectX = true;
    expect(projection.reflectX, isTrue);
    assertProjectionEqual(projection, const (0, 0), const (0, 0));
    assertProjectionEqual(
      projection,
      const (10, 0),
      const (-0.17632698070846498, 0),
    );
    assertProjectionEqual(
      projection,
      const (0, 10),
      const (0, -0.17632698070846498),
    );
    projection
      ..reflectX = false
      ..reflectY = true;
    expect(projection.reflectX, isFalse);
    expect(projection.reflectY, isTrue);
    assertProjectionEqual(projection, const (0, 0), const (0, 0));
    assertProjectionEqual(
      projection,
      const (10, 0),
      const (0.17632698070846498, 0),
    );
    assertProjectionEqual(
      projection,
      const (0, 10),
      const (0, 0.17632698070846498),
    );
  });

  test('projection.reflectX(…) works with projection.angle()', () {
    final projection = geoMercator()
      ..scale = 1
      ..translate = const (10, 20)
      ..reflectX = true
      ..angle = 45;
    expect(projection.reflectX, isTrue);
    assertInDelta(projection.angle, 45);
    assertProjectionEqual(projection, const (0, 0), const (10, 20));
    assertProjectionEqual(
      projection,
      const (10, 0),
      const (9.87658658, 20.12341341),
    );
    assertProjectionEqual(
      projection,
      const (0, 10),
      const (9.87595521, 19.87595521),
    );
  });
}
