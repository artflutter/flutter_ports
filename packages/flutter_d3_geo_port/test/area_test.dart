// Ported from d3-geo v3.1.1 test/area-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart' show range;
import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'asserts.dart';

GeoPolygon _stripes(double a, double b) {
  List<GeoPosition> makeRing(double lat, bool reverse) {
    final stripe = <GeoPosition>[
      for (final x in range(-180, 180, 0.1)) (x, lat),
    ];
    stripe.add(stripe[0]);
    return reverse ? stripe.reversed.toList() : stripe;
  }

  return GeoPolygon(<List<GeoPosition>>[makeRing(a, false), makeRing(b, true)]);
}

void main() {
  test('area: Point', () {
    expect(geoArea(const GeoPoint((0, 0))), 0);
  });

  test('area: MultiPoint', () {
    expect(geoArea(const GeoMultiPoint(<GeoPosition>[(0, 1), (2, 3)])), 0);
  });

  test('area: LineString', () {
    expect(geoArea(const GeoLineString(<GeoPosition>[(0, 1), (2, 3)])), 0);
  });

  test('area: MultiLineString', () {
    expect(
      geoArea(
        const GeoMultiLineString(<List<GeoPosition>>[
          <GeoPosition>[(0, 1), (2, 3)],
          <GeoPosition>[(4, 5), (6, 7)],
        ]),
      ),
      0,
    );
  });

  test('area: Polygon - tiny', () {
    assertInDelta(
      geoArea(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[
            (-64.66070178517852, 18.33986913231323),
            (-64.66079715091509, 18.33994007490749),
            (-64.66074946804680, 18.33994007490749),
            (-64.66070178517852, 18.33986913231323),
          ],
        ]),
      ),
      4.890516e-13,
      1e-13,
    );
  });

  test('area: Polygon - zero area', () {
    expect(
      geoArea(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[
            (96.79142432523281, 5.262704519048153),
            (96.81065389253769, 5.272455576551362),
            (96.82988345984256, 5.272455576551362),
            (96.81065389253769, 5.272455576551362),
            (96.79142432523281, 5.262704519048153),
          ],
        ]),
      ),
      0,
    );
  });

  test('area: Polygon - semilune', () {
    assertInDelta(
      geoArea(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, 0), (0, 90), (90, 0), (0, 0)],
        ]),
      ),
      math.pi / 2,
    );
  });

  test('area: Polygon - lune', () {
    assertInDelta(
      geoArea(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, 0), (0, 90), (90, 0), (0, -90), (0, 0)],
        ]),
      ),
      math.pi,
    );
  });

  test('area: Polygon - hemispheres North', () {
    assertInDelta(
      geoArea(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, 0), (-90, 0), (180, 0), (90, 0), (0, 0)],
        ]),
      ),
      2 * math.pi,
    );
  });

  test('area: Polygon - hemispheres South', () {
    assertInDelta(
      geoArea(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, 0), (90, 0), (180, 0), (-90, 0), (0, 0)],
        ]),
      ),
      2 * math.pi,
    );
  });

  test('area: Polygon - hemispheres East', () {
    assertInDelta(
      geoArea(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, 0), (0, 90), (180, 0), (0, -90), (0, 0)],
        ]),
      ),
      2 * math.pi,
    );
  });

  test('area: Polygon - hemispheres West', () {
    assertInDelta(
      geoArea(
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(0, 0), (0, -90), (180, 0), (0, 90), (0, 0)],
        ]),
      ),
      2 * math.pi,
    );
  });

  test('area: Polygon - graticule outline sphere', () {
    final g = geoGraticule()..extent = const ((-180, -90), (180, 90));
    assertInDelta(geoArea(g.outline()), 4 * math.pi, 1e-5);
  });

  test('area: Polygon - graticule outline hemisphere', () {
    final g = geoGraticule()..extent = const ((-180, 0), (180, 90));
    assertInDelta(geoArea(g.outline()), 2 * math.pi, 1e-5);
  });

  test('area: Polygon - graticule outline semilune', () {
    final g = geoGraticule()..extent = const ((0, 0), (90, 90));
    assertInDelta(geoArea(g.outline()), math.pi / 2, 1e-5);
  });

  test('area: Polygon - circles hemisphere', () {
    assertInDelta(geoArea(geoCircle(radius: 90)()), 2 * math.pi, 1e-5);
  });

  test('area: Polygon - circles 60°', () {
    assertInDelta(
      geoArea(geoCircle(radius: 60, precision: 0.1)()),
      math.pi,
      1e-5,
    );
  });

  test('area: Polygon - circles 60° North', () {
    assertInDelta(
      geoArea(geoCircle(radius: 60, precision: 0.1, center: const (0, 90))()),
      math.pi,
      1e-5,
    );
  });

  test('area: Polygon - circles 45°', () {
    assertInDelta(
      geoArea(geoCircle(radius: 45, precision: 0.1)()),
      math.pi * (2 - math.sqrt2),
      1e-5,
    );
  });

  test('area: Polygon - circles 45° North', () {
    assertInDelta(
      geoArea(geoCircle(radius: 45, precision: 0.1, center: const (0, 90))()),
      math.pi * (2 - math.sqrt2),
      1e-5,
    );
  });

  test('area: Polygon - circles 45° South', () {
    assertInDelta(
      geoArea(geoCircle(radius: 45, precision: 0.1, center: const (0, -90))()),
      math.pi * (2 - math.sqrt2),
      1e-5,
    );
  });

  test('area: Polygon - circles 135°', () {
    assertInDelta(
      geoArea(geoCircle(radius: 135, precision: 0.1)()),
      math.pi * (2 + math.sqrt2),
      1e-5,
    );
  });

  test('area: Polygon - circles 135° North', () {
    assertInDelta(
      geoArea(geoCircle(radius: 135, precision: 0.1, center: const (0, 90))()),
      math.pi * (2 + math.sqrt2),
      1e-5,
    );
  });

  test('area: Polygon - circles 135° South', () {
    assertInDelta(
      geoArea(geoCircle(radius: 135, precision: 0.1, center: const (0, -90))()),
      math.pi * (2 + math.sqrt2),
      1e-5,
    );
  });

  test('area: Polygon - circles tiny', () {
    assertInDelta(geoArea(geoCircle(radius: 1e-6, precision: 0.1)()), 0);
  });

  test('area: Polygon - circles huge', () {
    assertInDelta(
      geoArea(geoCircle(radius: 180 - 1e-6, precision: 0.1)()),
      4 * math.pi,
    );
  });

  test('area: Polygon - circles 60° with 45° hole', () {
    final circle = geoCircle(precision: 0.1);
    final outer = (circle..radius = 60)().coordinates[0];
    final inner = (circle..radius = 45)().coordinates[0].reversed.toList();
    assertInDelta(
      geoArea(GeoPolygon(<List<GeoPosition>>[outer, inner])),
      math.pi * (math.sqrt2 - 1),
      1e-5,
    );
  });

  test('area: Polygon - circles 45° holes at [0°, 0°] and [0°, 90°]', () {
    final circle = geoCircle(precision: 0.1, radius: 45);
    final h1 = (circle..center = const (0, 0))().coordinates[0].reversed
        .toList();
    final h2 = (circle..center = const (0, 90))().coordinates[0].reversed
        .toList();
    assertInDelta(
      geoArea(GeoPolygon(<List<GeoPosition>>[h1, h2])),
      math.pi * 2 * math.sqrt2,
      1e-5,
    );
  });

  test('area: Polygon - circles 45° holes at [0°, 90°] and [0°, 0°]', () {
    final circle = geoCircle(precision: 0.1, radius: 45);
    final h1 = (circle..center = const (0, 90))().coordinates[0].reversed
        .toList();
    final h2 = (circle..center = const (0, 0))().coordinates[0].reversed
        .toList();
    assertInDelta(
      geoArea(GeoPolygon(<List<GeoPosition>>[h1, h2])),
      math.pi * 2 * math.sqrt2,
      1e-5,
    );
  });

  test('area: Polygon - stripes 45°, -45°', () {
    assertInDelta(geoArea(_stripes(45, -45)), math.pi * 2 * math.sqrt2, 1e-5);
  });

  test('area: Polygon - stripes -45°, 45°', () {
    assertInDelta(
      geoArea(_stripes(-45, 45)),
      math.pi * 2 * (2 - math.sqrt2),
      1e-5,
    );
  });

  test('area: Polygon - stripes 45°, 30°', () {
    assertInDelta(geoArea(_stripes(45, 30)), math.pi * (math.sqrt2 - 1), 1e-5);
  });

  test('area: MultiPolygon two hemispheres', () {
    expect(
      geoArea(
        const GeoMultiPolygon(<List<List<GeoPosition>>>[
          <List<GeoPosition>>[
            <GeoPosition>[(0, 0), (-90, 0), (180, 0), (90, 0), (0, 0)],
          ],
          <List<GeoPosition>>[
            <GeoPosition>[(0, 0), (90, 0), (180, 0), (-90, 0), (0, 0)],
          ],
        ]),
      ),
      4 * math.pi,
    );
  });

  test('area: Sphere', () {
    expect(geoArea(const GeoSphere()), 4 * math.pi);
  });

  test('area: GeometryCollection', () {
    expect(
      geoArea(const GeoGeometryCollection(<GeoGeometry?>[GeoSphere()])),
      4 * math.pi,
    );
  });

  test('area: FeatureCollection', () {
    expect(
      geoArea(
        const GeoFeatureCollection<void>(<GeoFeature<void>>[
          GeoFeature<void>(geometry: GeoSphere()),
        ]),
      ),
      4 * math.pi,
    );
  });

  test('area: Feature', () {
    expect(geoArea(const GeoFeature<void>(geometry: GeoSphere())), 4 * math.pi);
  });
}
