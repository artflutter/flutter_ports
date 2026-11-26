// Original code, not ported from d3-shape: direct UiPathContext tests.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';
import 'package:flutter_d3_shape_port/flutter_d3_shape_port.dart';
import 'package:test/test.dart';

void main() {
  test('arc draws directly to UiPathContext with non-empty bounds', () {
    final ctx = uiPathContext();
    final gen = arc<PieArc<double>>(
      innerRadius: 40,
      outerRadius: 100,
      cornerRadius: 8,
    )..context = ctx;
    final slices = pie<double>(padAngle: 0.04)([30, 50, 20]);
    for (final s in slices) {
      expect(gen(s), isNull);
    }
    final bounds = ctx.path.getBounds();
    expect(bounds.width, inInclusiveRange(190, 230));
    expect(bounds.height, inInclusiveRange(190, 230));
    expect(ctx.path.contains(const ui.Offset(70, 0)), isTrue);
    expect(ctx.path.contains(ui.Offset.zero), isFalse);
    expect(ctx.path.contains(const ui.Offset(105, 0)), isFalse);
  });

  test('line and area toUiPath build non-empty ui.Path for all 18 curves', () {
    const pts = <(double, double)>[
      (0, 10),
      (40, 80),
      (80, 20),
      (120, 90),
      (160, 40),
    ];
    final curves = <CurveFactory>[
      curveLinear,
      curveLinearClosed,
      curveBasis,
      curveBasisClosed,
      curveBasisOpen,
      curveBundle.call,
      curveBumpX,
      curveBumpY,
      curveCardinal.call,
      curveCardinalClosed.call,
      curveCardinalOpen.call,
      curveCatmullRom.call,
      curveCatmullRomClosed.call,
      curveCatmullRomOpen.call,
      curveMonotoneX,
      curveMonotoneY,
      curveNatural,
      curveStep,
      curveStepAfter,
      curveStepBefore,
    ];
    final reusable = uiPathContext();
    for (final c in curves) {
      reusable.reset();
      final p = (line<(double, double)>()..curve = c).toUiPath(pts, reusable);
      expect(p.getBounds().width, greaterThan(0));
    }
    final areaPath = (area<(double, double)>()..curve = curveCatmullRom.call)
        .toUiPath(pts);
    expect(areaPath.getBounds().height, greaterThan(50));
  });

  test('radial shapes, links, and all symbols build valid ui.Path', () {
    final radialPts = [
      for (var i = 0; i < 8; i++) (i * math.pi / 4, 40.0 + (i.isEven ? 20 : 0)),
    ];
    final rl = lineRadial<(double, double)>()..curve = curveLinearClosed;
    expect(rl.toUiPath(radialPts).getBounds().width, greaterThan(80));

    final ra = areaRadial<(double, double)>()..innerRadiusConst(20);
    expect(ra.toUiPath(radialPts).getBounds().width, greaterThan(80));

    final lh = linkHorizontal<LinkData<(double, double)>, (double, double)>();
    final lp = lh.toUiPath(const LinkData(source: (0, 0), target: (100, 50)));
    expect(lp.getBounds(), const ui.Rect.fromLTRB(0, 0, 100, 50));

    final lr = linkRadial<LinkData<(double, double)>, (double, double)>();
    final lrp = lr.toUiPath(
      const LinkData(source: (0, 20), target: (math.pi / 2, 80)),
    );
    expect(lrp.getBounds().width, greaterThan(50));

    for (final st in [...symbolsFill, ...symbolsStroke]) {
      final sp = symbol<void>(st, 256).toUiPath();
      expect(sp.getBounds().width, greaterThan(5));
    }
  });
}
