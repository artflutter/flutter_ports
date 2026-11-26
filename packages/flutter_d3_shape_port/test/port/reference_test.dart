// Original code, not ported from d3-shape: Node.js reference comparison tests.

import 'dart:math' as math;

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';
import 'd3_shape_reference.dart';

void main() {
  const points = [
    (0.0, 10.0),
    (20.0, 45.0),
    (45.0, 25.0),
    (70.0, 80.0),
    (100.0, 35.0),
    (135.0, 65.0),
    (170.0, 15.0),
    (200.0, 50.0),
  ];

  const areaPoints = [
    (0.0, 10.0, 40.0),
    (25.0, 22.0, 65.0),
    (55.0, 15.0, 50.0),
    (90.0, 30.0, 95.0),
    (120.0, 18.0, 70.0),
    (160.0, 25.0, 85.0),
  ];

  const radialPoints = [
    (0.0, 30.0),
    (math.pi / 3, 55.0),
    (2 * math.pi / 3, 40.0),
    (math.pi, 75.0),
    (4 * math.pi / 3, 45.0),
    (5 * math.pi / 3, 60.0),
  ];

  test('line() across all curves matches Node.js reference', () {
    final curves = <String, CurveFactory>{
      'linear': curveLinear,
      'linearClosed': curveLinearClosed,
      'basis': curveBasis,
      'basisClosed': curveBasisClosed,
      'basisOpen': curveBasisOpen,
      'bundle05': curveBundle.beta(0.5).call,
      'bumpX': curveBumpX,
      'bumpY': curveBumpY,
      'cardinal04': curveCardinal.tension(0.4).call,
      'cardinalClosed04': curveCardinalClosed.tension(0.4).call,
      'cardinalOpen04': curveCardinalOpen.tension(0.4).call,
      'catmullRom0': curveCatmullRom.alpha(0).call,
      'catmullRom05': curveCatmullRom.alpha(0.5).call,
      'catmullRom1': curveCatmullRom.alpha(1).call,
      'catmullRomClosed05': curveCatmullRomClosed.alpha(0.5).call,
      'catmullRomOpen05': curveCatmullRomOpen.alpha(0.5).call,
      'monotoneX': curveMonotoneX,
      'monotoneY': curveMonotoneY,
      'natural': curveNatural,
      'step': curveStep,
      'stepBefore': curveStepBefore,
      'stepAfter': curveStepAfter,
    };

    for (final entry in curves.entries) {
      final actual = (line<(double, double)>()
        ..x = ((d, _, _) => d.$1)
        ..y = ((d, _, _) => d.$2)
        ..curve = entry.value)(points)!;
      assertPathEqual(actual, referenceLines[entry.key]!);
    }

    final withGap = (line<(double, double)>()
      ..x = ((d, _, _) => d.$1)
      ..y = ((d, _, _) => d.$2)
      ..defined = ((_, i, _) => i != 3)
      ..curve = curveMonotoneX)(points)!;
    assertPathEqual(withGap, referenceLines['withGap']!);
  });

  test('area() across all curves matches Node.js reference', () {
    final curves = <String, CurveFactory>{
      'linear': curveLinear,
      'linearClosed': curveLinearClosed,
      'basis': curveBasis,
      'basisClosed': curveBasisClosed,
      'basisOpen': curveBasisOpen,
      'bumpX': curveBumpX,
      'bumpY': curveBumpY,
      'cardinal04': curveCardinal.tension(0.4).call,
      'cardinalClosed04': curveCardinalClosed.tension(0.4).call,
      'cardinalOpen04': curveCardinalOpen.tension(0.4).call,
      'catmullRom05': curveCatmullRom.alpha(0.5).call,
      'catmullRomClosed05': curveCatmullRomClosed.alpha(0.5).call,
      'catmullRomOpen05': curveCatmullRomOpen.alpha(0.5).call,
      'monotoneX': curveMonotoneX,
      'monotoneY': curveMonotoneY,
      'natural': curveNatural,
      'step': curveStep,
      'stepBefore': curveStepBefore,
      'stepAfter': curveStepAfter,
    };

    for (final entry in curves.entries) {
      final actual = (area<(double, double, double)>()
        ..x = ((d, _, _) => d.$1)
        ..y0 = ((d, _, _) => d.$2)
        ..y1 = ((d, _, _) => d.$3)
        ..curve = entry.value)(areaPoints)!;
      assertPathEqual(actual, referenceAreas[entry.key]!);
    }
  });

  test('lineRadial() and areaRadial() match Node.js reference', () {
    final l = lineRadial<(double, double)>()
      ..angle = ((d, _, _) => d.$1)
      ..radius = ((d, _, _) => d.$2);
    assertPathEqual(l(radialPoints), referenceRadials['lineLinear']!);
    l.curve = curveBasisClosed;
    assertPathEqual(l(radialPoints), referenceRadials['lineBasisClosed']!);
    l.curve = curveNatural;
    assertPathEqual(l(radialPoints), referenceRadials['lineNatural']!);
    l.curve = curveCardinalClosed.call;
    assertPathEqual(l(radialPoints), referenceRadials['lineCardinalClosed']!);
    l.curve = curveCatmullRomClosed.call;
    assertPathEqual(l(radialPoints), referenceRadials['lineCatmullRomClosed']!);

    final a = areaRadial<(double, double)>()
      ..angle = ((d, _, _) => d.$1)
      ..innerRadius = ((d, _, _) => d.$2 * 0.5)
      ..outerRadius = ((d, _, _) => d.$2);
    assertPathEqual(a(radialPoints), referenceRadials['areaLinear']!);
    a.curve = curveBasis;
    assertPathEqual(a(radialPoints), referenceRadials['areaBasis']!);
  });

  test('arc() and centroid() match Node.js reference', () {
    final a = arc<ArcData>();
    assertPathEqual(
      a(
        const ArcData(
          innerRadius: 0,
          outerRadius: 100,
          startAngle: 0,
          endAngle: math.pi / 2,
        ),
      ),
      referenceArcs['sector']!,
    );
    assertPathEqual(
      a(
        const ArcData(
          innerRadius: 40,
          outerRadius: 100,
          startAngle: 0.2,
          endAngle: 1.9,
        ),
      ),
      referenceArcs['annulus']!,
    );
    assertPathEqual(
      (arc<ArcData>()
        ..cornerRadiusConst(12)
        ..padAngleConst(0.04))(
        const ArcData(
          innerRadius: 45,
          outerRadius: 100,
          startAngle: 0.1,
          endAngle: 1.4,
        ),
      ),
      referenceArcs['roundedPadded']!,
    );
    assertPathEqual(
      a(
        const ArcData(
          innerRadius: 30,
          outerRadius: 90,
          startAngle: 0,
          endAngle: math.pi * 2,
        ),
      ),
      referenceArcs['fullCircle']!,
    );
    assertPathEqual(
      (arc<ArcData>()
        ..padRadiusConst(80)
        ..padAngleConst(0.05)
        ..cornerRadiusConst(8))(
        const ArcData(
          innerRadius: 20,
          outerRadius: 100,
          startAngle: -0.5,
          endAngle: 1.2,
        ),
      ),
      referenceArcs['padRadius']!,
    );

    final c1 = a.centroid(
      const ArcData(
        innerRadius: 40,
        outerRadius: 100,
        startAngle: 0.2,
        endAngle: 1.9,
      ),
    );
    expect(c1.$1, closeTo(referenceArcCentroids['annulus']!.$1, 1e-12));
    expect(c1.$2, closeTo(referenceArcCentroids['annulus']!.$2, 1e-12));

    final c2 = a.centroid(
      const ArcData(
        innerRadius: 0,
        outerRadius: 100,
        startAngle: 0,
        endAngle: math.pi / 2,
      ),
    );
    expect(c2.$1, closeTo(referenceArcCentroids['sector']!.$1, 1e-12));
    expect(c2.$2, closeTo(referenceArcCentroids['sector']!.$2, 1e-12));
  });

  test('pie() matches Node.js reference', () {
    const pieData = [1, 1, 2, 3, 5, 8, 13, 21];

    void checkPie(
      List<PieArc<int>> actual,
      List<
        ({
          int data,
          int index,
          double value,
          double startAngle,
          double endAngle,
          double padAngle,
        })
      >
      expected,
    ) {
      expect(actual.length, expected.length);
      for (var i = 0; i < actual.length; i++) {
        expect(actual[i].data, expected[i].data);
        expect(actual[i].index, expected[i].index);
        expect(actual[i].value, closeTo(expected[i].value, 1e-12));
        expect(actual[i].startAngle, closeTo(expected[i].startAngle, 1e-12));
        expect(actual[i].endAngle, closeTo(expected[i].endAngle, 1e-12));
        expect(actual[i].padAngle, closeTo(expected[i].padAngle, 1e-12));
      }
    }

    checkPie(
      (pie<int>()..value = ((d, _, _) => d.toDouble()))(pieData),
      referencePieDefault,
    );
    checkPie(
      (pie<int>()
        ..value = ((d, _, _) => d.toDouble())
        ..startAngleConst(-math.pi / 2)
        ..endAngleConst(math.pi / 2)
        ..padAngleConst(0.03)
        ..sort = null)(pieData),
      referencePiePadded,
    );
  });

  test('linkHorizontal, linkVertical, linkRadial match Node.js reference', () {
    const datum = LinkData(source: (10, 20), target: (150, 90));
    const radialDatum = LinkData(source: (0.3, 40), target: (2.1, 120));
    assertPathEqual(
      linkHorizontal<LinkData<(int, int)>, (int, int)>()(datum),
      referenceLinks['horizontal']!,
    );
    assertPathEqual(
      linkVertical<LinkData<(int, int)>, (int, int)>()(datum),
      referenceLinks['vertical']!,
    );
    assertPathEqual(
      linkRadial<LinkData<(double, int)>, (double, int)>()(radialDatum),
      referenceLinks['radial']!,
    );
  });

  test('all 13 symbols at size 64 and 250 match Node.js reference', () {
    const symbols = <(String, SymbolType)>[
      ('circle', symbolCircle),
      ('cross', symbolCross),
      ('diamond', symbolDiamond),
      ('square', symbolSquare),
      ('star', symbolStar),
      ('triangle', symbolTriangle),
      ('wye', symbolWye),
      ('times', symbolTimes),
      ('plus', symbolPlus),
      ('asterisk', symbolAsterisk),
      ('diamond2', symbolDiamond2),
      ('square2', symbolSquare2),
      ('triangle2', symbolTriangle2),
    ];

    for (final (name, type) in symbols) {
      assertPathEqual(
        symbol<Object?>(type, 64)(),
        referenceSymbols['${name}_64']!,
      );
      assertPathEqual(
        symbol<Object?>(type, 250)(),
        referenceSymbols['${name}_250']!,
      );
    }
  });

  test('stack() across all offsets and orders matches Node.js reference', () {
    const stackData = [
      {'a': 10.0, 'b': 25.0, 'c': 5.0, 'd': 15.0},
      {'a': 30.0, 'b': 10.0, 'c': 20.0, 'd': 5.0},
      {'a': 15.0, 'b': 35.0, 'c': 10.0, 'd': 25.0},
      {'a': 5.0, 'b': 15.0, 'c': 40.0, 'd': 10.0},
      {'a': 25.0, 'b': 5.0, 'c': 15.0, 'd': 30.0},
    ];
    const stackDivergingData = [
      {'a': 10.0, 'b': -5.0, 'c': 20.0, 'd': -15.0},
      {'a': -10.0, 'b': 15.0, 'c': -5.0, 'd': 25.0},
      {'a': 5.0, 'b': 10.0, 'c': -20.0, 'd': 5.0},
    ];

    final offsets = <String, StackOffset>{
      'none': stackOffsetNone,
      'expand': stackOffsetExpand,
      'silhouette': stackOffsetSilhouette,
      'wiggle': stackOffsetWiggle,
    };
    final orders = <String, StackOrder>{
      'none': stackOrderNone,
      'ascending': stackOrderAscending,
      'descending': stackOrderDescending,
      'appearance': stackOrderAppearance,
      'insideOut': stackOrderInsideOut,
      'reverse': stackOrderReverse,
    };

    void checkStack(
      List<StackSeries<Map<String, double>, String>> actual,
      List<({String key, int index, List<(double, double)> points})> expected,
      String name,
    ) {
      expect(actual.length, expected.length, reason: name);
      for (var i = 0; i < actual.length; i++) {
        expect(actual[i].key, expected[i].key, reason: '$name[$i].key');
        expect(actual[i].index, expected[i].index, reason: '$name[$i].index');
        expect(
          actual[i].length,
          expected[i].points.length,
          reason: '$name[$i].length',
        );
        for (var j = 0; j < actual[i].length; j++) {
          expect(
            actual[i][j].y0,
            closeTo(expected[i].points[j].$1, 1e-12),
            reason: '$name[$i][$j].y0',
          );
          expect(
            actual[i][j].y1,
            closeTo(expected[i].points[j].$2, 1e-12),
            reason: '$name[$i][$j].y1',
          );
        }
      }
    }

    for (final o in offsets.entries) {
      for (final r in orders.entries) {
        final name = '${o.key}_${r.key}';
        final actual = (stack<Map<String, double>, String>()
          ..keysConst(['a', 'b', 'c', 'd'])
          ..value = ((d, k, _, _) => d[k] ?? double.nan)
          ..offset = o.value
          ..order = r.value)(stackData);
        checkStack(actual, referenceStacks[name]!, name);
      }
    }

    final diverging = (stack<Map<String, double>, String>()
      ..keysConst(['a', 'b', 'c', 'd'])
      ..value = ((d, k, _, _) => d[k] ?? double.nan)
      ..offset = stackOffsetDiverging)(stackDivergingData);
    checkStack(diverging, referenceStacks['diverging_none']!, 'diverging_none');
  });
}
