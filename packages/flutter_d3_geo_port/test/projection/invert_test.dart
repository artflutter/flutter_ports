// Ported from d3-geo v3.1.1 test/projection/invert-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  final factories = <(String, GeoProjector Function())>[
    ('geoAlbers', geoAlbers),
    ('geoAzimuthalEqualArea', geoAzimuthalEqualArea),
    ('geoAzimuthalEquidistant', geoAzimuthalEquidistant),
    ('geoConicConformal', geoConicConformal),
    (
      'conicConformal [20, 30]',
      () => geoConicConformal()..parallels = const (20, 30),
    ),
    (
      'conicConformal [30, 30]',
      () => geoConicConformal()..parallels = const (30, 30),
    ),
    (
      'conicConformal [-35, -50]',
      () => geoConicConformal()..parallels = const (-35, -50),
    ),
    (
      'conicConformal [40, 60] rotate',
      () => geoConicConformal()
        ..parallels = const (40, 60)
        ..rotate = const (-120, 0, 0),
    ),
    ('geoConicEqualArea', geoConicEqualArea),
    (
      'conicEqualArea [20, 30]',
      () => geoConicEqualArea()..parallels = const (20, 30),
    ),
    (
      'conicEqualArea [-30, 30]',
      () => geoConicEqualArea()..parallels = const (-30, 30),
    ),
    (
      'conicEqualArea [-35, -50]',
      () => geoConicEqualArea()..parallels = const (-35, -50),
    ),
    (
      'conicEqualArea [40, 60] rotate',
      () => geoConicEqualArea()
        ..parallels = const (40, 60)
        ..rotate = const (-120, 0, 0),
    ),
    ('geoConicEquidistant', geoConicEquidistant),
    (
      'conicEquidistant [20, 30]',
      () => geoConicEquidistant()..parallels = const (20, 30),
    ),
    (
      'conicEquidistant [30, 30]',
      () => geoConicEquidistant()..parallels = const (30, 30),
    ),
    (
      'conicEquidistant [-35, -50]',
      () => geoConicEquidistant()..parallels = const (-35, -50),
    ),
    (
      'conicEquidistant [40, 60] rotate',
      () => geoConicEquidistant()
        ..parallels = const (40, 60)
        ..rotate = const (-120, 0, 0),
    ),
    ('geoEquirectangular', geoEquirectangular),
    ('geoEqualEarth', geoEqualEarth),
    ('geoGnomonic', geoGnomonic),
    ('geoMercator', geoMercator),
    ('geoOrthographic', geoOrthographic),
    ('geoStereographic', geoStereographic),
    ('geoTransverseMercator', geoTransverseMercator),
  ];

  for (final (name, factory) in factories) {
    final projection = factory();
    test('$name(point) and $name.invert(point) are symmetric', () {
      for (final point in const <GeoPosition>[
        (0, 0),
        (30.3, 24.1),
        (-10, 42),
        (-2, -5),
      ]) {
        assertProjectionEqual(projection, point, projection(point)!);
      }
    });
  }

  test('albersUsa(point) and albersUsa.invert(point) are symmetric', () {
    final projection = geoAlbersUsa();
    for (final point in const <GeoPosition>[
      (-122.4194, 37.7749),
      (-74.0059, 40.7128),
      (-149.9003, 61.2181),
      (-157.8583, 21.3069),
    ]) {
      assertProjectionEqual(projection, point, projection(point)!);
    }
  });
}
