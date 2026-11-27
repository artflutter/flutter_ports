// Ported from d3-geo v3.1.1 test/path/measure-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

void main() {
  test('geoPath.measure(…) of a Point', () {
    expect(geoPath().measure(const GeoPoint((0, 0))), 0);
  });

  test('geoPath.measure(…) of a MultiPoint', () {
    expect(
      geoPath().measure(
        const GeoMultiPoint(<GeoPosition>[(0, 0), (0, 1), (1, 1), (1, 0)]),
      ),
      0,
    );
  });

  test('geoPath.measure(…) of a LineString', () {
    expect(
      geoPath().measure(
        const GeoLineString(<GeoPosition>[(0, 0), (0, 1), (1, 1), (1, 0)]),
      ),
      3,
    );
  });

  test('geoPath.measure(…) of a MultiLineString', () {
    expect(
      geoPath().measure(
        const GeoMultiLineString(<List<GeoPosition>>[
          <GeoPosition>[(0, 0), (0, 1), (1, 1), (1, 0)],
        ]),
      ),
      3,
    );
  });

  test('geoPath.measure(…) of a Polygon', () {
    expect(
      geoPath().measure(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, 0), (0, 1), (1, 1), (1, 0), (0, 0)],
        ]),
      ),
      4,
    );
  });

  test('geoPath.measure(…) of a Polygon with a hole', () {
    expect(
      geoPath().measure(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(-1, -1), (-1, 2), (2, 2), (2, -1), (-1, -1)],
          <GeoPosition>[(0, 0), (1, 0), (1, 1), (0, 1), (0, 0)],
        ]),
      ),
      16,
    );
  });

  test('geoPath.measure(…) of a MultiPolygon', () {
    expect(
      geoPath().measure(
        const GeoMultiPolygon(<List<List<GeoPosition>>>[
          <List<GeoPosition>>[
            <GeoPosition>[(-1, -1), (-1, 2), (2, 2), (2, -1), (-1, -1)],
          ],
          <List<GeoPosition>>[
            <GeoPosition>[(0, 0), (0, 1), (1, 1), (1, 0), (0, 0)],
          ],
        ]),
      ),
      16,
    );
  });
}
