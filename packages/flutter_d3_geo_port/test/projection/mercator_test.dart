// Ported from d3-geo v3.1.1 test/projection/mercator-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('mercator.clipExtent(null) sets the default automatic clip extent', () {
    final projection = geoMercator()
      ..translate = const (0, 0)
      ..scale = 1
      ..clipExtent = null
      ..precision = 0;
    assertPathEqual(
      geoPath(projection)(const GeoSphere()),
      'M3.141593,-3.141593L3.141593,0L3.141593,3.141593L3.141593,3.141593L-3.141593,3.141593L-3.141593,3.141593L-3.141593,0L-3.141593,-3.141593L-3.141593,-3.141593L3.141593,-3.141593Z',
    );
    expect(projection.clipExtent, isNull);
  });

  test('mercator.center(center) sets the correct automatic clip extent', () {
    final projection = geoMercator()
      ..translate = const (0, 0)
      ..scale = 1
      ..center = const (10, 10)
      ..precision = 0;
    assertPathEqual(
      geoPath(projection)(const GeoSphere()),
      'M2.967060,-2.966167L2.967060,0.175426L2.967060,3.317018L2.967060,3.317018L-3.316126,3.317018L-3.316126,3.317019L-3.316126,0.175426L-3.316126,-2.966167L-3.316126,-2.966167L2.967060,-2.966167Z',
    );
    expect(projection.clipExtent, isNull);
  });

  test('mercator.clipExtent(extent) intersects the specified clip extent with the automatic clip extent', () {
    final projection = geoMercator()
      ..translate = const (0, 0)
      ..scale = 1
      ..clipExtent = const ((-10, -10), (10, 10))
      ..precision = 0;
    assertPathEqual(
      geoPath(projection)(const GeoSphere()),
      'M3.141593,-10L3.141593,0L3.141593,10L3.141593,10L-3.141593,10L-3.141593,10L-3.141593,0L-3.141593,-10L-3.141593,-10L3.141593,-10Z',
    );
    expect(projection.clipExtent, const ((-10.0, -10.0), (10.0, 10.0)));
  });

  test('mercator.clipExtent(extent).scale(scale) updates the intersected clip extent', () {
    final projection = geoMercator()
      ..translate = const (0, 0)
      ..clipExtent = const ((-10, -10), (10, 10))
      ..scale = 1
      ..precision = 0;
    assertPathEqual(
      geoPath(projection)(const GeoSphere()),
      'M3.141593,-10L3.141593,0L3.141593,10L3.141593,10L-3.141593,10L-3.141593,10L-3.141593,0L-3.141593,-10L-3.141593,-10L3.141593,-10Z',
    );
    expect(projection.clipExtent, const ((-10.0, -10.0), (10.0, 10.0)));
  });

  test('mercator.clipExtent(extent).translate(translate) updates the intersected clip extent', () {
    final projection = geoMercator()
      ..scale = 1
      ..clipExtent = const ((-10, -10), (10, 10))
      ..translate = const (0, 0)
      ..precision = 0;
    assertPathEqual(
      geoPath(projection)(const GeoSphere()),
      'M3.141593,-10L3.141593,0L3.141593,10L3.141593,10L-3.141593,10L-3.141593,10L-3.141593,0L-3.141593,-10L-3.141593,-10L3.141593,-10Z',
    );
    expect(projection.clipExtent, const ((-10.0, -10.0), (10.0, 10.0)));
  });

  test('mercator.rotate(…) does not affect the automatic clip extent', () {
    final projection = geoMercator();
    const object = GeoMultiPoint(<GeoPosition>[
      (-82.35024908550241, 29.649391549778745),
      (-82.35014449996858, 29.65075946917633),
      (-82.34916073446641, 29.65070265688781),
      (-82.3492653331286, 29.64933474064504),
    ]);
    projection.fitExtent(const ((0, 0), (960, 600)), object);
    assertInDelta(projection.scale, 20969742.365692537, 1e-4);
    assertPositionInDelta(projection.translate, const (
      30139734.76760269,
      11371473.949706702,
    ), 1e-4);
    projection
      ..rotate = const (0, 95, 0)
      ..fitExtent(const ((0, 0), (960, 600)), object);
    assertInDelta(projection.scale, 35781690.650920525, 1e-4);
    assertPositionInDelta(projection.translate, const (
      75115911.95344563,
      2586046.4116968135,
    ), 1e-4);
  });
}
