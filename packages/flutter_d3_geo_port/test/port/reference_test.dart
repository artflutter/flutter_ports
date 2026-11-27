// Original code, not ported from d3-geo: Node.js v3.1.1 reference parity tests.

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import '../asserts.dart';
import '../data/us_land_data.dart';
import '../data/world_land_data.dart';
import 'd3_geo_reference.dart';

void main() {
  group('Node.js v3.1.1 projection parity', () {
    final factories = <String, GeoProjector Function()>{
      'albers': geoAlbers,
      'albersUsa': geoAlbersUsa,
      'azimuthalEqualArea': geoAzimuthalEqualArea,
      'azimuthalEquidistant': geoAzimuthalEquidistant,
      'conicConformal': geoConicConformal,
      'conicEqualArea': geoConicEqualArea,
      'conicEquidistant': geoConicEquidistant,
      'equalEarth': geoEqualEarth,
      'equirectangular': geoEquirectangular,
      'gnomonic': geoGnomonic,
      'mercator': geoMercator,
      'naturalEarth1': geoNaturalEarth1,
      'orthographic': () => geoOrthographic()..rotate = const (-10, -20, 5),
      'stereographic': geoStereographic,
      'transverseMercator': geoTransverseMercator,
    };

    for (final entry in factories.entries) {
      test('${entry.key} matches Node.js forward & inverse', () {
        final p = entry.value();
        final expected = refProjections[entry.key]!;
        for (var i = 0; i < refTestPoints.length; ++i) {
          final pt = refTestPoints[i];
          final (expFwd, expInv) = expected[i];
          final actFwd = p(pt);
          if (expFwd == null) {
            expect(actFwd, isNull);
          } else {
            expect(actFwd, isNotNull);
            assertPositionInDelta(actFwd!, expFwd);
            final actInv = p.invert(actFwd);
            expect(actInv, isNotNull);
            assertPositionInDelta(actInv!, expInv!);
          }
        }
      });
    }
  });

  group('Node.js v3.1.1 spherical & SVG parity', () {
    test('world & US spherical area, bounds, centroid, length', () {
      assertInDelta(geoArea(worldLandFeature), refWorldArea, 1e-9);
      assertExtentInDelta(geoBounds(worldLandFeature), refWorldBounds, 1e-9);
      assertPositionInDelta(
        geoCentroid(worldLandFeature),
        refWorldCentroid,
        1e-9,
      );
      assertInDelta(geoLength(worldLandFeature), refWorldLength, 1e-9);

      assertInDelta(geoArea(usLandFeature), refUsArea, 1e-9);
      assertExtentInDelta(geoBounds(usLandFeature), refUsBounds, 1e-9);
      assertPositionInDelta(geoCentroid(usLandFeature), refUsCentroid, 1e-9);
    });

    test('distance & interpolate match Node.js', () {
      const london = (-0.1276, 51.5072);
      const tokyo = (139.6917, 35.6895);
      assertInDelta(geoDistance(london, tokyo), refLondonTokyoDist, 1e-12);
      final interp = geoInterpolate(london, tokyo);
      assertInDelta(interp.distance, refLondonTokyoDist, 1e-12);
      assertPositionInDelta(interp(0.5), refLondonTokyoMid, 1e-9);
    });

    test('SVG path output matches Node.js', () {
      final neSvg = (geoPath(geoNaturalEarth1())..digits = 2)(worldLandFeature);
      assertPathEqual(neSvg, refWorldNaturalEarthSvg);

      final orthoSvg = (geoPath(geoOrthographic()..rotate = const (-10, -20, 0))
        ..digits = 2)(worldLandFeature);
      assertPathEqual(orthoSvg, refWorldOrthoSvg);

      final grat = geoGraticule()..step = const (30, 30);
      final gratSvg = (geoPath(geoMercator())..digits = 1)(grat());
      assertPathEqual(gratSvg, refGrat10MercatorSvg);
    });
  });

  group('Typed native Dart APIs', () {
    test('GeoJsonObject fromJson/toJson round-trip', () {
      const sample = GeoFeatureCollection<Map<String, Object?>>(
        <GeoFeature<Map<String, Object?>>>[
          GeoFeature<Map<String, Object?>>(
            id: 'f1',
            geometry: GeoPoint((10, 20), elevation: 30),
            properties: <String, Object?>{'name': 'alpha'},
          ),
          GeoFeature<Map<String, Object?>>(
            geometry: GeoPolygon(<List<GeoPosition>>[
              <GeoPosition>[(0, 0), (0, 10), (10, 10), (10, 0), (0, 0)],
            ]),
          ),
          GeoFeature<Map<String, Object?>>(
            geometry: GeoGeometryCollection(<GeoGeometry?>[
              GeoSphere(),
              GeoLineString(<GeoPosition>[(0, 0), (5, 5)]),
              null,
            ]),
          ),
        ],
      );
      final json = sample.toJson();
      final decoded = GeoJsonObject.fromJson(json);
      expect(decoded, isA<GeoFeatureCollection<Map<String, Object?>>>());
      expect(decoded.toJson(), json);
    });

    test('geoTransform custom stream transform', () {
      final flipY = geoTransform(
        point: (stream, x, y, [z]) => stream.point(x * 2, -y),
      );
      final path = geoPath(flipY);
      expect(
        path(const GeoLineString(<GeoPosition>[(1, 2), (3, 4)])),
        'M2,-2L6,-4',
      );
    });

    test('geoClipExtent clips to extent', () {
      final clip = geoClipExtent()..extent = const ((0, 0), (10, 10));
      final path = geoPath(clip);
      expect(
        path(const GeoLineString(<GeoPosition>[(-5, 5), (15, 5)])),
        'M0,5L10,5',
      );
    });

    test('geoProjectionMutator updates raw projection cleanly', () {
      final mutate = geoProjectionMutator<double>(
        (factor) => geoRawProjection(
          (x, y) => (x * factor, y),
          invert: (x, y) => (x / factor, y),
        ),
      );
      final p = mutate(2)
        ..scale = 1
        ..translate = const (0, 0);
      assertPositionInDelta(p(const (180, 0))!, const (2 * geoPi, 0));
      mutate(3);
      assertPositionInDelta(p(const (180, 0))!, const (3 * geoPi, 0));
    });

    test('geoCircleBy datum-driven generator and pointRadiusAccessor', () {
      final gen = geoCircleBy<(GeoPosition, double)>(
        centerAccessor: (d) => d.$1,
        radiusAccessor: (d) => d.$2,
      );
      final poly = gen((const (10, 20), 15));
      assertPositionInDelta(geoCentroid(poly), const (10, 20), 1e-4);

      final path = geoPath()
        ..pointRadiusAccessor = (obj) => obj is GeoPoint ? 8 : 3;
      expect(
        path(const GeoPoint((10, 20))),
        'M10,20m0,8a8,8 0 1,1 0,-16a8,8 0 1,1 0,16z',
      );
    });
  });
}
