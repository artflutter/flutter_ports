// Ported from d3-geo v3.1.1 test/graticule-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_array_port/d3_array.dart' show extentBy;
import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

void main() {
  test('graticule.extent() gets precision', () {
    final g = geoGraticule();
    expect(g.precision, 2.5);
    g.precision = 999;
    expect(g.precision, 999);
  });

  test('graticule.extent(…) sets extentMinor and extentMajor', () {
    final g = geoGraticule()..extent = const ((-90, -45), (90, 45));
    expect(g.extentMinor, const ((-90.0, -45.0), (90.0, 45.0)));
    expect(g.extentMajor, const ((-90.0, -45.0), (90.0, 45.0)));

    final gReversed = geoGraticule()..extent = const ((90, 45), (-90, -45));
    expect(gReversed.extentMinor, const ((-90.0, -45.0), (90.0, 45.0)));
    expect(gReversed.extentMajor, const ((-90.0, -45.0), (90.0, 45.0)));
  });

  test('graticule.extent() gets extentMinor', () {
    final g = geoGraticule()..extentMinor = const ((-90, -45), (90, 45));
    expect(g.extent, const ((-90.0, -45.0), (90.0, 45.0)));
  });

  test('graticule.extentMajor() default longitude ranges from 180°W (inclusive) to 180°E (exclusive)', () {
    final e = geoGraticule().extentMajor;
    expect(e.$1.$1, -180);
    expect(e.$2.$1, 180);
  });

  test('graticule.extentMajor() default latitude ranges from 90°S (exclusive) to 90°N (exclusive)', () {
    final e = geoGraticule().extentMajor;
    expect(e.$1.$2, -90 + 1e-6);
    expect(e.$2.$2, 90 - 1e-6);
  });

  // DIVERGES(d3-geo): adapt-geo-typed-api, typed GeoExtent requires doubles
  // rather than JS string-to-number coercion.
  test(
    'graticule.extentMajor(…) coerces input values to numbers',
    () {},
    skip: 'diverges: adapt-geo-typed-api',
  );

  test('graticule.extentMinor() default longitude ranges from 180°W (inclusive) to 180°E (exclusive)', () {
    final e = geoGraticule().extentMinor;
    expect(e.$1.$1, -180);
    expect(e.$2.$1, 180);
  });

  test('graticule.extentMinor() default latitude ranges from 80°S (inclusive) to 80°N (inclusive)', () {
    final e = geoGraticule().extentMinor;
    expect(e.$1.$2, -80 - 1e-6);
    expect(e.$2.$2, 80 + 1e-6);
  });

  test(
    'graticule.extentMinor(…) coerces input values to numbers',
    () {},
    skip: 'diverges: adapt-geo-typed-api',
  );

  test('graticule.step(…) sets the minor and major step', () {
    final g = geoGraticule()..step = const (22.5, 22.5);
    expect(g.stepMinor, const (22.5, 22.5));
    expect(g.stepMajor, const (22.5, 22.5));
  });

  test('graticule.step() gets the minor step', () {
    final g = geoGraticule()..stepMinor = const (22.5, 22.5);
    expect(g.step, const (22.5, 22.5));
  });

  test('graticule.stepMinor() defaults to 10°, 10°', () {
    expect(geoGraticule().stepMinor, const (10.0, 10.0));
  });

  test(
    'graticule.stepMinor(…) coerces input values to numbers',
    () {},
    skip: 'diverges: adapt-geo-typed-api',
  );

  test('graticule.stepMajor() defaults to 90°, 360°', () {
    expect(geoGraticule().stepMajor, const (90.0, 360.0));
  });

  test(
    'graticule.stepMajor(…) coerces input values to numbers',
    () {},
    skip: 'diverges: adapt-geo-typed-api',
  );

  test('graticule.lines() default longitude ranges from 180°W (inclusive) to 180°E (exclusive)', () {
    final lines =
        geoGraticule()
            .lines()
            .where((line) => line.coordinates[0].$1 == line.coordinates[1].$1)
            .toList()
          ..sort((a, b) => a.coordinates[0].$1.compareTo(b.coordinates[0].$1));
    expect(lines.first.coordinates[0].$1, -180);
    expect(lines.last.coordinates[0].$1, 170);
  });

  test('graticule.lines() default latitude ranges from 90°S (exclusive) to 90°N (exclusive)', () {
    final lines =
        geoGraticule()
            .lines()
            .where((line) => line.coordinates[0].$2 == line.coordinates[1].$2)
            .toList()
          ..sort((a, b) => a.coordinates[0].$2.compareTo(b.coordinates[0].$2));
    expect(lines.first.coordinates[0].$2, -80);
    expect(lines.last.coordinates[0].$2, 80);
  });

  test(
    'graticule.lines() default minor longitude lines extend from 80°S to 80°N',
    () {
      final lines = geoGraticule()
          .lines()
          .where((line) => line.coordinates[0].$1 == line.coordinates[1].$1)
          .where((line) => line.coordinates[0].$1.remainder(90).abs() > 1e-6);
      for (final line in lines) {
        expect(extentBy(line.coordinates, (p) => p.$2), const (
          -80 - 1e-6,
          80 + 1e-6,
        ));
      }
    },
  );

  test(
    'graticule.lines() default major longitude lines extend from 90°S to 90°N',
    () {
      final lines = geoGraticule()
          .lines()
          .where((line) => line.coordinates[0].$1 == line.coordinates[1].$1)
          .where((line) => line.coordinates[0].$1.remainder(90).abs() < 1e-6);
      for (final line in lines) {
        expect(extentBy(line.coordinates, (p) => p.$2), const (
          -90 + 1e-6,
          90 - 1e-6,
        ));
      }
    },
  );

  test(
    'graticule.lines() default latitude lines extend from 180°W to 180°E',
    () {
      final lines = geoGraticule().lines().where(
        (line) => line.coordinates[0].$2 == line.coordinates[1].$2,
      );
      for (final line in lines) {
        expect(extentBy(line.coordinates, (p) => p.$1), const (-180.0, 180.0));
      }
    },
  );

  test('graticule.lines() returns an array of LineStrings', () {
    final g = geoGraticule()
      ..extent = const ((-90, -45), (90, 45))
      ..step = const (45, 45)
      ..precision = 3;
    final lines = g.lines();
    expect(lines, hasLength(6));
    expect(lines[0].coordinates, const <GeoPosition>[(-90, -45), (-90, 45)]);
    expect(lines[1].coordinates, const <GeoPosition>[(-45, -45), (-45, 45)]);
    expect(lines[2].coordinates, const <GeoPosition>[(0, -45), (0, 45)]);
    expect(lines[3].coordinates, const <GeoPosition>[(45, -45), (45, 45)]);
    expect(lines[4].coordinates, <GeoPosition>[
      for (var x = -90; x <= 90; x += 3) (x.toDouble(), -45),
    ]);
    expect(lines[5].coordinates, <GeoPosition>[
      for (var x = -90; x <= 90; x += 3) (x.toDouble(), 0),
    ]);
  });

  test('graticule() returns a MultiLineString of all lines', () {
    final g = geoGraticule()
      ..extent = const ((-90, -45), (90, 45))
      ..step = const (45, 45)
      ..precision = 3;
    final ml = g();
    expect(ml.type, 'MultiLineString');
    expect(ml.coordinates, <List<GeoPosition>>[
      for (final l in g.lines()) l.coordinates,
    ]);
  });

  test(
    'graticule.outline() returns a Polygon encompassing the major extent',
    () {
      final g = geoGraticule()
        ..extentMajor = const ((-90, -45), (90, 45))
        ..precision = 3;
      final poly = g.outline();
      expect(poly.type, 'Polygon');
      expect(poly.coordinates, hasLength(1));
      expect(poly.coordinates[0], <GeoPosition>[
        const (-90, -45),
        const (-90, 45),
        for (var x = -87; x <= 87; x += 3) (x.toDouble(), 45),
        const (90, 45),
        const (90, -45),
        for (var x = 87; x >= -90; x -= 3) (x.toDouble(), -45),
      ]);
    },
  );
}
