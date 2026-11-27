// Ported from d3-geo v3.1.1 test/path/string-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import '../asserts.dart';

final GeoProjection _equirectangular = geoEquirectangular()
  ..scale = 900 / math.pi
  ..precision = 0;

String? _testPath(GeoStreamable projection, GeoJsonObject object) =>
    (geoPath()..projection = projection)(object);

void main() {
  test('geoPath(Point) renders a point', () {
    assertPathEqual(
      _testPath(_equirectangular, const GeoPoint((-63, 18))),
      'M165,160m0,4.500000a4.500000,4.500000 0 1,1 0,-9a4.500000,4.500000 0 1,1 0,9z',
    );
  });

  test(
    'geoPath.pointRadius(radius)(Point) renders a point of the given radius',
    () {
      assertPathEqual(
        (geoPath()
          ..projection = _equirectangular
          ..pointRadius = 10)(const GeoPoint((-63, 18))),
        'M165,160m0,10a10,10 0 1,1 0,-20a10,10 0 1,1 0,20z',
      );
    },
  );

  test('geoPath(MultiPoint) renders a point', () {
    assertPathEqual(
      _testPath(
        _equirectangular,
        const GeoMultiPoint(<GeoPosition>[(-63, 18), (-62, 18), (-62, 17)]),
      ),
      'M165,160m0,4.500000a4.500000,4.500000 0 1,1 0,-9a4.500000,4.500000 0 1,1 0,9zM170,160m0,4.500000a4.500000,4.500000 0 1,1 0,-9a4.500000,4.500000 0 1,1 0,9zM170,165m0,4.500000a4.500000,4.500000 0 1,1 0,-9a4.500000,4.500000 0 1,1 0,9z',
    );
  });

  test('geoPath(LineString) renders a line string', () {
    assertPathEqual(
      _testPath(
        _equirectangular,
        const GeoLineString(<GeoPosition>[(-63, 18), (-62, 18), (-62, 17)]),
      ),
      'M165,160L170,160L170,165',
    );
  });

  test('geoPath(Polygon) renders a polygon', () {
    assertPathEqual(
      _testPath(
        _equirectangular,
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(-63, 18), (-62, 18), (-62, 17), (-63, 18)],
        ]),
      ),
      'M165,160L170,160L170,165Z',
    );
  });

  test('geoPath(GeometryCollection) renders a geometry collection', () {
    assertPathEqual(
      _testPath(
        _equirectangular,
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(-63, 18), (-62, 18), (-62, 17), (-63, 18)],
          ]),
        ]),
      ),
      'M165,160L170,160L170,165Z',
    );
  });

  test('geoPath(Feature) renders a feature', () {
    assertPathEqual(
      _testPath(
        _equirectangular,
        const GeoFeature<void>(
          geometry: GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(-63, 18), (-62, 18), (-62, 17), (-63, 18)],
          ]),
        ),
      ),
      'M165,160L170,160L170,165Z',
    );
  });

  test('geoPath(FeatureCollection) renders a feature collection', () {
    assertPathEqual(
      _testPath(
        _equirectangular,
        const GeoFeatureCollection<void>(<GeoFeature<void>>[
          GeoFeature<void>(
            geometry: GeoPolygon(<List<GeoPosition>>[
              <GeoPosition>[(-63, 18), (-62, 18), (-62, 17), (-63, 18)],
            ]),
          ),
        ]),
      ),
      'M165,160L170,160L170,165Z',
    );
  });

  test('geoPath(LineString) then geoPath(Point) does not treat the point as part of a line', () {
    final path = geoPath()..projection = _equirectangular;
    assertPathEqual(
      path(const GeoLineString(<GeoPosition>[(-63, 18), (-62, 18), (-62, 17)])),
      'M165,160L170,160L170,165',
    );
    assertPathEqual(
      path(const GeoPoint((-63, 18))),
      'M165,160m0,4.500000a4.500000,4.500000 0 1,1 0,-9a4.500000,4.500000 0 1,1 0,9z',
    );
  });
}
