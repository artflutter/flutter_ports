// Original code, not ported from d3-geo: twin tests for faster forms.
// Verifies row adapt-geo-fast-forms against literal upstream algorithms.

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:test/test.dart';

import '../asserts.dart';
import '../data/us_land_data.dart';
import '../data/world_land_data.dart';

double _literalDistance(GeoPosition a, GeoPosition b) =>
    geoLength(GeoLineString(<GeoPosition>[a, b]));

double _literalArea(GeoJsonObject object) {
  final s = GeoAreaStream();
  geoStream(object, s);
  return s.result();
}

GeoPosition _pointRad(GeoPosition p) => (p.$1 * geoRadians, p.$2 * geoRadians);

bool _literalContainsPolygon(List<List<GeoPosition>> rings, GeoPosition pt) {
  final radRings = <List<GeoPosition>>[
    for (final ring in rings)
      <GeoPosition>[
        for (var i = 0; i < ring.length - 1; ++i) _pointRad(ring[i]),
      ],
  ];
  return geoPolygonContains(radRings, _pointRad(pt));
}

void main() {
  test('geoDistance fast form matches geoLength(GeoLineString)', () {
    const pts = <GeoPosition>[
      (0, 0),
      (10, 20),
      (-122.4194, 37.7749),
      (139.6917, 35.6895),
      (180, 0),
      (-180, 0),
      (0, 90),
      (0, -90),
      (45.123, -67.891),
    ];
    for (final a in pts) {
      for (final b in pts) {
        assertInDelta(geoDistance(a, b), _literalDistance(a, b), 1e-12);
      }
    }
  });

  test('geoArea direct fast path matches GeoAreaStream', () {
    assertInDelta(
      geoArea(worldLandFeature),
      _literalArea(worldLandFeature),
      1e-12,
    );
    assertInDelta(geoArea(usLandFeature), _literalArea(usLandFeature), 1e-12);
    assertInDelta(
      geoArea(const GeoSphere()),
      _literalArea(const GeoSphere()),
      1e-12,
    );
    final circle = geoCircle(
      center: const (10, 20),
      radius: 35,
      precision: 2,
    )();
    assertInDelta(geoArea(circle), _literalArea(circle), 1e-12);
  });

  test(
    'geoPolygonContainsDegrees matches radian-copied geoPolygonContains',
    () {
      final outer = geoCircle(
        center: const (10, 20),
        radius: 35,
        precision: 2,
      )().coordinates[0];
      final inner = geoCircle(
        center: const (10, 20),
        radius: 10,
        precision: 6,
      )().coordinates[0].reversed.toList();
      final poly = GeoPolygon(<List<GeoPosition>>[outer, inner]);
      var s = 12345;
      for (var i = 0; i < 200; ++i) {
        s = (s * 48271) % 0x7fffffff;
        final lon = -60.0 + (s / 0x7fffffff) * 140.0;
        s = (s * 48271) % 0x7fffffff;
        final lat = -40.0 + (s / 0x7fffffff) * 120.0;
        final pt = (lon, lat);
        expect(
          geoContains(poly, pt),
          equals(_literalContainsPolygon(poly.coordinates, pt)),
        );
      }
    },
  );

  test('fused projection call & resample match generic GeoRawProjectionFn', () {
    final builtIns = <(String, GeoProjection Function(), GeoRawProjection)>[
      ('orthographic', geoOrthographic, geoOrthographicRaw),
      ('mercator', geoMercator, geoMercatorRaw),
      ('equalEarth', geoEqualEarth, geoEqualEarthRaw),
      ('naturalEarth1', geoNaturalEarth1, geoNaturalEarth1Raw),
      (
        'albers',
        geoAlbers,
        geoConicEqualAreaRaw(29.5 * geoRadians, 45.5 * geoRadians),
      ),
    ];
    final grat = geoGraticule10();
    for (final (name, makeFast, raw) in builtIns) {
      final fast = makeFast()
        ..rotate = const (-15, -20, 7)
        ..angle = 12;
      final genericRaw = geoRawProjection(raw.call, invert: raw.invert);
      final slow = name == 'mercator'
          ? (geoMercatorProjection(genericRaw)
              ..scale = fast.scale
              ..translate = fast.translate
              ..center = fast.center
              ..rotate = fast.rotate
              ..angle = fast.angle
              ..clipAngle = fast.clipAngle
              ..clipExtent = fast.clipExtent
              ..precision = fast.precision)
          : (geoProjection(genericRaw)
              ..scale = fast.scale
              ..translate = fast.translate
              ..center = fast.center
              ..rotate = fast.rotate
              ..angle = fast.angle
              ..clipAngle = fast.clipAngle
              ..clipExtent = fast.clipExtent
              ..precision = fast.precision);

      for (var lon = -160.0; lon <= 160.0; lon += 40.0) {
        for (var lat = -70.0; lat <= 70.0; lat += 35.0) {
          final fp = fast((lon, lat));
          final sp = slow((lon, lat));
          if (fp == null || sp == null) {
            expect(fp, equals(sp), reason: name);
          } else {
            assertPositionInDelta(fp, sp, 1e-10);
          }
        }
      }
      assertInDelta(
        geoPath(fast).area(worldLandFeature),
        geoPath(slow).area(worldLandFeature),
      );
      assertInDelta(geoPath(fast).measure(grat), geoPath(slow).measure(grat));
    }
  });

  test('geoAlbersUsa fast clipped call matches stream projection', () {
    final usa = geoAlbersUsa();
    const pts = <GeoPosition>[
      (-122.4194, 37.7749),
      (-74.006, 40.7128),
      (-149.9003, 61.2181),
      (-157.8583, 21.3069),
      (2.3522, 48.8566),
      (-100, 40),
    ];
    for (final pt in pts) {
      GeoPosition? streamed;
      final sink = GeoStreamCallbacks(point: (x, y, [z]) => streamed = (x, y));
      usa.stream(sink).point(pt.$1, pt.$2);
      final fast = usa(pt);
      if (streamed == null) {
        expect(fast, isNull);
      } else {
        expect(fast, isNotNull);
        assertPositionInDelta(fast!, streamed!, 1e-10);
      }
    }
  });

  test('GeoPathString fast byte emitter matches digits=null/0/2/3/6', () {
    final proj = geoNaturalEarth1();
    for (final digits in <int?>[0, 1, 2, 3, 6, 12, null]) {
      final pathGen = geoPath(proj)..digits = digits;
      final svg = pathGen(worldLandFeature);
      expect(svg, isNotNull);
      expect(svg, startsWith('M'));
      expect(svg, contains('Z'));
      // Verify no ".0," or "-0," artifacts
      expect(svg, isNot(contains('.0,')));
      expect(svg, isNot(contains('-0,')));
      expect(svg, isNot(contains('-0L')));
      expect(svg, isNot(contains('-0M')));
      expect(svg, isNot(contains('-0Z')));
    }
    // Check negative half-way tie-breaking matches JS Math.round
    final p0 = geoPath()..digits = 0;
    expect(
      p0(const GeoLineString(<GeoPosition>[(-0.5, 0.5), (-1.5, 1.5)])),
      'M0,1L-1,2',
    );
    final p1 = geoPath()..digits = 1;
    expect(
      p1(const GeoLineString(<GeoPosition>[(-0.05, 0.05), (-1.25, 1.25)])),
      'M0,0.1L-1.2,1.3',
    );
  });

  test('GeoPath.draw caches target sink and matches context=target', () {
    final proj = geoOrthographic()..rotate = const (-20, -30, 0);
    final pDraw = geoPath(proj);
    final pCtx = geoPath(proj);
    final outA = pathRound();
    final outB = pathRound();
    pCtx.context = outB;

    // Call twice on the same target to exercise cached GeoPathContext.
    pDraw.draw(worldLandFeature, outA);
    pCtx(worldLandFeature);
    expect(outA.toString(), equals(outB.toString()));

    final outA2 = pathRound();
    final outB2 = pathRound();
    pCtx.context = outB2;
    pDraw.draw(worldLandFeature, outA2);
    pCtx(worldLandFeature);
    expect(outA2.toString(), equals(outB2.toString()));
  });

  test('geoClipCircle unboxed intersections match gnomonic snapshot', () {
    final g = geoGnomonic()..precision = 0.1;
    final grat = geoGraticule10();
    final m = geoPath(g).measure(grat);
    assertInDelta(m, 10023.39369546447, 1e-3);
    expect(math.cos(60 * geoRadians), closeTo(0.5, 1e-12));
  });
}
