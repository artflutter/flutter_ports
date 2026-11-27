// Ported from d3-geo v3.1.1 test/projection/identity-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('identity(point) returns the point', () {
    final identity = geoIdentity()
      ..translate = const (0, 0)
      ..scale = 1;
    assertProjectionEqual(identity, const (0, 0), const (0, 0));
    assertProjectionEqual(identity, const (-180, 0), const (-180, 0));
    assertProjectionEqual(identity, const (180, 0), const (180, 0));
    assertProjectionEqual(identity, const (30, 30), const (30, 30));
  });

  test(
    'identity(point).scale(…).translate(…) returns the transformed point',
    () {
      final identity = geoIdentity()
        ..translate = const (100, 10)
        ..scale = 2;
      assertProjectionEqual(identity, const (0, 0), const (100, 10));
      assertProjectionEqual(identity, const (-180, 0), const (-260, 10));
      assertProjectionEqual(identity, const (180, 0), const (460, 10));
      assertProjectionEqual(identity, const (30, 30), const (160, 70));
    },
  );

  test(
    'identity(point).reflectX(…) and reflectY() return the transformed point',
    () {
      final identity = geoIdentity()
        ..translate = const (100, 10)
        ..scale = 2
        ..reflectX = false
        ..reflectY = false;
      assertProjectionEqual(identity, const (3, 7), const (106, 24));
      assertProjectionEqual(
        identity..reflectX = true,
        const (3, 7),
        const (94, 24),
      );
      assertProjectionEqual(
        identity..reflectY = true,
        const (3, 7),
        const (94, -4),
      );
      assertProjectionEqual(
        identity..reflectX = false,
        const (3, 7),
        const (106, -4),
      );
      assertProjectionEqual(
        identity..reflectY = false,
        const (3, 7),
        const (106, 24),
      );
    },
  );

  test('geoPath(identity) returns the path', () {
    final identity = geoIdentity()
      ..translate = const (0, 0)
      ..scale = 1;
    final path = geoPath()..projection = identity;
    expect(
      path(const GeoLineString(<GeoPosition>[(0, 0), (10, 10)])),
      'M0,0L10,10',
    );
    identity
      ..translate = const (30, 90)
      ..scale = 2
      ..reflectY = true;
    expect(
      path(const GeoLineString(<GeoPosition>[(0, 0), (10, 10)])),
      'M30,90L50,70',
    );
  });

  test('geoPath(identity) respects clipExtent', () {
    final identity = geoIdentity()
      ..translate = const (0, 0)
      ..scale = 1;
    final path = geoPath()..projection = identity;
    identity.clipExtent = const ((5, 5), (40, 80));
    expect(
      path(const GeoLineString(<GeoPosition>[(0, 0), (10, 10)])),
      'M5,5L10,10',
    );
    identity
      ..translate = const (30, 90)
      ..scale = 2
      ..reflectY = true
      ..clipExtent = const ((35, 76), (45, 86));
    expect(
      path(const GeoLineString(<GeoPosition>[(0, 0), (10, 10)])),
      'M35,85L44,76',
    );
  });
}
