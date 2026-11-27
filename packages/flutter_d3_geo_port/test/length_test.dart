// Ported from d3-geo v3.1.1 test/length-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('geoLength(Point) returns zero', () {
    assertInDelta(geoLength(const GeoPoint((0, 0))), 0);
  });

  test('geoLength(MultiPoint) returns zero', () {
    assertInDelta(
      geoLength(const GeoMultiPoint(<GeoPosition>[(0, 1), (2, 3)])),
      0,
    );
  });

  test('geoLength(LineString) returns the sum of its great-arc segments', () {
    assertInDelta(
      geoLength(const GeoLineString(<GeoPosition>[(-45, 0), (45, 0)])),
      math.pi / 2,
    );
    assertInDelta(
      geoLength(
        const GeoLineString(<GeoPosition>[
          (-45, 0),
          (-30, 0),
          (-15, 0),
          (0, 0),
        ]),
      ),
      math.pi / 4,
    );
  });

  test(
    'geoLength(MultiLineString) returns the sum of its great-arc segments',
    () {
      assertInDelta(
        geoLength(
          const GeoMultiLineString(<List<GeoPosition>>[
            <GeoPosition>[(-45, 0), (-30, 0)],
            <GeoPosition>[(-15, 0), (0, 0)],
          ]),
        ),
        math.pi / 6,
      );
    },
  );

  test('geoLength(Polygon) returns the length of its perimeter', () {
    assertInDelta(
      geoLength(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, 0), (3, 0), (3, 3), (0, 3), (0, 0)],
        ]),
      ),
      0.157008,
    );
  });

  test(
    'geoLength(Polygon) returns the length of its perimeter, including holes',
    () {
      assertInDelta(
        geoLength(
          const GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(0, 0), (3, 0), (3, 3), (0, 3), (0, 0)],
            <GeoPosition>[(1, 1), (2, 1), (2, 2), (1, 2), (1, 1)],
          ]),
        ),
        0.209354,
      );
    },
  );

  test(
    'geoLength(MultiPolygon) returns the summed length of the perimeters',
    () {
      assertInDelta(
        geoLength(
          const GeoMultiPolygon(<List<List<GeoPosition>>>[
            <List<GeoPosition>>[
              <GeoPosition>[(0, 0), (3, 0), (3, 3), (0, 3), (0, 0)],
            ],
          ]),
        ),
        0.157008,
      );
      assertInDelta(
        geoLength(
          const GeoMultiPolygon(<List<List<GeoPosition>>>[
            <List<GeoPosition>>[
              <GeoPosition>[(0, 0), (3, 0), (3, 3), (0, 3), (0, 0)],
            ],
            <List<GeoPosition>>[
              <GeoPosition>[(1, 1), (2, 1), (2, 2), (1, 2), (1, 1)],
            ],
          ]),
        ),
        0.209354,
      );
    },
  );

  test(
    "geoLength(FeatureCollection) returns the sum of its features' lengths",
    () {
      assertInDelta(
        geoLength(
          const GeoFeatureCollection<void>(<GeoFeature<void>>[
            GeoFeature<void>(
              geometry: GeoLineString(<GeoPosition>[(-45, 0), (0, 0)]),
            ),
            GeoFeature<void>(
              geometry: GeoLineString(<GeoPosition>[(0, 0), (45, 0)]),
            ),
          ]),
        ),
        math.pi / 2,
      );
    },
  );

  test(
    "geoLength(GeometryCollection) returns the sum of its geometries' lengths",
    () {
      assertInDelta(
        geoLength(
          const GeoGeometryCollection(<GeoGeometry?>[
            GeoGeometryCollection(<GeoGeometry?>[
              GeoLineString(<GeoPosition>[(-45, 0), (0, 0)]),
            ]),
            GeoLineString(<GeoPosition>[(0, 0), (45, 0)]),
          ]),
        ),
        math.pi / 2,
      );
    },
  );
}
