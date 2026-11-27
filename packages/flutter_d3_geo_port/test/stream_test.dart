// Ported from d3-geo v3.1.1 test/stream-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

void main() {
  // DIVERGES(d3-geo): adapt-geo-typed-api, sealed GeoJsonObject rejects
  // unknown GeoJSON type discriminators at compile time.
  test(
    'geoStream(object) ignores unknown types',
    () {},
    skip: 'diverges: adapt-geo-typed-api',
  );

  test('geoStream(object) ignores null geometries', () {
    final noop = GeoStreamCallbacks();
    geoStream(null, noop);
    geoStream(const GeoFeature<void>(), noop);
    geoStream(
      const GeoFeatureCollection<void>(<GeoFeature<void>>[GeoFeature<void>()]),
      noop,
    );
    geoStream(const GeoGeometryCollection(<GeoGeometry?>[null]), noop);
  });

  test('geoStream(object) returns void', () {
    var called = false;
    geoStream(
      const GeoPoint((1, 2)),
      GeoStreamCallbacks(point: (_, _, [_]) => called = true),
    );
    expect(called, isTrue);
  });

  test('geoStream(object) allows empty multi-geometries', () {
    final noop = GeoStreamCallbacks();
    geoStream(const GeoMultiPoint(<GeoPosition>[]), noop);
    geoStream(const GeoMultiLineString(<List<GeoPosition>>[]), noop);
    geoStream(const GeoMultiPolygon(<List<List<GeoPosition>>>[]), noop);
  });

  test('geoStream(Sphere) ↦ sphere', () {
    var calls = 0;
    geoStream(
      const GeoSphere(),
      GeoStreamCallbacks(
        sphere: () {
          expect(++calls, 1);
        },
      ),
    );
    expect(calls, 1);
  });

  test('geoStream(Point) ↦ point', () {
    var calls = 0;
    var coordinates = 0;
    geoStream(
      const GeoPoint((1, 2), elevation: 3),
      GeoStreamCallbacks(
        point: (x, y, [z]) {
          expect(x, ++coordinates);
          expect(y, ++coordinates);
          expect(z, ++coordinates);
          expect(++calls, 1);
        },
      ),
    );
    expect(calls, 1);
  });

  test('geoStream(MultiPoint) ↦ point*', () {
    var calls = 0;
    var coordinates = 0;
    geoStream(
      const GeoMultiPoint(
        <GeoPosition>[(1, 2), (4, 5)],
        elevations: <double?>[3, 6],
      ),
      GeoStreamCallbacks(
        point: (x, y, [z]) {
          expect(x, ++coordinates);
          expect(y, ++coordinates);
          expect(z, ++coordinates);
          expect(++calls, inInclusiveRange(1, 2));
        },
      ),
    );
    expect(calls, 2);
  });

  test('geoStream(LineString) ↦ lineStart, point{2,}, lineEnd', () {
    var calls = 0;
    var coordinates = 0;
    geoStream(
      const GeoLineString(
        <GeoPosition>[(1, 2), (4, 5)],
        elevations: <double?>[3, 6],
      ),
      GeoStreamCallbacks(
        lineStart: () {
          expect(++calls, 1);
        },
        point: (x, y, [z]) {
          expect(x, ++coordinates);
          expect(y, ++coordinates);
          expect(z, ++coordinates);
          expect(++calls, inInclusiveRange(2, 3));
        },
        lineEnd: () {
          expect(++calls, 4);
        },
      ),
    );
    expect(calls, 4);
  });

  test('geoStream(MultiLineString) ↦ (lineStart, point{2,}, lineEnd)*', () {
    var calls = 0;
    var coordinates = 0;
    geoStream(
      const GeoMultiLineString(
        <List<GeoPosition>>[
          <GeoPosition>[(1, 2), (4, 5)],
          <GeoPosition>[(7, 8), (10, 11)],
        ],
        elevations: <List<double?>?>[
          <double?>[3, 6],
          <double?>[9, 12],
        ],
      ),
      GeoStreamCallbacks(
        lineStart: () {
          final c = ++calls;
          expect(c == 1 || c == 5, isTrue);
        },
        point: (x, y, [z]) {
          expect(x, ++coordinates);
          expect(y, ++coordinates);
          expect(z, ++coordinates);
          final c = ++calls;
          expect((c >= 2 && c <= 3) || (c >= 6 && c <= 7), isTrue);
        },
        lineEnd: () {
          final c = ++calls;
          expect(c == 4 || c == 8, isTrue);
        },
      ),
    );
    expect(calls, 8);
  });

  test('geoStream(Polygon) ↦ polygonStart, lineStart, point{2,}, lineEnd, polygonEnd', () {
    var calls = 0;
    var coordinates = 0;
    geoStream(
      const GeoPolygon(
        <List<GeoPosition>>[
          <GeoPosition>[(1, 2), (4, 5), (1, 2)],
          <GeoPosition>[(7, 8), (10, 11), (7, 8)],
        ],
        elevations: <List<double?>?>[
          <double?>[3, 6, 3],
          <double?>[9, 12, 9],
        ],
      ),
      GeoStreamCallbacks(
        polygonStart: () {
          expect(++calls, 1);
        },
        lineStart: () {
          final c = ++calls;
          expect(c == 2 || c == 6, isTrue);
        },
        point: (x, y, [z]) {
          expect(x, ++coordinates);
          expect(y, ++coordinates);
          expect(z, ++coordinates);
          final c = ++calls;
          expect((c >= 3 && c <= 4) || (c >= 7 && c <= 8), isTrue);
        },
        lineEnd: () {
          final c = ++calls;
          expect(c == 5 || c == 9, isTrue);
        },
        polygonEnd: () {
          expect(++calls, 10);
        },
      ),
    );
    expect(calls, 10);
  });

  test('geoStream(MultiPolygon) ↦ (polygonStart, lineStart, point{2,}, lineEnd, polygonEnd)*', () {
    var calls = 0;
    var coordinates = 0;
    geoStream(
      const GeoMultiPolygon(
        <List<List<GeoPosition>>>[
          <List<GeoPosition>>[
            <GeoPosition>[(1, 2), (4, 5), (1, 2)],
          ],
          <List<GeoPosition>>[
            <GeoPosition>[(7, 8), (10, 11), (7, 8)],
          ],
        ],
        elevations: <List<List<double?>?>?>[
          <List<double?>?>[
            <double?>[3, 6, 3],
          ],
          <List<double?>?>[
            <double?>[9, 12, 9],
          ],
        ],
      ),
      GeoStreamCallbacks(
        polygonStart: () {
          final c = ++calls;
          expect(c == 1 || c == 7, isTrue);
        },
        lineStart: () {
          final c = ++calls;
          expect(c == 2 || c == 8, isTrue);
        },
        point: (x, y, [z]) {
          expect(x, ++coordinates);
          expect(y, ++coordinates);
          expect(z, ++coordinates);
          final c = ++calls;
          expect((c >= 3 && c <= 4) || (c >= 9 && c <= 10), isTrue);
        },
        lineEnd: () {
          final c = ++calls;
          expect(c == 5 || c == 11, isTrue);
        },
        polygonEnd: () {
          final c = ++calls;
          expect(c == 6 || c == 12, isTrue);
        },
      ),
    );
    expect(calls, 12);
  });

  test('geoStream(Feature) ↦ .*', () {
    var calls = 0;
    var coordinates = 0;
    geoStream(
      const GeoFeature<void>(geometry: GeoPoint((1, 2), elevation: 3)),
      GeoStreamCallbacks(
        point: (x, y, [z]) {
          expect(x, ++coordinates);
          expect(y, ++coordinates);
          expect(z, ++coordinates);
          expect(++calls, 1);
        },
      ),
    );
    expect(calls, 1);
  });

  test('geoStream(FeatureCollection) ↦ .*', () {
    var calls = 0;
    var coordinates = 0;
    geoStream(
      const GeoFeatureCollection<void>(<GeoFeature<void>>[
        GeoFeature<void>(geometry: GeoPoint((1, 2), elevation: 3)),
      ]),
      GeoStreamCallbacks(
        point: (x, y, [z]) {
          expect(x, ++coordinates);
          expect(y, ++coordinates);
          expect(z, ++coordinates);
          expect(++calls, 1);
        },
      ),
    );
    expect(calls, 1);
  });

  test('geoStream(GeometryCollection) ↦ .*', () {
    var calls = 0;
    var coordinates = 0;
    geoStream(
      const GeoGeometryCollection(<GeoGeometry?>[
        GeoPoint((1, 2), elevation: 3),
      ]),
      GeoStreamCallbacks(
        point: (x, y, [z]) {
          expect(x, ++coordinates);
          expect(y, ++coordinates);
          expect(z, ++coordinates);
          expect(++calls, 1);
        },
      ),
    );
    expect(calls, 1);
  });
}
