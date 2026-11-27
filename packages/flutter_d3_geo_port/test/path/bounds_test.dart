// Ported from d3-geo v3.1.1 test/path/bounds-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

final GeoProjection _equirectangular = geoEquirectangular()
  ..scale = 900 / math.pi
  ..precision = 0;

GeoExtent _testBounds(GeoStreamable projection, GeoJsonObject object) =>
    (geoPath()..projection = projection).bounds(object);

void main() {
  test('geoPath.bounds(…) of a polygon with no holes', () {
    expect(
      _testBounds(
        _equirectangular,
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(100, 0), (100, 1), (101, 1), (101, 0), (100, 0)],
        ]),
      ),
      const ((980.0, 245.0), (985.0, 250.0)),
    );
  });

  test('geoPath.bounds(…) of a polygon with holes', () {
    expect(
      _testBounds(
        _equirectangular,
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(100, 0), (100, 1), (101, 1), (101, 0), (100, 0)],
          <GeoPosition>[
            (100.2, 0.2),
            (100.8, 0.2),
            (100.8, 0.8),
            (100.2, 0.8),
            (100.2, 0.2),
          ],
        ]),
      ),
      const ((980.0, 245.0), (985.0, 250.0)),
    );
  });

  test('geoPath.bounds(…) of a sphere', () {
    expect(_testBounds(_equirectangular, const GeoSphere()), const (
      (-420.0, -200.0),
      (1380.0, 700.0),
    ));
  });
}
