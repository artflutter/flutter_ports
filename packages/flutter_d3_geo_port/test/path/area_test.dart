// Ported from d3-geo v3.1.1 test/path/area-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

final GeoProjection _equirectangular = geoEquirectangular()
  ..scale = 900 / math.pi
  ..precision = 0;

double _testArea(GeoStreamable projection, GeoJsonObject object) =>
    (geoPath()..projection = projection).area(object);

void main() {
  test('geoPath.area(…) of a polygon with no holes', () {
    expect(
      _testArea(
        _equirectangular,
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(100, 0), (100, 1), (101, 1), (101, 0), (100, 0)],
        ]),
      ),
      25,
    );
  });

  test('geoPath.area(…) of a polygon with holes', () {
    expect(
      _testArea(
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
      16,
    );
  });

  test('geoPath.area(…) of a sphere', () {
    expect(_testArea(_equirectangular, const GeoSphere()), 1620000);
  });
}
