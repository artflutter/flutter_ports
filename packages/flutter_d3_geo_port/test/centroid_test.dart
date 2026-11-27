// Ported from d3-geo v3.1.1 test/centroid-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_array_port/d3_array.dart' show range;
import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'data/ny_data.dart';

void _expectNaNPosition(GeoPosition p) {
  expect(p.$1.isNaN, isTrue);
  expect(p.$2.isNaN, isTrue);
}

void main() {
  test('the centroid of a point is itself', () {
    assertPositionInDelta(geoCentroid(const GeoPoint((0, 0))), const (0, 0));
    assertPositionInDelta(geoCentroid(const GeoPoint((1, 1))), const (1, 1));
    assertPositionInDelta(geoCentroid(const GeoPoint((2, 3))), const (2, 3));
    assertPositionInDelta(geoCentroid(const GeoPoint((-4, -5))), const (
      -4,
      -5,
    ));
  });

  test('the centroid of a set of points is the (spherical) average of its constituent members', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoPoint((0, 0)),
          GeoPoint((1, 2)),
        ]),
      ),
      const (0.499847, 1.000038),
    );
    assertPositionInDelta(
      geoCentroid(const GeoMultiPoint(<GeoPosition>[(0, 0), (1, 2)])),
      const (0.499847, 1.000038),
    );
    assertPositionInDelta(
      geoCentroid(const GeoMultiPoint(<GeoPosition>[(179, 0), (-179, 0)])),
      const (180, 0),
    );
  });

  test('the centroid of a set of points and their antipodes is ambiguous', () {
    _expectNaNPosition(
      geoCentroid(const GeoMultiPoint(<GeoPosition>[(0, 0), (180, 0)])),
    );
    _expectNaNPosition(
      geoCentroid(
        const GeoMultiPoint(<GeoPosition>[(0, 0), (90, 0), (180, 0), (-90, 0)]),
      ),
    );
    _expectNaNPosition(
      geoCentroid(
        const GeoMultiPoint(<GeoPosition>[(0, 0), (0, 90), (180, 0), (0, -90)]),
      ),
    );
  });

  test('the centroid of the empty set of points is ambiguous', () {
    _expectNaNPosition(geoCentroid(const GeoMultiPoint(<GeoPosition>[])));
  });

  test('the centroid of a line string is the (spherical) average of its constituent great arc segments', () {
    assertPositionInDelta(
      geoCentroid(const GeoLineString(<GeoPosition>[(0, 0), (1, 0)])),
      const (0.5, 0),
    );
    assertPositionInDelta(
      geoCentroid(const GeoLineString(<GeoPosition>[(0, 0), (0, 90)])),
      const (0, 45),
    );
    assertPositionInDelta(
      geoCentroid(const GeoLineString(<GeoPosition>[(0, 0), (0, 45), (0, 90)])),
      const (0, 45),
    );
    assertPositionInDelta(
      geoCentroid(const GeoLineString(<GeoPosition>[(-1, -1), (1, 1)])),
      const (0, 0),
    );
    assertPositionInDelta(
      geoCentroid(const GeoLineString(<GeoPosition>[(-60, -1), (60, 1)])),
      const (0, 0),
    );
    assertPositionInDelta(
      geoCentroid(const GeoLineString(<GeoPosition>[(179, -1), (-179, 1)])),
      const (180, 0),
    );
    assertPositionInDelta(
      geoCentroid(
        const GeoLineString(<GeoPosition>[(-179, 0), (0, 0), (179, 0)]),
      ),
      const (0, 0),
    );
    assertPositionInDelta(
      geoCentroid(
        const GeoLineString(<GeoPosition>[(-180, -90), (0, 0), (0, 90)]),
      ),
      const (0, 0),
    );
  });

  test(
    'the centroid of a great arc from a point to its antipode is ambiguous',
    () {
      _expectNaNPosition(
        geoCentroid(const GeoLineString(<GeoPosition>[(180, 0), (0, 0)])),
      );
      _expectNaNPosition(
        geoCentroid(
          const GeoMultiLineString(<List<GeoPosition>>[
            <GeoPosition>[(0, -90), (0, 90)],
          ]),
        ),
      );
    },
  );

  test('the centroid of a set of line strings is the (spherical) average of its constituent great arc segments', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoMultiLineString(<List<GeoPosition>>[
          <GeoPosition>[(0, 0), (0, 2)],
        ]),
      ),
      const (0, 1),
    );
  });

  test('a line of zero length is treated as points', () {
    assertPositionInDelta(
      geoCentroid(const GeoLineString(<GeoPosition>[(1, 1), (1, 1)])),
      const (1, 1),
    );
    assertPositionInDelta(
      geoCentroid(
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoPoint((0, 0)),
          GeoLineString(<GeoPosition>[(1, 2), (1, 2)]),
        ]),
      ),
      const (0.666534, 1.333408),
    );
  });

  test('an empty polygon with non-zero extent is treated as a line', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(1, 1), (2, 1), (3, 1), (2, 1), (1, 1)],
        ]),
      ),
      const (2, 1.000076),
    );
    assertPositionInDelta(
      geoCentroid(
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoPoint((0, 0)),
          GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(1, 2), (1, 2), (1, 2), (1, 2)],
          ]),
        ]),
      ),
      const (0.799907, 1.600077),
    );
  });

  test('an empty polygon with zero extent is treated as a point', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(1, 1), (1, 1), (1, 1), (1, 1)],
        ]),
      ),
      const (1, 1),
    );
    assertPositionInDelta(
      geoCentroid(
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoPoint((0, 0)),
          GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(1, 2), (1, 2), (1, 2), (1, 2)],
          ]),
        ]),
      ),
      const (0.799907, 1.600077),
    );
  });

  test('the centroid of the equator is ambiguous', () {
    _expectNaNPosition(
      geoCentroid(
        const GeoLineString(<GeoPosition>[(0, 0), (120, 0), (-120, 0), (0, 0)]),
      ),
    );
  });

  test(
    'the centroid of a polygon is the (spherical) average of its surface',
    () {
      assertPositionInDelta(
        geoCentroid(
          const GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(0, -90), (0, 0), (0, 90), (1, 0), (0, -90)],
          ]),
        ),
        const (0.5, 0),
      );
      assertInDelta(
        geoCentroid(
          GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[for (final x in range(-180, 180.5, 1)) (x, -60)],
          ]),
        ).$2,
        -90,
      );
      assertPositionInDelta(
        geoCentroid(
          const GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(0, -10), (0, 10), (10, 10), (10, -10), (0, -10)],
          ]),
        ),
        const (5, 0),
      );
    },
  );

  test('the centroid of a set of polygons is the (spherical) average of its surface', () {
    final circle = geoCircle();
    final p1 =
        (circle
              ..radius = 45
              ..center = const (90, 0))()
            .coordinates;
    final p2 =
        (circle
              ..radius = 60
              ..center = const (-90, 0))()
            .coordinates;
    assertPositionInDelta(
      geoCentroid(GeoMultiPolygon(<List<List<GeoPosition>>>[p1, p2])),
      const (-90, 0),
    );
  });

  test('the centroid of a lune is the (spherical) average of its surface', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, -90), (0, 0), (0, 90), (1, 0), (0, -90)],
        ]),
      ),
      const (0.5, 0),
    );
  });

  test('the centroid of a small circle is its center: 5°', () {
    assertPositionInDelta(
      geoCentroid(geoCircle(radius: 5, center: const (30, 45))()),
      const (30, 45),
    );
  });

  test('the centroid of a small circle is its center: 135°', () {
    assertPositionInDelta(
      geoCentroid(geoCircle(radius: 135, center: const (30, 45))()),
      const (30, 45),
    );
  });

  test('the centroid of a small circle is its center: South Pole', () {
    expect(
      geoCentroid(
        GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[for (final x in range(-180, 180.5, 1)) (x, -60)],
        ]),
      ).$2,
      -90,
    );
  });

  test('the centroid of a small circle is its center: equator', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, -10), (0, 10), (10, 10), (10, -10), (0, -10)],
        ]),
      ),
      const (5, 0),
    );
  });

  test('the centroid of a small circle is its center: equator with coincident points', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[
            (0, -10),
            (0, 10),
            (0, 10),
            (10, 10),
            (10, -10),
            (0, -10),
          ],
        ]),
      ),
      const (5, 0),
    );
  });

  test('the centroid of a small circle is its center: other', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[
            (-180, 0),
            (-180, 10),
            (-179, 10),
            (-179, 0),
            (-180, 0),
          ],
        ]),
      ),
      const (-179.5, 4.987448),
    );
  });

  test('the centroid of a small circle is its center: concentric rings', () {
    final circle = geoCircle(center: const (0, 45));
    final outer = (circle..radius = 60)().coordinates[0];
    final inner = (circle..radius = 45)().coordinates[0].reversed.toList();
    assertPositionInDelta(
      geoCentroid(GeoPolygon(<List<GeoPosition>>[outer, inner])),
      const (0, 45),
    );
  });

  test('the centroid of a spherical square on the equator', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, -10), (0, 10), (10, 10), (10, -10), (0, -10)],
        ]),
      ),
      const (5, 0),
    );
  });

  test('the centroid of a spherical square touching the antimeridian', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[
            (-180, 0),
            (-180, 10),
            (-179, 10),
            (-179, 0),
            (-180, 0),
          ],
        ]),
      ),
      const (-179.5, 4.987448),
    );
  });

  test('concentric rings', () {
    final circle = geoCircle(center: const (0, 45));
    final outer = (circle..radius = 60)().coordinates[0];
    final inner = (circle..radius = 45)().coordinates[0].reversed.toList();
    assertPositionInDelta(
      geoCentroid(GeoPolygon(<List<GeoPosition>>[outer, inner])),
      const (0, 45),
    );
  });

  test('the centroid of a sphere is ambiguous', () {
    _expectNaNPosition(geoCentroid(const GeoSphere()));
  });

  test(
    'the centroid of a feature is the centroid of its constituent geometry',
    () {
      assertPositionInDelta(
        geoCentroid(
          const GeoFeature<void>(
            geometry: GeoLineString(<GeoPosition>[(1, 1), (1, 1)]),
          ),
        ),
        const (1, 1),
      );
      assertPositionInDelta(
        geoCentroid(const GeoFeature<void>(geometry: GeoPoint((1, 1)))),
        const (1, 1),
      );
      assertPositionInDelta(
        geoCentroid(
          const GeoFeature<void>(
            geometry: GeoPolygon(<List<GeoPosition>>[
              <GeoPosition>[(0, -90), (0, 0), (0, 90), (1, 0), (0, -90)],
            ]),
          ),
        ),
        const (0.5, 0),
      );
    },
  );

  test('the centroid of a feature collection is the centroid of its constituent geometry', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoFeatureCollection<void>(<GeoFeature<void>>[
          GeoFeature<void>(
            geometry: GeoLineString(<GeoPosition>[(179, 0), (180, 0)]),
          ),
          GeoFeature<void>(geometry: GeoPoint((0, 0))),
        ]),
      ),
      const (179.5, 0),
    );
  });

  test('the centroid of a non-empty line string and a point only considers the line string', () {
    assertPositionInDelta(
      geoCentroid(
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoLineString(<GeoPosition>[(179, 0), (180, 0)]),
          GeoPoint((0, 0)),
        ]),
      ),
      const (179.5, 0),
    );
  });

  test('the centroid of a non-empty polygon, a non-empty line string and a point only considers the polygon', () {
    assertPositionInDelta(
      geoCentroid(
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
      const (-179.5, 0.500006),
    );
    assertPositionInDelta(
      geoCentroid(
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoPoint((0, 0)),
          GeoLineString(<GeoPosition>[(179, 0), (180, 0)]),
          GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[
              (-180, 0),
              (-180, 1),
              (-179, 1),
              (-179, 0),
              (-180, 0),
            ],
          ]),
        ]),
      ),
      const (-179.5, 0.500006),
    );
  });

  test('the centroid of the sphere and a point is the point', () {
    expect(
      geoCentroid(
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoSphere(),
          GeoPoint((0, 0)),
        ]),
      ),
      const (0.0, 0.0),
    );
    expect(
      geoCentroid(
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoPoint((0, 0)),
          GeoSphere(),
        ]),
      ),
      const (0.0, 0.0),
    );
  });

  test('the centroid of a detailed feature is correct', () {
    assertPositionInDelta(geoCentroid(nyFeatureCollection), const (
      -73.93079,
      40.69447,
    ), 1e-5);
  });
}
