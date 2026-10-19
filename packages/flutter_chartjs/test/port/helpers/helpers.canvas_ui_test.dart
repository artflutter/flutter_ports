// Original code, not ported from Chart.js: helpers.canvas on dart:ui.
@TestOn('vm')
library;

// flutter_test and dart:ui: the web legs cannot compile this file.
import 'dart:ui' as ui;

import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_test/flutter_test.dart';

import '../canvas/pixel_compare.dart';
import 'rounded_rect_upstream.dart';

// The two forms of addRoundedRectPath on the dart:ui canvas (differences.md
// adapt-rounded-rect-path): the port makes one roundRect call, upstream
// adds four arcs and four lines (the copy in rounded_rect_upstream.dart).
// The fill and clip area is the same. The tests compare the pixels: no
// pixel differs in area, the worst channel differs by at most 24 on
// anti-aliased edge pixels, and the inked areas differ by less than 1 %
// (Chart.js ADR 0009).

/// A JavaScript object literal `{topLeft, topRight, bottomLeft,
/// bottomRight}`, passed as [TRBLCorners].
final class _Corners implements TRBLCorners {
  const _Corners(
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  );

  @override
  final double topLeft;

  @override
  final double topRight;

  @override
  final double bottomLeft;

  @override
  final double bottomRight;
}

/// A JavaScript object literal `{x, y, w, h, radius}`, passed as a
/// [RoundedRect].
final class _Box implements RoundedRect {
  const _Box(this.x, this.y, this.w, this.h, this.radius);

  @override
  final double x;

  @override
  final double y;

  @override
  final double w;

  @override
  final double h;

  @override
  final _Corners radius;

  @override
  String toString() =>
      '($x, $y, $w, $h, ${radius.topLeft} ${radius.topRight} '
      '${radius.bottomLeft} ${radius.bottomRight})';
}

/// The rectangles of the callers: a bar with its top corners rounded, a
/// legend box, a tooltip color box and a point label backdrop, with
/// fractional positions.
const List<_Box> _boxes = [
  _Box(20.3, 30.6, 31.7, 80.9, _Corners(4, 4, 0, 0)),
  _Box(10, 12, 40, 12, _Corners(3, 3, 3, 3)),
  _Box(60.5, 40.25, 12, 12, _Corners(6, 0, 6, 0)),
  _Box(15.75, 20.5, 90, 20, _Corners(2, 8, 10, 0)),
];

/// The upstream form of `addRoundedRectPath(ctx, box)`.
void _upstream(UiCanvasContext ctx, _Box box) => upstreamRoundedRectPath(
  ctx,
  box.x,
  box.y,
  box.w,
  box.h,
  topLeft: box.radius.topLeft,
  topRight: box.radius.topRight,
  bottomRight: box.radius.bottomRight,
  bottomLeft: box.radius.bottomLeft,
);

/// The retina transform of a chart on the Pixel 8a.
void _retina(UiCanvasContext ctx) => ctx.setTransform(2.625, 0, 0, 2.625, 0, 0);

Future<PixelDiff> _compare(
  void Function(UiCanvasContext ctx) port,
  void Function(UiCanvasContext ctx) upstream,
) async {
  final a = await renderContext(port, width: 340, height: 340);
  final b = await renderContext(upstream, width: 340, height: 340);
  return comparePixels(a, b);
}

void _expectSame(PixelDiff diff, String reason) {
  expect(diff.inkA, greaterThan(100), reason: reason);
  expect(diff.solidDiffering, 0, reason: '$reason: $diff');
  expect(diff.maxChannel, lessThanOrEqualTo(24), reason: '$reason: $diff');
  expect(diff.inkRatio, lessThan(0.01), reason: '$reason: $diff');
}

void main() {
  group('adapt-rounded-rect-path', () {
    test('the fill of both forms covers the same pixels', () async {
      for (final box in _boxes) {
        final diff = await _compare(
          (ctx) {
            _retina(ctx);
            ctx.beginPath();
            addRoundedRectPath(ctx, box);
            ctx.fill();
          },
          (ctx) {
            _retina(ctx);
            ctx.beginPath();
            _upstream(ctx, box);
            ctx.fill();
          },
        );
        _expectSame(diff, '$box');
      }
    });

    test('the clip of both forms covers the same pixels', () async {
      for (final box in _boxes) {
        final diff = await _compare(
          (ctx) {
            _retina(ctx);
            ctx.beginPath();
            addRoundedRectPath(ctx, box);
            ctx
              ..clip()
              ..fillRect(0, 0, 200, 200);
          },
          (ctx) {
            _retina(ctx);
            ctx.beginPath();
            _upstream(ctx, box);
            ctx
              ..clip()
              ..fillRect(0, 0, 200, 200);
          },
        );
        _expectSame(diff, '$box');
      }
    });

    test('the stroke of both forms covers the same pixels', () async {
      // plugin.legend.js:359 and plugin.tooltip.js:845 stroke the path. The
      // upstream path is open and ends at its start point with the same
      // tangent, so the butt caps meet as a join does.
      for (final box in _boxes) {
        final diff = await _compare(
          (ctx) {
            _retina(ctx);
            ctx
              ..lineWidth = 1.5
              ..beginPath();
            addRoundedRectPath(ctx, box);
            ctx.stroke();
          },
          (ctx) {
            _retina(ctx);
            ctx
              ..lineWidth = 1.5
              ..beginPath();
            _upstream(ctx, box);
            ctx.stroke();
          },
        );
        _expectSame(diff, '$box');
      }
    });

    test('a negative radius throws in both forms', () {
      // The DOM arc throws an IndexSizeError and roundRect a RangeError.
      // The canvas layer throws a RangeError for both.
      const box = _Box(10, 10, 40, 40, _Corners(-1, 2, 2, 2));
      final ctx = UiCanvasElement().getContext2d()..beginPath();
      expect(() => addRoundedRectPath(ctx, box), throwsRangeError);
      expect(() => _upstream(ctx, box), throwsRangeError);
      ctx.dispose();
    });

    test('radii that overflow scale down, where the upstream arcs overlap', () {
      // A listed difference of the row: on a 20 x 20 box, the radius 15
      // gives a circle of radius 10 in the port.
      const box = _Box(10, 10, 20, 20, _Corners(15, 15, 15, 15));
      final ctx = UiCanvasElement().getContext2d()..beginPath();
      addRoundedRectPath(ctx, box);
      expect(
        ctx.debugPath.singleRRect,
        ui.RRect.fromLTRBR(10, 10, 30, 30, const ui.Radius.circular(10)),
      );
      ctx.dispose();
    });

    test('a NaN radius adds nothing, where upstream adds the finite parts', () {
      // A listed difference of the row.
      const box = _Box(10, 10, 40, 40, _Corners(double.nan, 4, 4, 4));
      final port = UiCanvasElement().getContext2d()..beginPath();
      addRoundedRectPath(port, box);
      expect(port.debugPath.isEmpty, isTrue);
      final upstream = UiCanvasElement().getContext2d()..beginPath();
      _upstream(upstream, box);
      expect(upstream.debugPath.isEmpty, isFalse);
      port.dispose();
      upstream.dispose();
    });

    test('the current point does not join the rounded rectangle', () {
      // A listed difference of the row: upstream connects the current
      // point to the first arc with a line. The port starts a new subpath.
      const box = _Box(10, 10, 40, 40, _Corners(4, 4, 4, 4));
      final port = UiCanvasElement().getContext2d()
        ..beginPath()
        ..moveTo(0, 0);
      addRoundedRectPath(port, box);
      final upstream = UiCanvasElement().getContext2d()
        ..beginPath()
        ..moveTo(0, 0);
      _upstream(upstream, box);
      // The port: the single-point subpath, the closed rounded rectangle
      // and the single-point subpath at (x, y). Upstream: one subpath.
      expect(
        upstream.debugPath.path.computeMetrics().map((m) => m.isClosed),
        [false],
      );
      expect(
        port.debugPath.path.computeMetrics().map((m) => m.isClosed),
        [true],
      );
      port.dispose();
      upstream.dispose();
    });
  });
}
