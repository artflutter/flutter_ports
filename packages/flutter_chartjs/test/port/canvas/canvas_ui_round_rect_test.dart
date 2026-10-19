// Original code, not ported from Chart.js: roundRect on the dart:ui canvas.
@TestOn('vm')
library;

// flutter_test and dart:ui: the web legs cannot compile this file.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui_path.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/rounded_rect_upstream.dart';
import 'pixel_compare.dart';

// roundRect of the canvas layer (canvas.dart roundRectGeometry,
// canvas_ui_path.dart UiPathBuilder.roundRect) and the fast paths of the
// dart:ui context: drawRRect, drawDRRect and clipRRect (porting-flow.md
// §1.1, differences.md adapt-rounded-rect-path). The pixel tests compare
// each fast path with the arc path that the canvas drew before: the upstream
// arcs and lines of addRoundedRectPath (helpers.canvas.ts:498-527).
//
// Thresholds of the pixel tests (Chart.js ADR 0009): no pixel differs in
// area (a pixel that each render has fully opaque or fully transparent),
// the worst channel differs by at most _edge on anti-aliased edge pixels,
// and the inked areas differ by less than 1 %.

/// The largest difference of one channel on an anti-aliased edge pixel.
const int _edge = 24;

/// The retina transform of a chart on the Pixel 8a, with a translation.
void _retina(UiCanvasContext ctx) => ctx
  ..setTransform(2.625, 0, 0, 2.625, 0, 0)
  ..translate(3.25, 2.5);

/// A rounded rectangle with the corner radii of `TRBLCorners`.
typedef _Box = ({
  double x,
  double y,
  double w,
  double h,
  double tl,
  double tr,
  double br,
  double bl,
});

const List<_Box> _boxes = [
  (x: 10, y: 12, w: 80, h: 60, tl: 4, tr: 4, br: 4, bl: 4),
  (x: 10.3, y: 12.7, w: 80.2, h: 60.5, tl: 0, tr: 4, br: 12.5, bl: 30),
  (x: 20, y: 20, w: 30, h: 90, tl: 15, tr: 15, br: 0, bl: 0),
  (x: 5.5, y: 6.25, w: 100, h: 40, tl: 20, tr: 0, br: 20, bl: 0),
];

/// `roundRect` of [box] with the radii list of `addRoundedRectPath`.
void _roundRect(CanvasPath ctx, _Box box) => ctx.roundRect(
  box.x,
  box.y,
  box.w,
  box.h,
  [box.tl, box.tr, box.br, box.bl],
);

/// The upstream arcs and lines of [box].
void _arcs(CanvasPath ctx, _Box box) => upstreamRoundedRectPath(
  ctx,
  box.x,
  box.y,
  box.w,
  box.h,
  topLeft: box.tl,
  topRight: box.tr,
  bottomRight: box.br,
  bottomLeft: box.bl,
);

/// [box] grown by [d] on each side, its radii grown by [d] too.
_Box _grow(_Box box, double d) => (
  x: box.x - d,
  y: box.y - d,
  w: box.w + 2 * d,
  h: box.h + 2 * d,
  tl: box.tl == 0 ? 0 : box.tl + d,
  tr: box.tr == 0 ? 0 : box.tr + d,
  br: box.br == 0 ? 0 : box.br + d,
  bl: box.bl == 0 ? 0 : box.bl + d,
);

/// Expects that [fast] and [arcs] cover the same pixels, up to the
/// anti-aliasing of the edges.
Future<void> _expectSamePixels(
  void Function(UiCanvasContext ctx) fast,
  void Function(UiCanvasContext ctx) arcs, {
  int edge = _edge,
  String? reason,
}) async {
  final a = await renderContext(fast, width: 320, height: 320);
  final b = await renderContext(arcs, width: 320, height: 320);
  final diff = comparePixels(a, b);
  expect(diff.inkA, greaterThan(100), reason: reason);
  expect(diff.solidDiffering, 0, reason: '$reason: $diff');
  expect(diff.maxChannel, lessThanOrEqualTo(edge), reason: '$reason: $diff');
  expect(diff.inkRatio, lessThan(0.01), reason: '$reason: $diff');
}

/// A builder under the identity transform.
UiPathBuilder _builder() => UiPathBuilder(UiTransform());

/// A builder under the transform with the values a to f.
UiPathBuilder _mapped(
  double a,
  double b,
  double c,
  double d,
  double e,
  double f,
) => UiPathBuilder(UiTransform()..setValues(a, b, c, d, e, f));

/// The start points of the contours of [path], and their lengths.
List<(ui.Offset, double)> _contours(ui.Path path) => [
  for (final metric in path.computeMetrics())
    (metric.getTangentForOffset(0)!.position, metric.length),
];

void main() {
  group('UiPathBuilder.roundRect', () {
    test('adds one rounded rectangle under the identity', () {
      final b = _builder()..roundRect(10, 20, 100, 50, [1, 2, 3, 4]);
      expect(
        b.singleRRect,
        ui.RRect.fromLTRBAndCorners(
          10,
          20,
          110,
          70,
          topLeft: const ui.Radius.circular(1),
          topRight: const ui.Radius.circular(2),
          bottomRight: const ui.Radius.circular(3),
          bottomLeft: const ui.Radius.circular(4),
        ),
      );
      expect(b.singleRect, isNull);
      expect(b.singleCircle, isNull);
      expect(b.isEmpty, isFalse);
      expect(b.hasSubpath, isTrue);
      expect(b.path.getBounds(), const ui.Rect.fromLTRB(10, 20, 110, 70));
    });

    test('assigns 1 to 3 radii and an absent argument to the corners', () {
      ui.RRect? single(Object? radii) =>
          (_builder()..roundRect(0, 0, 100, 100, radii)).singleRRect;
      expect(
        single(5),
        ui.RRect.fromLTRBR(0, 0, 100, 100, const ui.Radius.circular(5)),
      );
      expect(single(null), ui.RRect.fromLTRBR(0, 0, 100, 100, ui.Radius.zero));
      expect(
        single([1, 2]),
        ui.RRect.fromLTRBAndCorners(
          0,
          0,
          100,
          100,
          topLeft: const ui.Radius.circular(1),
          topRight: const ui.Radius.circular(2),
          bottomRight: const ui.Radius.circular(1),
          bottomLeft: const ui.Radius.circular(2),
        ),
      );
      expect(
        single([1, 2, 3]),
        ui.RRect.fromLTRBAndCorners(
          0,
          0,
          100,
          100,
          topLeft: const ui.Radius.circular(1),
          topRight: const ui.Radius.circular(2),
          bottomRight: const ui.Radius.circular(3),
          bottomLeft: const ui.Radius.circular(2),
        ),
      );
    });

    test('a negative w or h flips the rectangle and the corners', () {
      final flippedX = _builder()..roundRect(110, 20, -100, 50, [1, 2, 3, 4]);
      expect(
        flippedX.singleRRect,
        ui.RRect.fromLTRBAndCorners(
          10,
          20,
          110,
          70,
          topLeft: const ui.Radius.circular(2),
          topRight: const ui.Radius.circular(1),
          bottomRight: const ui.Radius.circular(4),
          bottomLeft: const ui.Radius.circular(3),
        ),
      );
      final flippedY = _builder()..roundRect(10, 70, 100, -50, [1, 2, 3, 4]);
      expect(
        flippedY.singleRRect,
        ui.RRect.fromLTRBAndCorners(
          10,
          20,
          110,
          70,
          topLeft: const ui.Radius.circular(4),
          topRight: const ui.Radius.circular(3),
          bottomRight: const ui.Radius.circular(2),
          bottomLeft: const ui.Radius.circular(1),
        ),
      );
    });

    test('scales the radii so that the corner curves do not overlap', () {
      final b = _builder()..roundRect(0, 0, 40, 100, 30);
      expect(
        b.singleRRect,
        ui.RRect.fromLTRBR(0, 0, 40, 100, const ui.Radius.circular(20)),
      );
    });

    test('maps the rectangle and the radii through the transform', () {
      final retina = _mapped(2.625, 0, 0, 2.625, 3, 4)
        ..roundRect(10, 20, 30, 40, 4);
      final r = retina.singleRRect!;
      expect(r.left, closeTo(29.25, 1e-12));
      expect(r.top, closeTo(56.5, 1e-12));
      expect(r.right, closeTo(108, 1e-12));
      expect(r.bottom, closeTo(161.5, 1e-12));
      expect(r.tlRadius, const ui.Radius.circular(10.5));
      // A non-uniform scale gives elliptical corners.
      final stretched = _mapped(2, 0, 0, 1, 0, 0)..roundRect(0, 0, 10, 10, 2);
      expect(stretched.singleRRect!.tlRadius, const ui.Radius.elliptical(4, 2));
      // A mirror moves each radius to the mirrored corner.
      final mirrored = _mapped(-1, 0, 0, 1, 100, 0)
        ..roundRect(10, 20, 30, 40, [1, 2, 3, 4]);
      expect(
        mirrored.singleRRect,
        ui.RRect.fromLTRBAndCorners(
          60,
          20,
          90,
          60,
          topLeft: const ui.Radius.circular(2),
          topRight: const ui.Radius.circular(1),
          bottomRight: const ui.Radius.circular(4),
          bottomLeft: const ui.Radius.circular(3),
        ),
      );
      final upsideDown = _mapped(1, 0, 0, -1, 0, 100)
        ..roundRect(10, 20, 30, 40, [1, 2, 3, 4]);
      expect(
        upsideDown.singleRRect,
        ui.RRect.fromLTRBAndCorners(
          10,
          40,
          40,
          80,
          topLeft: const ui.Radius.circular(4),
          topRight: const ui.Radius.circular(3),
          bottomRight: const ui.Radius.circular(2),
          bottomLeft: const ui.Radius.circular(1),
        ),
      );
    });

    test('a rotation or a skew gives the path and no singleRRect', () {
      final rotated = _builder()
        ..transform.rotate(0.3)
        ..roundRect(10, 20, 30, 40, 4);
      expect(rotated.singleRRect, isNull);
      expect(rotated.isEmpty, isFalse);
      final skewed = _mapped(1, 0, 0.5, 1, 0, 0)..roundRect(10, 20, 30, 40, 4);
      expect(skewed.singleRRect, isNull);
      // x + 0.5 y: the corner arcs reach 21.5 and 68.5. The bounds of a
      // path also hold the control points of its curves.
      final bounds = skewed.path.getBounds();
      expect(bounds.left, closeTo(21.5, 1));
      expect(bounds.right, closeTo(68.5, 1));
    });

    test('a non-finite argument adds nothing', () {
      for (final args in [
        [double.nan, 0.0, 10.0, 10.0],
        [0.0, double.infinity, 10.0, 10.0],
        [0.0, 0.0, double.negativeInfinity, 10.0],
        [0.0, 0.0, 10.0, double.nan],
      ]) {
        final b = _builder()..roundRect(args[0], args[1], args[2], args[3], -1);
        expect(b.isEmpty, isTrue, reason: '$args');
      }
      final nanRadius = _builder()..roundRect(0, 0, 10, 10, [1, double.nan]);
      expect(nanRadius.isEmpty, isTrue);
      expect(nanRadius.hasSubpath, isFalse);
    });

    test('a bad radius throws a RangeError and adds nothing', () {
      final b = _builder();
      expect(() => b.roundRect(0, 0, 10, 10, -1), throwsRangeError);
      expect(() => b.roundRect(0, 0, 10, 10, <double>[]), throwsRangeError);
      expect(
        () => b.roundRect(0, 0, 10, 10, [1, 2, 3, 4, 5]),
        throwsRangeError,
      );
      expect(b.isEmpty, isTrue);
      // The RangeError comes before the test of the transform.
      final singular = _mapped(0, 0, 0, 1, 0, 0);
      expect(() => singular.roundRect(0, 0, 10, 10, -1), throwsRangeError);
      singular.roundRect(0, 0, 10, 10, 1);
      expect(singular.isEmpty, isTrue);
    });

    test('then starts a new subpath at (x, y)', () {
      // The builder, then the bitmap points of (x, y) and of (10, 80).
      final cases = [
        (_builder()..roundRect(10, 20, 30, 40, 5), const ui.Offset(10, 20)),
        // A negative width: the segments go counterclockwise, and the new
        // subpath starts at the x of the call.
        (_builder()..roundRect(40, 20, -30, 40, 5), const ui.Offset(40, 20)),
        // A skew: the segments, mapped.
        (
          _mapped(1, 0, 0.5, 1, 0, 0)..roundRect(10, 20, 30, 40, 5),
          const ui.Offset(20, 20),
        ),
      ];
      for (final (b, start) in cases) {
        b.lineTo(10, 80);
        final end = ui.Offset(b.transform.mapX(10, 80), 80);
        final contours = _contours(b.path);
        expect(contours, hasLength(2), reason: '$start');
        expect(contours.last.$1.dx, closeTo(start.dx, 1e-4));
        expect(contours.last.$1.dy, closeTo(start.dy, 1e-4));
        expect(contours.last.$2, closeTo((end - start).distance, 1e-3));
      }
    });

    test('the contour goes clockwise unless one side is negative', () async {
      // Two overlapping shapes, filled with the nonzero rule: the same
      // direction fills the overlap, the opposite direction leaves a hole.
      Future<int> overlap(void Function(UiCanvasContext ctx) shapes) async {
        final render = await renderContext((ctx) {
          ctx
            ..beginPath()
            ..fillStyle = '#000000';
          shapes(ctx);
          ctx.fill();
        });
        return render.alpha(60, 60);
      }

      // Each shape of 80 x 80 with the overlap [40, 80] x [40, 80].
      expect(
        await overlap(
          (ctx) => ctx
            ..roundRect(0, 0, 80, 80, 5)
            ..roundRect(40, 40, 80, 80, 5),
        ),
        255,
      );
      expect(
        await overlap(
          (ctx) => ctx
            ..roundRect(0, 0, 80, 80, 5)
            ..roundRect(120, 40, -80, 80, 5),
        ),
        0,
      );
      expect(
        await overlap(
          (ctx) => ctx
            ..roundRect(0, 0, 80, 80, 5)
            ..roundRect(40, 120, 80, -80, 5),
        ),
        0,
      );
      expect(
        await overlap(
          (ctx) => ctx
            ..roundRect(0, 0, 80, 80, 5)
            ..roundRect(120, 120, -80, -80, 5),
        ),
        255,
      );
      // A mirror reverses both: the rule still sees opposite directions.
      expect(
        await overlap(
          (ctx) => ctx
            ..setTransform(-1, 0, 0, 1, 160, 0)
            ..roundRect(80, 0, 80, 80, 5)
            ..roundRect(120, 40, -80, 80, 5),
        ),
        0,
      );
      expect(
        await overlap(
          (ctx) => ctx
            ..setTransform(-1, 0, 0, 1, 160, 0)
            ..roundRect(80, 0, 80, 80, 5)
            ..roundRect(40, 40, 80, 80, 5),
        ),
        255,
      );
      // The same with a rect: it goes clockwise as well.
      expect(
        await overlap(
          (ctx) => ctx
            ..rect(0, 0, 80, 80)
            ..roundRect(120, 40, -80, 80, 5),
        ),
        0,
      );
    });
  });

  group('shapePair and rrectContains', () {
    test('shapePair is two rect or roundRect commands', () {
      final pair =
          (_builder()
                ..roundRect(0, 0, 100, 100, 10)
                ..rect(10, 10, 80, 80))
              .shapePair;
      expect(
        pair?.first,
        ui.RRect.fromLTRBR(0, 0, 100, 100, const ui.Radius.circular(10)),
      );
      expect(pair?.second, ui.RRect.fromLTRBR(10, 10, 90, 90, ui.Radius.zero));
      expect((_builder()..roundRect(0, 0, 9, 9, 1)).shapePair, isNull);
      expect(
        (_builder()
              ..roundRect(0, 0, 9, 9, 1)
              ..roundRect(0, 0, 9, 9, 1)
              ..roundRect(0, 0, 9, 9, 1))
            .shapePair,
        isNull,
      );
      expect(
        (_builder()
              ..moveTo(0, 0)
              ..roundRect(0, 0, 9, 9, 1))
            .shapePair,
        isNull,
      );
      expect(
        (_builder()
              ..roundRect(0, 0, 9, 9, 1)
              ..lineTo(5, 5))
            .shapePair,
        isNull,
      );
      expect(
        (_builder()
              ..rect(0, 0, 9, 9)
              ..closePath())
            .shapePair,
        isNull,
      );
      final rotated = _builder();
      rotated.transform.rotate(0.2);
      rotated
        ..roundRect(0, 0, 9, 9, 1)
        ..roundRect(1, 1, 7, 7, 1);
      expect(rotated.shapePair, isNull);
    });

    test('the border ring of a bar is inside after the retina rounding', () {
      // element.bar.js boundingRects: the inner corner arc has the center of
      // the outer one and a radius smaller by the border.
      for (final scale in [1.0, 2.0, 2.625, 3.0, 1.75]) {
        for (final x in [0.1, 12.3, 333.37, 1234.5678]) {
          for (final (border, radius) in [
            (1.0, 4.0),
            (2.0, 9.5),
            (0.5, 0.75),
          ]) {
            final b = _mapped(scale, 0, 0, scale, 0.3, 0.7)
              ..roundRect(x, 20.2, 31.7, 80.9, [radius, radius, 0, 0])
              ..roundRect(
                x + border,
                20.2 + border,
                31.7 - 2 * border,
                80.9 - border,
                [radius - border, radius - border, 0, 0],
              );
            final pair = b.shapePair!;
            expect(
              rrectContains(pair.first, pair.second),
              isTrue,
              reason: '$scale $x $border $radius',
            );
            expect(rrectContains(pair.second, pair.first), isFalse);
          }
        }
      }
    });

    test('a border of other widths at the corners is inside', () {
      // boundingRects of element.bar.js for the borderWidth {top: 3,
      // right: 1, bottom: 0, left: 6} and the borderRadius 9: each inner
      // corner has the radius 9 - max of its two borders. The centers of the
      // inner corner arcs are not those of the outer arcs, and two inner arcs
      // touch the outer ones.
      final outer = ui.RRect.fromLTRBR(
        0,
        0,
        100,
        100,
        const ui.Radius.circular(9),
      );
      final inner = ui.RRect.fromLTRBAndCorners(
        6,
        3,
        99,
        100,
        topLeft: const ui.Radius.circular(3),
        topRight: const ui.Radius.circular(6),
        bottomRight: const ui.Radius.circular(8),
        bottomLeft: const ui.Radius.circular(3),
      );
      expect(rrectContains(outer, inner), isTrue);
      // The same bounds with the radius 3 at the bottom right: its bottom
      // edge reaches below the outer corner arc.
      final out = ui.RRect.fromLTRBR(
        6,
        3,
        99,
        100,
        const ui.Radius.circular(3),
      );
      expect(rrectContains(outer, out), isFalse);
    });

    test('an inner shape that sticks out is not inside', () {
      final outer = ui.RRect.fromLTRBR(
        0,
        0,
        100,
        100,
        const ui.Radius.circular(20),
      );
      // A square corner at (5, 5) is outside the corner arc.
      expect(
        rrectContains(outer, ui.RRect.fromLTRBR(5, 5, 95, 95, ui.Radius.zero)),
        isFalse,
      );
      // Bounds that stick out by a little.
      expect(
        rrectContains(
          ui.RRect.fromLTRBR(0, 0, 100, 100, ui.Radius.zero),
          ui.RRect.fromLTRBR(-1e-9, 0, 50, 50, ui.Radius.zero),
        ),
        isFalse,
      );
      // Overlapping shapes.
      expect(
        rrectContains(
          ui.RRect.fromLTRBR(0, 0, 50, 50, ui.Radius.zero),
          ui.RRect.fromLTRBR(25, 25, 75, 75, ui.Radius.zero),
        ),
        isFalse,
      );
      // A coordinate that is not finite.
      expect(
        rrectContains(
          ui.RRect.fromLTRBR(0, 0, double.infinity, 50, ui.Radius.zero),
          ui.RRect.fromLTRBR(1, 1, 2, 2, ui.Radius.zero),
        ),
        isFalse,
      );
    });

    test('a true result has every sampled point of inner inside outer', () {
      // The test is sufficient: sample the inner shapes that pass.
      final random = math.Random(7);
      var passed = 0;
      for (var i = 0; i < 400; i++) {
        double next(double max) => (random.nextDouble() * max * 4).round() / 4;
        final ow = 20 + next(60);
        final oh = 20 + next(60);
        final or = next(math.min(ow, oh) / 2);
        final outer = ui.RRect.fromLTRBR(0, 0, ow, oh, ui.Radius.circular(or));
        final l = next(8);
        final t = next(8);
        final iw = math.max(0, ow - l - next(8));
        final ih = math.max(0, oh - t - next(8));
        final ir = next(math.min(iw, ih) / 2);
        final inner = ui.RRect.fromLTRBR(
          l,
          t,
          l + iw,
          t + ih,
          ui.Radius.circular(ir),
        );
        if (!rrectContains(outer, inner)) continue;
        passed++;
        for (var y = 0.125; y < oh; y += 0.25) {
          for (var x = 0.125; x < ow; x += 0.25) {
            final p = ui.Offset(x, y);
            if (inner.contains(p)) {
              expect(outer.contains(p), isTrue, reason: '$outer $inner $p');
            }
          }
        }
      }
      expect(passed, greaterThan(50));
    });
  });

  group('fast paths of the context', () {
    test('fill of one roundRect draws an RRect', () {
      final ctx = UiCanvasElement().getContext2d()
        ..beginPath()
        ..roundRect(10, 10, 50, 40, 6);
      expect(ctx.debugPath.singleRRect, isNotNull);
      expect(ctx.debugRing, isNull);
      ctx.dispose();
    });

    test('fill evenodd of a ring draws a DRRect', () {
      final ctx = UiCanvasElement().getContext2d();
      _retina(ctx);
      ctx
        ..beginPath()
        ..roundRect(10, 10, 50, 40, [6, 6, 0, 0])
        ..roundRect(11, 11, 48, 39, [5, 5, 0, 0]);
      final ring = ctx.debugRing!;
      expect(ring.outer.left, lessThan(ring.inner.left));
      // Two rectangles: the bar with a border and no radius.
      ctx
        ..beginPath()
        ..rect(10, 10, 50, 40)
        ..rect(12, 12, 46, 38);
      expect(ctx.debugRing, isNotNull);
      // The inner shape first.
      ctx
        ..beginPath()
        ..rect(12, 12, 46, 36)
        ..roundRect(10, 10, 50, 40, 3);
      expect(ctx.debugRing?.outer.tlRadiusX, closeTo(3 * 2.625, 1e-9));
      ctx.dispose();
    });

    test('the ring falls back to the path when it does not apply', () {
      final ctx = UiCanvasElement().getContext2d();
      void expectPath(void Function() shapes, String reason) {
        ctx.beginPath();
        shapes();
        expect(ctx.debugRing, isNull, reason: reason);
        expect(ctx.debugPath.singleRRect, isNull, reason: reason);
      }

      expectPath(
        () => ctx
          ..roundRect(0, 0, 50, 50, 5)
          ..roundRect(25, 25, 50, 50, 5),
        'overlap',
      );
      expectPath(
        () => ctx
          ..roundRect(0, 0, 50, 50, 20)
          ..rect(2, 2, 46, 46),
        'a square corner outside the arc',
      );
      expectPath(
        () => ctx
          ..roundRect(0, 0, 50, 50, 5)
          ..rect(10, 10, 0, 20),
        'an inner shape with no width',
      );
      ctx
        ..save()
        ..rotate(0.25);
      expectPath(
        () => ctx
          ..roundRect(0, 0, 50, 50, 5)
          ..roundRect(5, 5, 40, 40, 1),
        'a rotation',
      );
      ctx
        ..restore()
        ..save()
        ..transform(1, 0, 0.3, 1, 0, 0);
      expectPath(
        () => ctx
          ..roundRect(0, 0, 50, 50, 5)
          ..roundRect(5, 5, 40, 40, 1),
        'a skew',
      );
      ctx
        ..restore()
        ..dispose();
    });

    test('clip of one roundRect is an RRect clip', () {
      final ctx = UiCanvasElement().getContext2d()
        ..beginPath()
        ..roundRect(10, 10, 50, 40, 6)
        ..clip()
        ..beginPath()
        ..rect(20, 20, 10, 10)
        ..clip()
        ..beginPath()
        ..roundRect(10, 10, 50, 40, 6)
        ..roundRect(20, 20, 10, 10, 2)
        ..clip()
        ..rotate(0.1)
        ..beginPath()
        ..roundRect(10, 10, 50, 40, 6)
        ..clip();
      expect(ctx.debugClips, [
        isA<ui.RRect>(),
        isA<ui.Rect>(),
        isA<ui.Path>(),
        isA<ui.Path>(),
      ]);
      ctx.dispose();
    });

    test('an RRect clip replays into a new recording', () async {
      final render = await renderContext((ctx) {
        // A paint ends the recording. The next draw starts a new one, which
        // replays the clip of the state.
        ctx
          ..beginPath()
          ..roundRect(20, 20, 100, 100, 30)
          ..clip()
          ..fillStyle = '#ff0000'
          ..fillRect(0, 0, 160, 160)
          ..paint(ui.Canvas(ui.PictureRecorder()), ui.Offset.zero)
          ..fillStyle = '#0000ff'
          ..fillRect(0, 0, 160, 160);
      });
      expect(render.alpha(70, 70), 255);
      expect(render.alpha(10, 10), 0);
      // The rounded corner: inside the box, outside the arc.
      expect(render.alpha(22, 22), 0);
      expect(render.alpha(150, 150), 0);
    });
  });

  group('pixels of the fast paths and of the arc path', () {
    test('fill of a roundRect (drawRRect)', () async {
      for (final box in _boxes) {
        for (final retina in [false, true]) {
          await _expectSamePixels(
            (ctx) {
              if (retina) _retina(ctx);
              ctx.beginPath();
              _roundRect(ctx, box);
              ctx.fill();
            },
            (ctx) {
              if (retina) _retina(ctx);
              ctx.beginPath();
              _arcs(ctx, box);
              ctx.fill();
            },
            reason: '$box retina $retina',
          );
        }
      }
    });

    test('fill under a mirror and a non-uniform scale (drawRRect)', () async {
      for (final m in [
        [-1.0, 0.0, 0.0, 1.0, 200.0, 0.0],
        [1.0, 0.0, 0.0, -1.0, 0.0, 200.0],
        [2.0, 0.0, 0.0, 1.25, 4.0, 3.0],
        [-1.5, 0.0, 0.0, -2.5, 250.0, 290.0],
      ]) {
        for (final box in _boxes) {
          void transform(UiCanvasContext ctx) =>
              ctx.setTransform(m[0], m[1], m[2], m[3], m[4], m[5]);
          await _expectSamePixels(
            (ctx) {
              transform(ctx);
              ctx.beginPath();
              _roundRect(ctx, box);
              ctx.fill();
            },
            (ctx) {
              transform(ctx);
              ctx.beginPath();
              _arcs(ctx, box);
              ctx.fill();
            },
            reason: '$m $box',
          );
        }
      }
    });

    test('fill evenodd of a bar border ring (drawDRRect)', () async {
      for (final box in _boxes) {
        final outer = _grow(box, 2);
        await _expectSamePixels(
          (ctx) {
            _retina(ctx);
            ctx.beginPath();
            _roundRect(ctx, outer);
            _roundRect(ctx, box);
            expect(ctx.debugRing, isNotNull, reason: '$box');
            ctx.fill('evenodd');
          },
          (ctx) {
            _retina(ctx);
            ctx.beginPath();
            _arcs(ctx, outer);
            _arcs(ctx, box);
            ctx.fill('evenodd');
          },
          reason: '$box',
        );
      }
      // Two rectangles: drawDRRect in place of the path.
      await _expectSamePixels(
        (ctx) {
          _retina(ctx);
          ctx
            ..beginPath()
            ..rect(10.3, 12.7, 80.2, 60.5)
            ..rect(11.3, 13.7, 78.2, 59.5);
          expect(ctx.debugRing, isNotNull);
          ctx.fill('evenodd');
        },
        (ctx) {
          _retina(ctx);
          ctx
            ..beginPath()
            ..moveTo(10.3, 12.7)
            ..lineTo(90.5, 12.7)
            ..lineTo(90.5, 73.2)
            ..lineTo(10.3, 73.2)
            ..closePath()
            ..moveTo(11.3, 13.7)
            ..lineTo(89.5, 13.7)
            ..lineTo(89.5, 73.2)
            ..lineTo(11.3, 73.2)
            ..closePath()
            ..fill('evenodd');
        },
      );
    });

    test('clip of a roundRect (clipRRect)', () async {
      for (final box in _boxes) {
        await _expectSamePixels(
          (ctx) {
            _retina(ctx);
            ctx.beginPath();
            _roundRect(ctx, box);
            ctx
              ..clip()
              ..fillRect(0, 0, 200, 200);
          },
          (ctx) {
            _retina(ctx);
            ctx.beginPath();
            _arcs(ctx, box);
            ctx
              ..clip()
              ..fillRect(0, 0, 200, 200);
          },
          reason: '$box',
        );
      }
    });

    test('the path under a rotation and a skew', () async {
      // The transform and the edge tolerance. Under a skew, both paths have
      // cubic Bézier arcs. The HTML path goes clockwise and the upstream
      // path counterclockwise, and Skia flattens a cubic from its start
      // point: the edge pixels differ by up to about 40 (the same arcs in
      // the same direction differ by less than 10).
      for (final (m, edge) in [
        (
          [math.cos(0.4), math.sin(0.4), -math.sin(0.4), math.cos(0.4), 80, 0],
          _edge,
        ),
        ([1.0, 0.0, 0.4, 1.0, 0.0, 0.0], 48),
        ([1.5, 0.3, 0.0, 1.2, 10.0, 5.0], 48),
      ]) {
        for (final box in _boxes) {
          void transform(UiCanvasContext ctx) => ctx.setTransform(
            m[0].toDouble(),
            m[1].toDouble(),
            m[2].toDouble(),
            m[3].toDouble(),
            m[4].toDouble(),
            m[5].toDouble(),
          );
          for (final op in ['fill', 'clip', 'ring']) {
            await _expectSamePixels(
              (ctx) {
                transform(ctx);
                ctx.beginPath();
                if (op == 'ring') _roundRect(ctx, _grow(box, 3));
                _roundRect(ctx, box);
                expect(ctx.debugPath.singleRRect, isNull);
                expect(ctx.debugRing, isNull);
                _finish(ctx, op);
              },
              (ctx) {
                transform(ctx);
                ctx.beginPath();
                if (op == 'ring') _arcs(ctx, _grow(box, 3));
                _arcs(ctx, box);
                _finish(ctx, op);
              },
              edge: edge,
              reason: '$m $box $op',
            );
          }
        }
      }
    });

    test('stroke of the path, with the segments and with addRRect', () async {
      for (final box in _boxes) {
        for (final flip in [false, true]) {
          await _expectSamePixels(
            (ctx) {
              _retina(ctx);
              ctx
                ..lineWidth = 2
                ..beginPath();
              if (flip) {
                // A negative width: the segments, counterclockwise.
                ctx.roundRect(
                  box.x + box.w,
                  box.y,
                  -box.w,
                  box.h,
                  [box.tr, box.tl, box.bl, box.br],
                );
              } else {
                _roundRect(ctx, box);
              }
              ctx.stroke();
            },
            (ctx) {
              _retina(ctx);
              ctx
                ..lineWidth = 2
                ..beginPath();
              _arcs(ctx, box);
              ctx
                ..closePath()
                ..stroke();
            },
            reason: '$box flip $flip',
          );
        }
      }
    });
  });
}

/// Ends a pixel case: a fill, a clip and a fill of the canvas, or an
/// even-odd fill.
void _finish(UiCanvasContext ctx, String op) {
  switch (op) {
    case 'fill':
      ctx.fill();
    case 'clip':
      ctx
        ..clip()
        ..resetTransform()
        ..fillRect(0, 0, 320, 320);
    case 'ring':
      ctx.fill('evenodd');
  }
}
