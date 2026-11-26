// Original code, not ported from d3-path: tests for Flutter UiPathContext.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_d3_path_port/flutter_d3_path_port.dart';
import 'package:test/test.dart';

void main() {
  test('UiPathContext builds rectangles and closes subpaths', () {
    final ctx = uiPathContext()
      ..moveTo(10, 20)
      ..lineTo(110, 20)
      ..lineTo(110, 70)
      ..lineTo(10, 70)
      ..closePath();

    final bounds = ctx.path.getBounds();
    expect(bounds.left, closeTo(10, 1e-4));
    expect(bounds.top, closeTo(20, 1e-4));
    expect(bounds.right, closeTo(110, 1e-4));
    expect(bounds.bottom, closeTo(70, 1e-4));
    expect(ctx.path.contains(const ui.Offset(60, 45)), isTrue);
    expect(ctx.path.contains(const ui.Offset(5, 45)), isFalse);
  });

  test('UiPathContext.rect creates a closed rectangle subpath', () {
    final ctx = UiPathContext()..rect(100, 200, 50, 25);
    expect(ctx.path.getBounds(), const ui.Rect.fromLTWH(100, 200, 50, 25));
    expect(ctx.path.contains(const ui.Offset(125, 212)), isTrue);
  });

  test('UiPathContext.arc draws full circles without collapsing', () {
    final cw = uiPathContext()..arc(100, 100, 50, 0, 2 * math.pi);
    final boundsCw = cw.path.getBounds();
    expect(boundsCw.left, closeTo(50, 1e-3));
    expect(boundsCw.top, closeTo(50, 1e-3));
    expect(boundsCw.right, closeTo(150, 1e-3));
    expect(boundsCw.bottom, closeTo(150, 1e-3));
    expect(cw.path.contains(const ui.Offset(100, 100)), isTrue);
    expect(cw.path.contains(const ui.Offset(145, 100)), isTrue);
    expect(cw.path.contains(const ui.Offset(155, 100)), isFalse);

    final ccw = uiPathContext()..arc(100, 100, 50, 0, 2 * math.pi, true);
    expect(ccw.path.contains(const ui.Offset(100, 100)), isTrue);
    expect(ccw.path.getBounds().width, closeTo(100, 1e-3));
  });

  test('UiPathContext.arc connects from current point to arc start', () {
    final ctx = uiPathContext()
      ..moveTo(0, 0)
      ..arc(100, 100, 50, 0, math.pi / 2);
    final metrics = ctx.path.computeMetrics().toList();
    expect(metrics, hasLength(1));
    final start = metrics.single.getTangentForOffset(0)!.position;
    final end = metrics.single
        .getTangentForOffset(metrics.single.length)!
        .position;
    expect(start.dx, closeTo(0, 1e-3));
    expect(start.dy, closeTo(0, 1e-3));
    expect(end.dx, closeTo(100, 1e-3));
    expect(end.dy, closeTo(150, 1e-3));
  });

  test('UiPathContext.arcTo rounds a corner with tangent arc', () {
    final ctx = uiPathContext()
      ..moveTo(100, 100)
      ..arcTo(200, 100, 200, 200, 50)
      ..lineTo(200, 200);
    final metrics = ctx.path.computeMetrics().toList();
    expect(metrics, hasLength(1));
    // Expected length: straight 50 + quarter circle (50 * pi / 2) + straight 50
    // (Skia conic flattening has ~0.13 px tolerance on a 50 px radius arc).
    expect(metrics.single.length, closeTo(100 + 25 * math.pi, 0.5));
    final mid = metrics.single
        .getTangentForOffset(metrics.single.length / 2)!
        .position;
    expect(mid.dx, closeTo(150 + 50 * math.sqrt1_2, 0.5));
    expect(mid.dy, closeTo(150 - 50 * math.sqrt1_2, 0.5));
    final end = metrics.single
        .getTangentForOffset(metrics.single.length)!
        .position;
    expect(end.dx, closeTo(200, 1e-2));
    expect(end.dy, closeTo(200, 1e-2));
  });

  test('UiPathContext handles quadratic and cubic Beziers on empty paths', () {
    final q = uiPathContext()..quadraticCurveTo(50, 0, 100, 100);
    expect(q.path.computeMetrics().single.length, greaterThan(100));

    final c = uiPathContext()..bezierCurveTo(20, 0, 80, 100, 100, 50);
    expect(c.path.computeMetrics().single.length, greaterThan(80));
  });

  test('UiPathContext throws RangeError on negative radius', () {
    final ctx = uiPathContext()..moveTo(0, 0);
    expect(() => ctx.arc(0, 0, -1, 0, math.pi), throwsRangeError);
    expect(() => ctx.arcTo(10, 0, 10, 10, -1), throwsRangeError);
  });

  test('UiPathContext ignores non-finite coordinates', () {
    final ctx = uiPathContext()
      ..moveTo(double.nan, 0)
      ..lineTo(double.infinity, 10)
      ..quadraticCurveTo(0, double.negativeInfinity, 10, 10)
      ..bezierCurveTo(0, 0, double.nan, 0, 10, 10)
      ..arc(0, 0, double.nan, 0, math.pi)
      ..arcTo(0, 0, 10, 10, double.infinity)
      ..rect(0, 0, double.nan, 10);
    expect(ctx.path.computeMetrics(), isEmpty);
  });

  test('UiPathContext.reset clears path and subpath state for reuse', () {
    final ctx = uiPathContext()..rect(0, 0, 100, 100);
    expect(ctx.path.getBounds().width, closeTo(100, 1e-3));

    ctx.reset();
    expect(ctx.path.computeMetrics(), isEmpty);

    ctx
      ..lineTo(25, 40)
      ..lineTo(75, 40);
    final bounds = ctx.path.getBounds();
    expect(bounds.left, closeTo(25, 1e-3));
    expect(bounds.right, closeTo(75, 1e-3));
  });
}
