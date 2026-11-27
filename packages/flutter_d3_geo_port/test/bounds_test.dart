// Ported from d3-geo v3.1.1 test/bounds-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('bounds: Feature', () {
    expect(
      geoBounds(
        const GeoFeature<void>(
          geometry: GeoMultiPoint(<GeoPosition>[(-123, 39), (-122, 38)]),
        ),
      ),
      const ((-123.0, 38.0), (-122.0, 39.0)),
    );
  });

  test('bounds: FeatureCollection', () {
    expect(
      geoBounds(
        const GeoFeatureCollection<void>(<GeoFeature<void>>[
          GeoFeature<void>(geometry: GeoPoint((-123, 39))),
          GeoFeature<void>(geometry: GeoPoint((-122, 38))),
        ]),
      ),
      const ((-123.0, 38.0), (-122.0, 39.0)),
    );
  });

  test('bounds: GeometryCollection', () {
    expect(
      geoBounds(
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoPoint((-123, 39)),
          GeoPoint((-122, 38)),
        ]),
      ),
      const ((-123.0, 38.0), (-122.0, 39.0)),
    );
  });

  test('bounds: LineString - simple', () {
    expect(
      geoBounds(const GeoLineString(<GeoPosition>[(-123, 39), (-122, 38)])),
      const ((-123.0, 38.0), (-122.0, 39.0)),
    );
  });

  test('bounds: LineString - symmetry', () {
    expect(
      geoBounds(const GeoLineString(<GeoPosition>[(-30, -20), (130, 40)])),
      geoBounds(const GeoLineString(<GeoPosition>[(130, 40), (-30, -20)])),
    );
  });

  test('bounds: LineString - containing coincident points', () {
    expect(
      geoBounds(
        const GeoLineString(<GeoPosition>[(-123, 39), (-122, 38), (-122, 38)]),
      ),
      const ((-123.0, 38.0), (-122.0, 39.0)),
    );
  });

  test('bounds: LineString - meridian', () {
    expect(
      geoBounds(const GeoLineString(<GeoPosition>[(0, 0), (0, 1), (0, 60)])),
      const ((0.0, 0.0), (0.0, 60.0)),
    );
  });

  test('bounds: LineString - equator', () {
    expect(
      geoBounds(const GeoLineString(<GeoPosition>[(0, 0), (1, 0), (60, 0)])),
      const ((0.0, 0.0), (60.0, 0.0)),
    );
  });

  test('bounds: LineString - containing an inflection point in the Northern hemisphere', () {
    assertExtentInDelta(
      geoBounds(const GeoLineString(<GeoPosition>[(-45, 60), (45, 60)])),
      const ((-45, 60), (45, 67.792345)),
    );
  });

  test('bounds: LineString - containing an inflection point in the Southern hemisphere', () {
    assertExtentInDelta(
      geoBounds(const GeoLineString(<GeoPosition>[(-45, -60), (45, -60)])),
      const ((-45, -67.792345), (45, -60)),
    );
  });

  test('bounds: MultiLineString', () {
    expect(
      geoBounds(
        const GeoMultiLineString(<List<GeoPosition>>[
          <GeoPosition>[(-123, 39), (-122, 38)],
        ]),
      ),
      const ((-123.0, 38.0), (-122.0, 39.0)),
    );
  });

  test('bounds: MultiPoint - simple', () {
    expect(
      geoBounds(const GeoMultiPoint(<GeoPosition>[(-123, 39), (-122, 38)])),
      const ((-123.0, 38.0), (-122.0, 39.0)),
    );
  });

  test('bounds: MultiPoint - two points near antimeridian', () {
    expect(
      geoBounds(const GeoMultiPoint(<GeoPosition>[(-179, 39), (179, 38)])),
      const ((179.0, 38.0), (-179.0, 39.0)),
    );
  });

  test('bounds: MultiPoint - two points near antimeridian, two points near primary meridian', () {
    expect(
      geoBounds(
        const GeoMultiPoint(<GeoPosition>[
          (-179, 39),
          (179, 38),
          (-1, 0),
          (1, 0),
        ]),
      ),
      const ((-1.0, 0.0), (-179.0, 39.0)),
    );
  });

  test('bounds: MultiPoint - two points near primary meridian, two points near antimeridian', () {
    expect(
      geoBounds(
        const GeoMultiPoint(<GeoPosition>[
          (-1, 0),
          (1, 0),
          (-179, 39),
          (179, 38),
        ]),
      ),
      const ((-1.0, 0.0), (-179.0, 39.0)),
    );
  });

  test('bounds: MultiPoint - four mixed points near primary meridian and antimeridian', () {
    expect(
      geoBounds(
        const GeoMultiPoint(<GeoPosition>[
          (-1, 0),
          (-179, 39),
          (1, 0),
          (179, 38),
        ]),
      ),
      const ((-1.0, 0.0), (-179.0, 39.0)),
    );
  });

  test('bounds: MultiPoint - three points near antimeridian', () {
    expect(
      geoBounds(
        const GeoMultiPoint(<GeoPosition>[(178, 38), (179, 39), (-179, 37)]),
      ),
      const ((178.0, 37.0), (-179.0, 39.0)),
    );
  });

  test('bounds: MultiPoint - various points near antimeridian', () {
    expect(
      geoBounds(
        const GeoMultiPoint(<GeoPosition>[
          (-179, 39),
          (-179, 38),
          (178, 39),
          (-178, 38),
        ]),
      ),
      const ((178.0, 38.0), (-178.0, 39.0)),
    );
  });

  test('bounds: MultiPolygon', () {
    assertExtentInDelta(
      geoBounds(
        const GeoMultiPolygon(<List<List<GeoPosition>>>[
          <List<GeoPosition>>[
            <GeoPosition>[(-123, 39), (-122, 39), (-122, 38), (-123, 39)],
            <GeoPosition>[(10, 20), (20, 20), (20, 10), (10, 10), (10, 20)],
          ],
        ]),
      ),
      const ((-123, 10), (20, 39.001067)),
    );
  });

  test('bounds: Point', () {
    expect(geoBounds(const GeoPoint((-123, 39))), const (
      (-123.0, 39.0),
      (-123.0, 39.0),
    ));
  });

  test('bounds: Polygon - simple', () {
    assertExtentInDelta(
      geoBounds(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(-123, 39), (-122, 39), (-122, 38), (-123, 39)],
        ]),
      ),
      const ((-123, 38), (-122, 39.001067)),
    );
  });

  test(
    'bounds: Polygon - larger than a hemisphere, small, counter-clockwise',
    () {
      expect(
        geoBounds(
          const GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(0, 0), (10, 0), (10, 10), (0, 10), (0, 0)],
          ]),
        ),
        const ((-180.0, -90.0), (180.0, 90.0)),
      );
    },
  );

  test(
    'bounds: Polygon - larger than a hemisphere, large lat-lon rectangle',
    () {
      assertExtentInDelta(
        geoBounds(
          const GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[
              (-170, 80),
              (0, 80),
              (170, 80),
              (170, -80),
              (0, -80),
              (-170, -80),
              (-170, 80),
            ],
          ]),
        ),
        const ((-170, -89.119552), (170, 89.119552)),
      );
    },
  );

  test('bounds: Polygon - larger than a hemisphere, South pole', () {
    assertExtentInDelta(
      geoBounds(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(10, 80), (170, 80), (-170, 80), (-10, 80), (10, 80)],
        ]),
      ),
      const ((-180, -90), (180, 88.246216)),
    );
  });

  test('bounds: Polygon - larger than a hemisphere, excluding both poles', () {
    assertExtentInDelta(
      geoBounds(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[
            (10, 80),
            (170, 80),
            (-170, 80),
            (-10, 80),
            (-10, 0),
            (-10, -80),
            (-170, -80),
            (170, -80),
            (10, -80),
            (10, 0),
            (10, 80),
          ],
        ]),
      ),
      const ((10, -88.246216), (-10, 88.246216)),
    );
  });

  test('bounds: Polygon - South pole', () {
    expect(
      geoBounds(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(-60, -80), (60, -80), (180, -80), (-60, -80)],
        ]),
      ),
      const ((-180.0, -90.0), (180.0, -80.0)),
    );
  });

  test('bounds: Polygon - ring', () {
    assertExtentInDelta(
      geoBounds(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(-60, -80), (60, -80), (180, -80), (-60, -80)],
          <GeoPosition>[(-60, -89), (180, -89), (60, -89), (-60, -89)],
        ]),
      ),
      const ((-180, -89.499961), (180, -80)),
    );
  });

  test('bounds: Sphere', () {
    expect(geoBounds(const GeoSphere()), const (
      (-180.0, -90.0),
      (180.0, 90.0),
    ));
  });

  test('bounds: NestedCollection', () {
    expect(
      geoBounds(
        const GeoFeatureCollection<void>(<GeoFeature<void>>[
          GeoFeature<void>(
            geometry: GeoGeometryCollection(<GeoGeometry?>[
              GeoPoint((-120, 47)),
              GeoPoint((-119, 46)),
            ]),
          ),
        ]),
      ),
      const ((-120.0, 46.0), (-119.0, 47.0)),
    );
  });

  test('bounds: null geometries - Feature', () {
    final b = geoBounds(const GeoFeature<void>());
    expect(b.$1.$1.isNaN, isTrue);
    expect(b.$1.$2.isNaN, isTrue);
    expect(b.$2.$1.isNaN, isTrue);
    expect(b.$2.$2.isNaN, isTrue);
  });

  test('bounds: null geometries - MultiPoint', () {
    final b = geoBounds(const GeoMultiPoint(<GeoPosition>[]));
    expect(b.$1.$1.isNaN, isTrue);
    expect(b.$1.$2.isNaN, isTrue);
    expect(b.$2.$1.isNaN, isTrue);
    expect(b.$2.$2.isNaN, isTrue);
  });

  test('bounds: null geometries - MultiLineString', () {
    final b = geoBounds(const GeoMultiLineString(<List<GeoPosition>>[]));
    expect(b.$1.$1.isNaN, isTrue);
    expect(b.$1.$2.isNaN, isTrue);
    expect(b.$2.$1.isNaN, isTrue);
    expect(b.$2.$2.isNaN, isTrue);
  });

  test('bounds: null geometries - MultiPolygon', () {
    final b = geoBounds(const GeoMultiPolygon(<List<List<GeoPosition>>>[]));
    expect(b.$1.$1.isNaN, isTrue);
    expect(b.$1.$2.isNaN, isTrue);
    expect(b.$2.$1.isNaN, isTrue);
    expect(b.$2.$2.isNaN, isTrue);
  });
}
