// Original code, not ported from d3-shape: twin tests for faster forms.

import 'dart:math' as math;

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

/// Literal O(n^2 * m) upstream reference implementation of `stackOffsetWiggle`.
void _referenceWiggle(
  List<StackSeries<Object?, Object?>> series,
  List<int> order,
) {
  final n = series.length;
  if (n <= 0) return;
  final s0 = series[order[0]];
  final m = s0.length;
  if (m <= 0) return;
  var y = 0.0;
  var j = 1;
  for (; j < m; ++j) {
    var s1 = 0.0;
    var s2 = 0.0;
    for (var i = 0; i < n; ++i) {
      final si = series[order[i]];
      final v0 = si[j].y1;
      final v1 = si[j - 1].y1;
      final sij0 = v0.isNaN ? 0.0 : v0;
      final sij1 = v1.isNaN ? 0.0 : v1;
      var s3 = (sij0 - sij1) / 2;
      for (var k = 0; k < i; ++k) {
        final sk = series[order[k]];
        final u0 = sk[j].y1;
        final u1 = sk[j - 1].y1;
        final skj0 = u0.isNaN ? 0.0 : u0;
        final skj1 = u1.isNaN ? 0.0 : u1;
        s3 += skj0 - skj1;
      }
      s1 += sij0;
      s2 += s3 * sij0;
    }
    s0[j - 1].y0 = y;
    s0[j - 1].y1 += y;
    if (s1 != 0) y -= s2 / s1;
  }
  s0[j - 1].y0 = y;
  s0[j - 1].y1 += y;
  stackOffsetNone(series, order);
}

void main() {
  test('stackOffsetWiggle O(n*m) matches literal O(n^2*m) upstream form', () {
    final rng = math.Random(12345);
    for (final (nSeries, nPoints) in [(1, 10), (8, 50), (40, 20)]) {
      final rows = List<List<double>>.generate(
        nPoints,
        (_) => List<double>.generate(
          nSeries,
          (k) => rng.nextInt(20) == 0 ? double.nan : rng.nextDouble() * 50,
        ),
      );
      final keys = List<int>.generate(nSeries, (i) => i);

      final fast = (stack<List<double>, int>()
        ..keysConst(keys)
        ..value = ((d, k, _, _) => d[k])
        ..order = stackOrderInsideOut
        ..offset = stackOffsetWiggle)(rows);

      final ref = (stack<List<double>, int>()
        ..keysConst(keys)
        ..value = ((d, k, _, _) => d[k])
        ..order = stackOrderInsideOut
        ..offset = _referenceWiggle)(rows);

      expect(fast.length, ref.length);
      for (var i = 0; i < fast.length; ++i) {
        expect(fast[i].index, ref[i].index);
        for (var j = 0; j < fast[i].length; ++j) {
          if (ref[i][j].y0.isNaN) {
            expect(fast[i][j].y0.isNaN, isTrue);
          } else {
            expect(fast[i][j].y0, closeTo(ref[i][j].y0, 1e-11));
          }
          if (ref[i][j].y1.isNaN) {
            expect(fast[i][j].y1.isNaN, isTrue);
          } else {
            expect(fast[i][j].y1, closeTo(ref[i][j].y1, 1e-11));
          }
        }
      }
    }
  });

  test('Pie fast paths match closure accessors across n <= 32 and n > 32', () {
    for (final n in [0, 1, 8, 20, 32, 48]) {
      final data = List<double>.generate(
        n,
        (i) => (i % 5 == 0) ? 10.0 : (i * 7 % 19).toDouble(),
      );
      final fast = (pie<double>()
        ..startAngleConst(-0.5)
        ..endAngleConst(4.5)
        ..padAngleConst(0.02))(data);
      final slow = (pie<double>()
        ..value = ((d, _, _) => d)
        ..startAngle = ((_) => -0.5)
        ..endAngle = ((_) => 4.5)
        ..padAngle = ((_) => 0.02)
        ..sortValues = shapeDescending)(data);

      expect(fast, equals(slow));
    }
  });

  test('CatmullRom sqrt/identity fast paths match general pow path', () {
    final pts = [
      for (var i = 0; i < 40; ++i) (i * 10.0, 50.0 + math.sin(i * 0.4) * 30.0),
    ];
    for (final alpha in [0.5, 1.0]) {
      final eps = alpha + 1e-12;
      final fastLine = (line<(double, double)>()
        ..x = ((d, _, _) => d.$1)
        ..y = ((d, _, _) => d.$2)
        ..curve = curveCatmullRom.alpha(alpha).call)(pts);
      final refLine = (line<(double, double)>()
        ..x = ((d, _, _) => d.$1)
        ..y = ((d, _, _) => d.$2)
        ..curve = curveCatmullRom.alpha(eps).call)(pts);
      assertPathEqual(fastLine, refLine!);

      final fastClosed = (line<(double, double)>()
        ..x = ((d, _, _) => d.$1)
        ..y = ((d, _, _) => d.$2)
        ..curve = curveCatmullRomClosed.alpha(alpha).call)(pts);
      final refClosed = (line<(double, double)>()
        ..x = ((d, _, _) => d.$1)
        ..y = ((d, _, _) => d.$2)
        ..curve = curveCatmullRomClosed.alpha(eps).call)(pts);
      assertPathEqual(fastClosed, refClosed!);

      final fastOpen = (line<(double, double)>()
        ..x = ((d, _, _) => d.$1)
        ..y = ((d, _, _) => d.$2)
        ..curve = curveCatmullRomOpen.alpha(alpha).call)(pts);
      final refOpen = (line<(double, double)>()
        ..x = ((d, _, _) => d.$1)
        ..y = ((d, _, _) => d.$2)
        ..curve = curveCatmullRomOpen.alpha(eps).call)(pts);
      assertPathEqual(fastOpen, refOpen!);
    }
  });

  test('NaturalCurve grows Float64List beyond 32 points accurately', () {
    final pts = [
      for (var i = 0; i < 100; ++i) (i * 5.0, 20.0 + math.cos(i * 0.3) * 40.0),
    ];
    final d = (line<(double, double)>()
      ..x = ((p, _, _) => p.$1)
      ..y = ((p, _, _) => p.$2)
      ..curve = curveNatural)(pts);
    expect(d, isNotNull);
    expect(d!.startsWith('M0,60C'), isTrue);
  });

  test('Arc, Line, Area, Link, and ShapeSymbol fast paths match closures', () {
    const datum = ArcData(
      innerRadius: 30,
      outerRadius: 90,
      startAngle: 0.2,
      endAngle: 1.8,
      padAngle: 0.04,
    );
    final arcFast = arc<ArcData>()
      ..innerRadiusConst(30)
      ..outerRadiusConst(90)
      ..cornerRadiusConst(10)
      ..padRadiusConst(75)
      ..padAngleConst(0.04);
    final arcSlow = arc<ArcData>()
      ..innerRadius = ((_) => 30)
      ..outerRadius = ((_) => 90)
      ..cornerRadius = ((_) => 10)
      ..padRadius = ((_) => 75)
      ..padAngle = ((_) => 0.04);
    expect(arcFast(datum), arcSlow(datum));

    final pts = [for (var i = 0; i < 20; ++i) (i * 4.0, i * 2.5)];
    final lineFast = line<(double, double)>()
      ..x = ((d, _, _) => d.$1)
      ..y = ((d, _, _) => d.$2);
    final lineSlow = line<(double, double)>()
      ..x = ((d, _, _) => d.$1)
      ..y = ((d, _, _) => d.$2)
      ..defined = ((_, _, _) => true);
    expect(lineFast(pts), lineSlow(pts));

    final areaFast = area<(double, double)>()
      ..x = ((d, _, _) => d.$1)
      ..y0 = ((_, _, _) => 0)
      ..y1 = ((d, _, _) => d.$2);
    final areaSlow = area<(double, double)>()
      ..x = ((d, _, _) => d.$1)
      ..y0 = ((_, _, _) => 0)
      ..y1 = ((d, _, _) => d.$2)
      ..defined = ((_, _, _) => true);
    expect(areaFast(pts), areaSlow(pts));

    // Link direct fast path vs custom wrapper curve.
    const linkDatum = LinkData(source: (10.0, 20.0), target: (140.0, 80.0));
    final lhFast =
        linkHorizontal<LinkData<(double, double)>, (double, double)>();
    final lhSlow = link<LinkData<(double, double)>, (double, double)>(
      (ctx) => BumpCurve(ctx, true),
    );
    expect(lhFast(linkDatum), lhSlow(linkDatum));

    const radialDatum = LinkData(source: (0.4, 40.0), target: (2.2, 110.0));
    final lrFast = linkRadial<LinkData<(double, double)>, (double, double)>();
    final lrSlow = link<LinkData<(double, double)>, (double, double)>(
      BumpRadialCurve.new,
    );
    assertPathEqual(lrFast(radialDatum), lrSlow(radialDatum)!);

    // Symbol constant vs closure.
    final symFast = symbol<double>(symbolStar, 128);
    final symSlow = symbol<double>()
      ..type = ((_) => symbolStar)
      ..size = ((_) => 128);
    expect(symFast(0), symSlow(0));
  });
}
