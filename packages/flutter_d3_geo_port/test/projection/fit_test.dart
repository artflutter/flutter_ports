// Ported from d3-geo v3.1.1 test/projection/fit-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import '../asserts.dart';
import '../data/us_land_data.dart';
import '../data/world_land_data.dart';
import '../port/d3_geo_reference.dart';

void _expectWorldFit(String key, GeoProjector projection) {
  final (expScale, expTranslate) = refWorldFit[key]!;
  assertInDelta(projection.scale, expScale);
  assertPositionInDelta(projection.translate, expTranslate);
}

void main() {
  final us = usLandFeature;
  const world = worldLandFeature;

  test('projection.fitExtent(…) sphere equirectangular', () {
    final projection = geoEquirectangular()
      ..fitExtent(const ((50, 50), (950, 950)), const GeoSphere());
    assertInDelta(projection.scale, 900 / (2 * math.pi));
    assertPositionInDelta(projection.translate, const (500, 500));
  });

  test('projection.fitExtent(…) world equirectangular', () {
    final projection = geoEquirectangular()
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world equirectangular', projection);
  });

  test('projection.fitExtent(…) world azimuthalEqualArea', () {
    final projection = geoAzimuthalEqualArea()
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world azimuthalEqualArea', projection);
  });

  test('projection.fitExtent(…) world azimuthalEquidistant', () {
    final projection = geoAzimuthalEquidistant()
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world azimuthalEquidistant', projection);
  });

  test('projection.fitExtent(…) world conicConformal', () {
    final projection = geoConicConformal()
      ..clipAngle = 30
      ..parallels = const (30, 60)
      ..rotate = const (0, -45, 0)
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world conicConformal', projection);
  });

  test('projection.fitExtent(…) world conicEqualArea', () {
    final projection = geoConicEqualArea()
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world conicEqualArea', projection);
  });

  test('projection.fitExtent(…) world conicEquidistant', () {
    final projection = geoConicEquidistant()
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world conicEquidistant', projection);
  });

  test('projection.fitSize(…) world equirectangular', () {
    final projection = geoEquirectangular()..fitSize(const (900, 900), world);
    _expectWorldFit('world fitSize equirectangular', projection);
  });

  test('projection.fitExtent(…) world gnomonic', () {
    final projection = geoGnomonic()
      ..clipAngle = 45
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world gnomonic', projection);
  });

  test('projection.fitExtent(…) world mercator', () {
    final projection = geoMercator()
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world mercator', projection);
  });

  test('projection.fitExtent(…) world orthographic', () {
    final projection = geoOrthographic()
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world orthographic', projection);
  });

  test('projection.fitSize(…) world orthographic', () {
    final projection = geoOrthographic()..fitSize(const (900, 900), world);
    _expectWorldFit('world fitSize orthographic', projection);
  });

  test('projection.fitExtent(…) world stereographic', () {
    final projection = geoStereographic()
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world stereographic', projection);
  });

  test('projection.fitExtent(…) world transverseMercator', () {
    final projection = geoTransverseMercator()
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world transverseMercator', projection);
  });

  test('projection.fitExtent(…) USA albersUsa', () {
    final projection = geoAlbersUsa()
      ..fitExtent(const ((50, 50), (950, 950)), us);
    assertInDelta(projection.scale, 1152.889035);
    assertPositionInDelta(projection.translate, const (533.52541, 496.232028));
  });

  test('projection.fitExtent(…) null geometries - Feature', () {
    final projection = geoEquirectangular()
      ..fitExtent(const ((50, 50), (950, 950)), const GeoFeature<void>());
    expect(projection.scale == 0 || projection.scale.isNaN, isTrue);
    expect(projection.translate.$1.isNaN, isTrue);
    expect(projection.translate.$2.isNaN, isTrue);
  });

  test('projection.fitExtent(…) null geometries - MultiPoint', () {
    final projection = geoEquirectangular()
      ..fitExtent(const (
        (50, 50),
        (950, 950),
      ), const GeoMultiPoint(<GeoPosition>[]));
    expect(projection.scale == 0 || projection.scale.isNaN, isTrue);
    expect(projection.translate.$1.isNaN, isTrue);
    expect(projection.translate.$2.isNaN, isTrue);
  });

  test('projection.fitExtent(…) null geometries - MultiLineString', () {
    final projection = geoEquirectangular()
      ..fitExtent(const (
        (50, 50),
        (950, 950),
      ), const GeoMultiLineString(<List<GeoPosition>>[]));
    expect(projection.scale == 0 || projection.scale.isNaN, isTrue);
    expect(projection.translate.$1.isNaN, isTrue);
    expect(projection.translate.$2.isNaN, isTrue);
  });

  test('projection.fitExtent(…) null geometries - MultiPolygon', () {
    final projection = geoEquirectangular()
      ..fitExtent(const (
        (50, 50),
        (950, 950),
      ), const GeoMultiPolygon(<List<List<GeoPosition>>>[]));
    expect(projection.scale == 0 || projection.scale.isNaN, isTrue);
    expect(projection.translate.$1.isNaN, isTrue);
    expect(projection.translate.$2.isNaN, isTrue);
  });

  test('projection.fitExtent(…) custom projection', () {
    final projection = geoProjection(geoRawProjection((x, y) => (x, y * y * y)))
      ..fitExtent(const ((50, 50), (950, 950)), world);
    _expectWorldFit('world custom', projection);
  });

  test('projection.fitSize(…) ignore clipExtent - world equirectangular', () {
    final p1 = geoEquirectangular()..fitSize(const (1000, 1000), world);
    final p2 = geoEquirectangular()
      ..clipExtent = const ((100, 200), (700, 600))
      ..fitSize(const (1000, 1000), world);
    assertInDelta(p1.scale, p2.scale);
    assertPositionInDelta(p1.translate, p2.translate);
    expect(p1.clipExtent, isNull);
    expect(p2.clipExtent, const ((100.0, 200.0), (700.0, 600.0)));
  });

  test('projection.fitExtent(…) chaining - world transverseMercator', () {
    final projection = geoTransverseMercator()
      ..fitExtent(const ((50, 50), (950, 950)), world)
      ..scale = 500;
    expect(projection.scale, 500);
    assertPositionInDelta(
      projection.translate,
      refWorldFit['world transverseMercator']!.$2,
    );
  });

  test('projection.fitSize(…) resampling - world mercator', () {
    const box = GeoPolygon(<List<GeoPosition>>[
      <GeoPosition>[(-135, 45), (-45, 45), (-45, -45), (-135, -45), (-135, 45)],
    ]);
    final p1 = geoMercator()
      ..precision = 0.1
      ..fitSize(const (1000, 1000), box);
    final p2 = geoMercator()
      ..precision = 0
      ..fitSize(const (1000, 1000), box);
    expect(p1.precision, 0.1);
    expect(p2.precision, 0);
    assertInDelta(p1.scale, 436.218018);
    assertInDelta(p2.scale, 567.296328);
    assertInDelta(p1.translate.$1, 1185.209661);
    assertInDelta(p2.translate.$1, 1391.106989);
    assertInDelta(p1.translate.$2, 500);
    assertInDelta(p1.translate.$2, p2.translate.$2);
  });

  test('projection.fitWidth(…) world equirectangular', () {
    final projection = geoEquirectangular()..fitWidth(900, world);
    _expectWorldFit('world fitWidth equirectangular', projection);
  });

  test('projection.fitWidth(…) world transverseMercator', () {
    final projection = geoTransverseMercator()..fitWidth(900, world);
    _expectWorldFit('world fitWidth transverseMercator', projection);
  });

  test('projection.fitWidth(…) USA albersUsa', () {
    final projection = geoAlbersUsa()..fitWidth(900, us);
    assertInDelta(projection.scale, 1152.889035);
    assertPositionInDelta(projection.translate, const (483.52541, 257.736905));
  });

  test('projection.fitHeight(…) world equirectangular', () {
    final projection = geoEquirectangular()..fitHeight(900, world);
    _expectWorldFit('world fitHeight equirectangular', projection);
  });

  test('projection.fitHeight(…) world transverseMercator', () {
    final projection = geoTransverseMercator()..fitHeight(900, world);
    _expectWorldFit('world fitHeight transverseMercator', projection);
  });

  test('projection.fitHeight(…) USA albersUsa', () {
    final projection = geoAlbersUsa()..fitHeight(900, us);
    assertInDelta(projection.scale, 1983.902059);
    assertPositionInDelta(projection.translate, const (832.054974, 443.516038));
  });
}
