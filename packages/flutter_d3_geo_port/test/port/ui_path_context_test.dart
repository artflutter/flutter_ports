// Original code, not ported from d3-geo: Flutter UiPathContext rendering tests.

import 'dart:ui' as ui;

import 'package:flutter_d3_geo_port/flutter_d3_geo_port.dart';
import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';
import 'package:test/test.dart';

import '../asserts.dart';
import '../data/world_land_data.dart';

void main() {
  test(
    'GeoPathUi.toUiPath builds non-empty dart:ui.Path for world & sphere',
    () {
      final proj = geoOrthographic()
        ..scale = 200
        ..translate = const (250, 250)
        ..rotate = const (-10, -25, 0);
      final pathGen = geoPath(proj);

      final spherePath = pathGen.toUiPath(const GeoSphere());
      final sphereBounds = spherePath.getBounds();
      assertInDelta(sphereBounds.left, 50, 1);
      assertInDelta(sphereBounds.top, 50, 1);
      assertInDelta(sphereBounds.right, 450, 1);
      assertInDelta(sphereBounds.bottom, 450, 1);

      final landPath = pathGen.toUiPath(worldLandFeature);
      final landBounds = landPath.getBounds();
      expect(landBounds.isEmpty, isFalse);
      expect(landBounds.left, greaterThanOrEqualTo(49));
      expect(landBounds.right, lessThanOrEqualTo(451));
    },
  );

  test('GeoPathUi.drawToUiPath reuses UiPathContext cleanly across frames', () {
    final proj = geoNaturalEarth1()
      ..fitSize(const (800, 420), const GeoSphere());
    final pathGen = geoPath(proj);
    final ctx = uiPathContext();

    pathGen.drawToUiPath(geoGraticule10(), ctx);
    final gratBounds = ctx.path.getBounds();
    expect(gratBounds.isEmpty, isFalse);

    ctx.reset();
    pathGen.drawToUiPath(const GeoPoint((0, 0)), ctx);
    final ptBounds = ctx.path.getBounds();
    expect(ptBounds.width, closeTo(9, 0.5));
    expect(ptBounds.height, closeTo(9, 0.5));

    // Verify draw() does not mutate GeoPath.context.
    expect(pathGen.context, isNull);
  });

  test('UiPathContext renders projected circle and great-circle route', () {
    final proj = geoMercator()
      ..scale = 120
      ..translate = const (400, 300);
    final pathGen = geoPath(proj);
    final ctx = UiPathContext(ui.Path());

    final circle = geoCircle(center: const (-0.1276, 51.5072), radius: 15)();
    pathGen.drawToUiPath(circle, ctx);
    expect(ctx.path.getBounds().isEmpty, isFalse);

    final interp = geoInterpolate(
      const (-0.1276, 51.5072),
      const (139.6917, 35.6895),
    );
    final route = GeoLineString(<GeoPosition>[
      for (var i = 0; i <= 32; ++i) interp(i / 32),
    ]);
    ctx.reset();
    pathGen.drawToUiPath(route, ctx);
    expect(ctx.path.getBounds().width, greaterThan(100));
  });
}
