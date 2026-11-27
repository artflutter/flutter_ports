// Ported from d3-geo v3.1.1 test/projection/transverseMercator-test.js (ISC, Mike Bostock).
// Upstream filename and test titles exceed 80 chars.
// ignore_for_file: file_names, lines_longer_than_80_chars

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('transverseMercator.clipExtent(null) sets the default automatic clip extent', () {
    final projection = geoTransverseMercator()
      ..translate = const (0, 0)
      ..scale = 1
      ..clipExtent = null
      ..precision = 0;
    assertPathEqual(
      geoPath(projection)(const GeoSphere()),
      'M3.141593,3.141593L0,3.141593L-3.141593,3.141593L-3.141593,-3.141593L-3.141593,-3.141593L0,-3.141593L3.141593,-3.141593L3.141593,3.141593Z',
    );
    expect(projection.clipExtent, isNull);
  });

  test(
    'transverseMercator.center(center) sets the correct automatic clip extent',
    () {
      final projection = geoTransverseMercator()
        ..translate = const (0, 0)
        ..scale = 1
        ..center = const (10, 10)
        ..precision = 0;
      assertPathEqual(
        geoPath(projection)(const GeoSphere()),
        'M2.966167,3.316126L-0.175426,3.316126L-3.317018,3.316126L-3.317019,-2.967060L-3.317019,-2.967060L-0.175426,-2.967060L2.966167,-2.967060L2.966167,3.316126Z',
      );
      expect(projection.clipExtent, isNull);
    },
  );

  test('transverseMercator.clipExtent(extent) intersects the specified clip extent with the automatic clip extent', () {
    final projection = geoTransverseMercator()
      ..translate = const (0, 0)
      ..scale = 1
      ..clipExtent = const ((-10, -10), (10, 10))
      ..precision = 0;
    assertPathEqual(
      geoPath(projection)(const GeoSphere()),
      'M10,3.141593L0,3.141593L-10,3.141593L-10,-3.141593L-10,-3.141593L0,-3.141593L10,-3.141593L10,3.141593Z',
    );
    expect(projection.clipExtent, const ((-10.0, -10.0), (10.0, 10.0)));
  });

  test('transverseMercator.clipExtent(extent).scale(scale) updates the intersected clip extent', () {
    final projection = geoTransverseMercator()
      ..translate = const (0, 0)
      ..clipExtent = const ((-10, -10), (10, 10))
      ..scale = 1
      ..precision = 0;
    assertPathEqual(
      geoPath(projection)(const GeoSphere()),
      'M10,3.141593L0,3.141593L-10,3.141593L-10,-3.141593L-10,-3.141593L0,-3.141593L10,-3.141593L10,3.141593Z',
    );
    expect(projection.clipExtent, const ((-10.0, -10.0), (10.0, 10.0)));
  });

  test('transverseMercator.clipExtent(extent).translate(translate) updates the intersected clip extent', () {
    final projection = geoTransverseMercator()
      ..scale = 1
      ..clipExtent = const ((-10, -10), (10, 10))
      ..translate = const (0, 0)
      ..precision = 0;
    assertPathEqual(
      geoPath(projection)(const GeoSphere()),
      'M10,3.141593L0,3.141593L-10,3.141593L-10,-3.141593L-10,-3.141593L0,-3.141593L10,-3.141593L10,3.141593Z',
    );
    expect(projection.clipExtent, const ((-10.0, -10.0), (10.0, 10.0)));
  });

  test(
    'transverseMercator.rotate(…) does not affect the automatic clip extent',
    () {
      final projection = geoTransverseMercator();
      const object = GeoMultiPoint(<GeoPosition>[
        (-82.35024908550241, 29.649391549778745),
        (-82.35014449996858, 29.65075946917633),
        (-82.34916073446641, 29.65070265688781),
        (-82.3492653331286, 29.64933474064504),
      ]);
      projection.fitExtent(const ((0, 0), (960, 600)), object);
      assertInDelta(projection.scale, 15724992.330511674, 1e-4);
      assertPositionInDelta(projection.translate, const (
        20418843.897824813,
        21088401.790971387,
      ), 1e-4);
      projection
        ..rotate = const (0, 95, 0)
        ..fitExtent(const ((0, 0), (960, 600)), object);
      assertInDelta(projection.scale, 15724992.330511674, 1e-4);
      assertPositionInDelta(projection.translate, const (
        20418843.897824813,
        47161426.43770847,
      ), 1e-4);
    },
  );
}
