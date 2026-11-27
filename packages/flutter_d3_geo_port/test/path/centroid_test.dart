// Ported from d3-geo v3.1.1 test/path/centroid-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import '../asserts.dart';

final GeoProjection _equirectangular = geoEquirectangular()
  ..scale = 900 / math.pi
  ..precision = 0;

GeoPosition _testCentroid(GeoStreamable projection, GeoJsonObject object) =>
    (geoPath()..projection = projection).centroid(object);

void main() {
  test('geoPath.centroid(…) of a point', () {
    expect(_testCentroid(_equirectangular, const GeoPoint((0, 0))), const (
      480.0,
      250.0,
    ));
  });

  test('geoPath.centroid(…) of an empty multipoint', () {
    final c = _testCentroid(
      _equirectangular,
      const GeoMultiPoint(<GeoPosition>[]),
    );
    expect(c.$1.isNaN && c.$2.isNaN, isTrue);
  });

  test('geoPath.centroid(…) of a singleton multipoint', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoMultiPoint(<GeoPosition>[(0, 0)]),
      ),
      const (480.0, 250.0),
    );
  });

  test('geoPath.centroid(…) of a multipoint with two points', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoMultiPoint(<GeoPosition>[(-122, 37), (-74, 40)]),
      ),
      const (-10.0, 57.5),
    );
  });

  test('geoPath.centroid(…) of an empty linestring', () {
    final c = _testCentroid(
      _equirectangular,
      const GeoLineString(<GeoPosition>[]),
    );
    expect(c.$1.isNaN && c.$2.isNaN, isTrue);
  });

  test('geoPath.centroid(…) of a linestring with two points', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoLineString(<GeoPosition>[(100, 0), (0, 0)]),
      ),
      const (730.0, 250.0),
    );
    expect(
      _testCentroid(
        _equirectangular,
        const GeoLineString(<GeoPosition>[(0, 0), (100, 0), (101, 0)]),
      ),
      const (732.5, 250.0),
    );
  });

  test('geoPath.centroid(…) of a linestring with two points, one unique', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoLineString(<GeoPosition>[(-122, 37), (-122, 37)]),
      ),
      const (-130.0, 65.0),
    );
    expect(
      _testCentroid(
        _equirectangular,
        const GeoLineString(<GeoPosition>[(-74, 40), (-74, 40)]),
      ),
      const (110.0, 50.0),
    );
  });

  test('geoPath.centroid(…) of a linestring with three points; two unique', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoLineString(<GeoPosition>[(-122, 37), (-74, 40), (-74, 40)]),
      ),
      const (-10.0, 57.5),
    );
  });

  test('geoPath.centroid(…) of a linestring with three points', () {
    assertPositionInDelta(
      _testCentroid(
        _equirectangular,
        const GeoLineString(<GeoPosition>[(-122, 37), (-74, 40), (-100, 0)]),
      ),
      const (17.389135, 103.563545),
    );
  });

  test('geoPath.centroid(…) of a multilinestring', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoMultiLineString(<List<GeoPosition>>[
          <GeoPosition>[(100, 0), (0, 0)],
          <GeoPosition>[(-10, 0), (0, 0)],
        ]),
      ),
      const (705.0, 250.0),
    );
  });

  test('geoPath.centroid(…) of a single-ring polygon', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(100, 0), (100, 1), (101, 1), (101, 0), (100, 0)],
        ]),
      ),
      const (982.5, 247.5),
    );
  });

  test('geoPath.centroid(…) of a zero-area polygon', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(1, 0), (2, 0), (3, 0), (1, 0)],
        ]),
      ),
      const (490.0, 250.0),
    );
  });

  test(
    'geoPath.centroid(…) of a polygon with two rings, one with zero area',
    () {
      expect(
        _testCentroid(
          _equirectangular,
          const GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(100, 0), (100, 1), (101, 1), (101, 0), (100, 0)],
            <GeoPosition>[(100.1, 0), (100.2, 0), (100.3, 0), (100.1, 0)],
          ]),
        ),
        const (982.5, 247.5),
      );
    },
  );

  test('geoPath.centroid(…) of a polygon with clockwise exterior and anticlockwise interior', () {
    assertPositionInDelta(
      _testCentroid(
        _equirectangular,
        GeoPolygon(<List<GeoPosition>>[
          const <GeoPosition>[
            (-2, -2),
            (2, -2),
            (2, 2),
            (-2, 2),
            (-2, -2),
          ].reversed.toList(),
          const <GeoPosition>[(0, -1), (1, -1), (1, 1), (0, 1), (0, -1)],
        ]),
      ),
      const (479.642857, 250),
    );
  });

  test('geoPath.centroid(…) of an empty multipolygon', () {
    final c = _testCentroid(
      _equirectangular,
      const GeoMultiPolygon(<List<List<GeoPosition>>>[]),
    );
    expect(c.$1.isNaN && c.$2.isNaN, isTrue);
  });

  test('geoPath.centroid(…) of a singleton multipolygon', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoMultiPolygon(<List<List<GeoPosition>>>[
          <List<GeoPosition>>[
            <GeoPosition>[(100, 0), (100, 1), (101, 1), (101, 0), (100, 0)],
          ],
        ]),
      ),
      const (982.5, 247.5),
    );
  });

  test('geoPath.centroid(…) of a multipolygon with two polygons', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoMultiPolygon(<List<List<GeoPosition>>>[
          <List<GeoPosition>>[
            <GeoPosition>[(100, 0), (100, 1), (101, 1), (101, 0), (100, 0)],
          ],
          <List<GeoPosition>>[
            <GeoPosition>[(0, 0), (1, 0), (1, -1), (0, -1), (0, 0)],
          ],
        ]),
      ),
      const (732.5, 250.0),
    );
  });

  test(
    'geoPath.centroid(…) of a multipolygon with two polygons, one zero area',
    () {
      expect(
        _testCentroid(
          _equirectangular,
          const GeoMultiPolygon(<List<List<GeoPosition>>>[
            <List<GeoPosition>>[
              <GeoPosition>[(100, 0), (100, 1), (101, 1), (101, 0), (100, 0)],
            ],
            <List<GeoPosition>>[
              <GeoPosition>[(0, 0), (1, 0), (2, 0), (0, 0)],
            ],
          ]),
        ),
        const (982.5, 247.5),
      );
    },
  );

  test('geoPath.centroid(…) of a geometry collection with a single point', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoGeometryCollection(<GeoGeometry?>[GeoPoint((0, 0))]),
      ),
      const (480.0, 250.0),
    );
  });

  test('geoPath.centroid(…) of a geometry collection with a point and a linestring', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoLineString(<GeoPosition>[(179, 0), (180, 0)]),
          GeoPoint((0, 0)),
        ]),
      ),
      const (1377.5, 250.0),
    );
  });

  test('geoPath.centroid(…) of a geometry collection with a point, linestring and polygon', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[
              (-180, 0),
              (-180, 1),
              (-179, 1),
              (-179, 0),
              (-180, 0),
            ],
          ]),
          GeoLineString(<GeoPosition>[(179, 0), (180, 0)]),
          GeoPoint((0, 0)),
        ]),
      ),
      const (-417.5, 247.5),
    );
  });

  test('geoPath.centroid(…) of a feature collection with a point', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoFeatureCollection<void>(<GeoFeature<void>>[
          GeoFeature<void>(geometry: GeoPoint((0, 0))),
        ]),
      ),
      const (480.0, 250.0),
    );
  });

  test('geoPath.centroid(…) of a feature collection with a point and a line string', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoFeatureCollection<void>(<GeoFeature<void>>[
          GeoFeature<void>(
            geometry: GeoLineString(<GeoPosition>[(179, 0), (180, 0)]),
          ),
          GeoFeature<void>(geometry: GeoPoint((0, 0))),
        ]),
      ),
      const (1377.5, 250.0),
    );
  });

  test('geoPath.centroid(…) of a feature collection with a point, line string and polygon', () {
    expect(
      _testCentroid(
        _equirectangular,
        const GeoFeatureCollection<void>(<GeoFeature<void>>[
          GeoFeature<void>(
            geometry: GeoPolygon(<List<GeoPosition>>[
              <GeoPosition>[
                (-180, 0),
                (-180, 1),
                (-179, 1),
                (-179, 0),
                (-180, 0),
              ],
            ]),
          ),
          GeoFeature<void>(
            geometry: GeoLineString(<GeoPosition>[(179, 0), (180, 0)]),
          ),
          GeoFeature<void>(geometry: GeoPoint((0, 0))),
        ]),
      ),
      const (-417.5, 247.5),
    );
  });

  test('geoPath.centroid(…) of a sphere', () {
    expect(_testCentroid(_equirectangular, const GeoSphere()), const (
      480.0,
      250.0,
    ));
  });
}
