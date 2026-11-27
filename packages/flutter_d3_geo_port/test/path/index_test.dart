// Ported from d3-geo v3.1.1 test/path/index-test.js (ISC, Mike Bostock).
// Upstream test titles exceed 80 chars.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:math' as math;

import 'package:flutter_d3_geo_port/d3_geo.dart';
import 'package:test/test.dart';

import 'test_context.dart';

final GeoProjection _equirectangular = geoEquirectangular()
  ..scale = 900 / math.pi
  ..precision = 0;

List<TestPathOp> _testPath(GeoStreamable? projection, GeoJsonObject object) {
  final context = testContext();
  (geoPath()
    ..projection = projection
    ..context = context)(object);
  return context.result();
}

void main() {
  test('geoPath.projection() defaults to null', () {
    expect(geoPath().projection, isNull);
  });

  test('geoPath.context() defaults to null', () {
    expect(geoPath().context, isNull);
  });

  test('geoPath(projection) sets the initial projection', () {
    final projection = geoAlbers();
    final path = geoPath(projection);
    expect(path.projection, same(projection));
  });

  test(
    'geoPath(projection, context) sets the initial projection and context',
    () {
      final context = testContext();
      final projection = geoAlbers();
      final path = geoPath(projection, context);
      expect(path.projection, same(projection));
      expect(path.context, same(context));
    },
  );

  test('geoPath(Point) renders a point', () {
    expect(_testPath(_equirectangular, const GeoPoint((-63, 18))), const [
      TestMoveTo(170, 160),
      TestArc(165, 160, 4.5),
    ]);
  });

  test('geoPath(MultiPoint) renders a point', () {
    expect(
      _testPath(
        _equirectangular,
        const GeoMultiPoint(<GeoPosition>[(-63, 18), (-62, 18), (-62, 17)]),
      ),
      const [
        TestMoveTo(170, 160),
        TestArc(165, 160, 4.5),
        TestMoveTo(175, 160),
        TestArc(170, 160, 4.5),
        TestMoveTo(175, 165),
        TestArc(170, 165, 4.5),
      ],
    );
  });

  test('geoPath(LineString) renders a line string', () {
    expect(
      _testPath(
        _equirectangular,
        const GeoLineString(<GeoPosition>[(-63, 18), (-62, 18), (-62, 17)]),
      ),
      const [TestMoveTo(165, 160), TestLineTo(170, 160), TestLineTo(170, 165)],
    );
  });

  test('geoPath(Polygon) renders a polygon', () {
    expect(
      _testPath(
        _equirectangular,
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(-63, 18), (-62, 18), (-62, 17), (-63, 18)],
        ]),
      ),
      const [
        TestMoveTo(165, 160),
        TestLineTo(170, 160),
        TestLineTo(170, 165),
        TestClosePath(),
      ],
    );
  });

  test('geoPath(GeometryCollection) renders a geometry collection', () {
    expect(
      _testPath(
        _equirectangular,
        const GeoGeometryCollection(<GeoGeometry?>[
          GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(-63, 18), (-62, 18), (-62, 17), (-63, 18)],
          ]),
        ]),
      ),
      const [
        TestMoveTo(165, 160),
        TestLineTo(170, 160),
        TestLineTo(170, 165),
        TestClosePath(),
      ],
    );
  });

  test('geoPath(Feature) renders a feature', () {
    expect(
      _testPath(
        _equirectangular,
        const GeoFeature<void>(
          geometry: GeoPolygon(<List<GeoPosition>>[
            <GeoPosition>[(-63, 18), (-62, 18), (-62, 17), (-63, 18)],
          ]),
        ),
      ),
      const [
        TestMoveTo(165, 160),
        TestLineTo(170, 160),
        TestLineTo(170, 165),
        TestClosePath(),
      ],
    );
  });

  test('geoPath(FeatureCollection) renders a feature collection', () {
    expect(
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
      const [
        TestMoveTo(165, 160),
        TestLineTo(170, 160),
        TestLineTo(170, 165),
        TestClosePath(),
      ],
    );
  });

  test('geoPath(…) wraps longitudes outside of ±180°', () {
    expect(_testPath(_equirectangular, const GeoPoint((180 + 1e-6, 0))), const [
      TestMoveTo(-415, 250),
      TestArc(-420, 250, 4.5),
    ]);
  });

  test('geoPath(…) observes the correct winding order of a tiny polygon', () {
    expect(
      _testPath(
        _equirectangular,
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[
            (-0.06904102953339501, 0.346043661846373),
            (-6.725674252975136e-15, 0.3981303360336475),
            (-6.742247658534323e-15, -0.08812465346531581),
            (-0.17301258217724075, -0.12278150669440671),
            (-0.06904102953339501, 0.346043661846373),
          ],
        ]),
      ),
      const [
        TestMoveTo(480, 248),
        TestLineTo(480, 248),
        TestLineTo(480, 250),
        TestLineTo(479, 251),
        TestClosePath(),
      ],
    );
  });

  test('geoPath.projection(null)(…) does not transform coordinates', () {
    expect(
      _testPath(
        null,
        const GeoPolygon(<List<GeoPosition>>[
          <GeoPosition>[(-63, 18), (-62, 18), (-62, 17), (-63, 18)],
        ]),
      ),
      const [
        TestMoveTo(-63, 18),
        TestLineTo(-62, 18),
        TestLineTo(-62, 17),
        TestClosePath(),
      ],
    );
  });

  test('geoPath.context(null)(null) returns null', () {
    final path = geoPath();
    expect(path(), isNull);
    GeoJsonObject? empty;
    expect(path(empty), isNull);
  });

  // DIVERGES(d3-geo): adapt-geo-typed-api, sealed GeoJsonObject rejects
  // unknown type strings at compile time.
  test(
    'geoPath.context(null)(Unknown) returns null',
    () {},
    skip: 'diverges: adapt-geo-typed-api',
  );

  test('geoPath(LineString) then geoPath(Point) does not treat the point as part of a line', () {
    final context = testContext();
    final path = geoPath()
      ..projection = _equirectangular
      ..context = context;
    path(const GeoLineString(<GeoPosition>[(-63, 18), (-62, 18), (-62, 17)]));
    expect(context.result(), const [
      TestMoveTo(165, 160),
      TestLineTo(170, 160),
      TestLineTo(170, 165),
    ]);
    path(const GeoPoint((-63, 18)));
    expect(context.result(), const [
      TestMoveTo(170, 160),
      TestArc(165, 160, 4.5),
    ]);
  });

  test('geoPath.digits() defaults to three', () {
    expect(geoPath().digits, 3);
  });

  test('geoPath.digits(digits) returns the current path after setting the digits option', () {
    final path = geoPath()..digits = 4;
    expect(path.digits, 4);
    path.digits = 0;
    expect(path.digits, 0);
    expect(geoPath().digits, 3);
  });

  test('geoPath.digits(nullish) sets digits to null', () {
    final path = geoPath()..digits = null;
    expect(path.digits, isNull);
  });

  // DIVERGES(d3-geo): adapt-geo-typed-api, digits is typed int? (no float
  // flooring or string coercion).
  test(
    'geoPath.digits(digits) floors and coerces digits if not nullish',
    () {},
    skip: 'diverges: adapt-geo-typed-api',
  );

  test('geoPath.digits(digits) throws if digits is not valid', () {
    final path = geoPath();
    expect(() => path.digits = -1, throwsRangeError);
  });

  test('path(object) respects the specified digits', () {
    const line = GeoLineString(<GeoPosition>[
      (math.pi, math.e),
      (math.e, math.pi),
    ]);
    expect((geoPath()..digits = 0)(line), 'M3,3L3,3');
    expect((geoPath()..digits = 1)(line), 'M3.1,2.7L2.7,3.1');
    expect((geoPath()..digits = 2)(line), 'M3.14,2.72L2.72,3.14');
    expect((geoPath()..digits = 3)(line), 'M3.142,2.718L2.718,3.142');
    expect((geoPath()..digits = 4)(line), 'M3.1416,2.7183L2.7183,3.1416');
    expect((geoPath()..digits = 5)(line), 'M3.14159,2.71828L2.71828,3.14159');
    expect(
      (geoPath()..digits = 6)(line),
      'M3.141593,2.718282L2.718282,3.141593',
    );
    expect(
      (geoPath()..digits = 40)(line),
      'M3.141592653589793,2.718281828459045L2.718281828459045,3.141592653589793',
    );
    expect(
      (geoPath()..digits = null)(line),
      'M3.141592653589793,2.718281828459045L2.718281828459045,3.141592653589793',
    );
  });

  test('path(object) handles variable-radius points with different digits', () {
    final p1 = geoPath()..digits = 1;
    final p2 = geoPath()..digits = 2;
    const point = GeoPoint((math.pi, math.e));
    expect(
      (p1..pointRadius = 1)(point),
      'M3.1,2.7m0,1a1,1 0 1,1 0,-2a1,1 0 1,1 0,2z',
    );
    expect(p1(point), 'M3.1,2.7m0,1a1,1 0 1,1 0,-2a1,1 0 1,1 0,2z');
    expect(
      (p1..pointRadius = 2)(point),
      'M3.1,2.7m0,2a2,2 0 1,1 0,-4a2,2 0 1,1 0,4z',
    );
    expect(p1(point), 'M3.1,2.7m0,2a2,2 0 1,1 0,-4a2,2 0 1,1 0,4z');
    expect(
      (p2..pointRadius = 1)(point),
      'M3.14,2.72m0,1a1,1 0 1,1 0,-2a1,1 0 1,1 0,2z',
    );
    expect(p2(point), 'M3.14,2.72m0,1a1,1 0 1,1 0,-2a1,1 0 1,1 0,2z');
    expect(p1(point), 'M3.1,2.7m0,2a2,2 0 1,1 0,-4a2,2 0 1,1 0,4z');
    expect(
      (p2..pointRadius = 2)(point),
      'M3.14,2.72m0,2a2,2 0 1,1 0,-4a2,2 0 1,1 0,4z',
    );
    expect(p2(point), 'M3.14,2.72m0,2a2,2 0 1,1 0,-4a2,2 0 1,1 0,4z');
    expect(p1(point), 'M3.1,2.7m0,2a2,2 0 1,1 0,-4a2,2 0 1,1 0,4z');
  });
}
