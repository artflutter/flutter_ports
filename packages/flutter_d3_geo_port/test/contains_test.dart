// Ported from d3-geo v3.1.1 test/contains-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

void main() {
  test('a sphere contains any point', () {
    expect(geoContains(const GeoSphere(), const (0, 0)), isTrue);
  });

  test('a point contains itself (and not some other point)', () {
    expect(geoContains(const GeoPoint((0, 0)), const (0, 0)), isTrue);
    expect(geoContains(const GeoPoint((1, 2)), const (1, 2)), isTrue);
    expect(geoContains(const GeoPoint((0, 0)), const (0, 1)), isFalse);
    expect(geoContains(const GeoPoint((1, 1)), const (1, 0)), isFalse);
  });

  test('a MultiPoint contains any of its points', () {
    const mp = GeoMultiPoint(<GeoPosition>[(0, 0), (1, 2)]);
    expect(geoContains(mp, const (0, 0)), isTrue);
    expect(geoContains(mp, const (1, 2)), isTrue);
    expect(geoContains(mp, const (1, 3)), isFalse);
  });

  test('a LineString contains any point on the Great Circle path', () {
    const line = GeoLineString(<GeoPosition>[(0, 0), (1, 2)]);
    final interp = geoInterpolate(const (0, 0), const (1, 2));
    expect(geoContains(line, const (0, 0)), isTrue);
    expect(geoContains(line, const (1, 2)), isTrue);
    expect(geoContains(line, interp(0.3)), isTrue);
    expect(geoContains(line, interp(1.3)), isFalse);
    expect(geoContains(line, interp(-0.3)), isFalse);
  });

  test('a LineString with 2+ points contains those points', () {
    const points = <GeoPosition>[(0, 0), (1, 2), (3, 4), (5, 6)];
    const feature = GeoLineString(points);
    for (final point in points) {
      expect(geoContains(feature, point), isTrue);
    }
  });

  test('a LineString contains epsilon-distant points', () {
    const epsilon = 1e-6;
    const line = GeoLineString(<GeoPosition>[
      (0, 0),
      (0, 10),
      (10, 10),
      (10, 0),
    ]);
    const points = <GeoPosition>[
      (0, 5),
      (epsilon, 5),
      (0, epsilon),
      (epsilon, epsilon),
    ];
    for (final point in points) {
      expect(geoContains(line, point), isTrue);
    }
  });

  test('a LineString does not contain 10*epsilon-distant points', () {
    const epsilon = 1e-6;
    const line = GeoLineString(<GeoPosition>[
      (0, 0),
      (0, 10),
      (10, 10),
      (10, 0),
    ]);
    const points = <GeoPosition>[(epsilon * 10, 5), (epsilon * 10, epsilon)];
    for (final point in points) {
      expect(geoContains(line, point), isFalse);
    }
  });

  test('a MultiLineString contains any point on one of its components', () {
    const ml = GeoMultiLineString(<List<GeoPosition>>[
      <GeoPosition>[(0, 0), (1, 2)],
      <GeoPosition>[(2, 3), (4, 5)],
    ]);
    expect(geoContains(ml, const (2, 3)), isTrue);
    expect(geoContains(ml, const (5, 6)), isFalse);
  });

  test('a Polygon contains a point', () {
    final polygon = geoCircle(radius: 60)();
    expect(geoContains(polygon, const (1, 1)), isTrue);
    expect(geoContains(polygon, const (-180, 0)), isFalse);
  });

  test("a Polygon with a hole doesn't contain a point", () {
    final outer = geoCircle(radius: 60)().coordinates[0];
    final inner = geoCircle(radius: 3)().coordinates[0];
    final polygon = GeoPolygon(<List<GeoPosition>>[outer, inner]);
    expect(geoContains(polygon, const (1, 1)), isFalse);
    expect(geoContains(polygon, const (5, 0)), isTrue);
    expect(geoContains(polygon, const (65, 0)), isFalse);
  });

  test('a MultiPolygon contains a point', () {
    final p1 = geoCircle(radius: 6)().coordinates;
    final p2 = geoCircle(radius: 6, center: const (90, 0))().coordinates;
    final polygon = GeoMultiPolygon(<List<List<GeoPosition>>>[p1, p2]);
    expect(geoContains(polygon, const (1, 0)), isTrue);
    expect(geoContains(polygon, const (90, 1)), isTrue);
    expect(geoContains(polygon, const (90, 45)), isFalse);
  });

  test('a GeometryCollection contains a point', () {
    const collection = GeoGeometryCollection(<GeoGeometry?>[
      GeoGeometryCollection(<GeoGeometry?>[
        GeoLineString(<GeoPosition>[(-45, 0), (0, 0)]),
      ]),
      GeoLineString(<GeoPosition>[(0, 0), (45, 0)]),
    ]);
    expect(geoContains(collection, const (-45, 0)), isTrue);
    expect(geoContains(collection, const (45, 0)), isTrue);
    expect(geoContains(collection, const (12, 25)), isFalse);
  });

  test('a Feature contains a point', () {
    const feature = GeoFeature<void>(
      geometry: GeoLineString(<GeoPosition>[(0, 0), (45, 0)]),
    );
    expect(geoContains(feature, const (45, 0)), isTrue);
    expect(geoContains(feature, const (12, 25)), isFalse);
  });

  test('a FeatureCollection contains a point', () {
    const feature1 = GeoFeature<void>(
      geometry: GeoLineString(<GeoPosition>[(0, 0), (45, 0)]),
    );
    const feature2 = GeoFeature<void>(
      geometry: GeoLineString(<GeoPosition>[(-45, 0), (0, 0)]),
    );
    const fc = GeoFeatureCollection<void>(<GeoFeature<void>>[
      feature1,
      feature2,
    ]);
    expect(geoContains(fc, const (45, 0)), isTrue);
    expect(geoContains(fc, const (-45, 0)), isTrue);
    expect(geoContains(fc, const (12, 25)), isFalse);
  });

  test('null contains nothing', () {
    expect(geoContains(null, const (0, 0)), isFalse);
  });
}
