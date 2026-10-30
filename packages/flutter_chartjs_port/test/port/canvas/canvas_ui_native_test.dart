// Original code, not ported from Chart.js: tests of the native draw path.
@TestOn('vm')
library;

// dart:ui and flutter_test: the web legs cannot compile this file. The
// forms N1 to N5 of canvas-cuts-plan.md §7 keep the Canvas 2D calls and
// change how the layer gives them to dart:ui. Each pixel test compares a
// form with the same drawing on another path.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_path.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

/// The fill (nonzero and even-odd) and the stroke of [path], each in a
/// band of 160 x 160 pixels.
Future<Render> _renderPath(ui.Path path) => _renderUi(
  (canvas) {
    final fill = ui.Paint()..color = const ui.Color(0x80FF0000);
    final stroke = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const ui.Color(0xFF0000FF);
    canvas
      ..drawPath(path..fillType = ui.PathFillType.nonZero, fill)
      ..save()
      ..translate(0, 160)
      ..drawPath(path..fillType = ui.PathFillType.evenOdd, fill)
      ..translate(0, 160)
      ..drawPath(path, stroke)
      ..restore();
  },
  height: 480,
);

/// The length of each contour of [path].
List<double> _contours(ui.Path path) => [
  for (final metric in path.computeMetrics()) metric.length,
];

/// Compares the path of [commands] on a builder that defers its commands
/// with the path on a builder that builds its `ui.Path` before the first
/// command, and thus sends each command to it directly, as the build before
/// form N3 did. Both use the transform that [transform] makes.
Future<void> _expectDeferredPath(
  UiTransform Function() transform,
  void Function(CanvasPath path) commands,
) async {
  final deferred = UiPathBuilder(transform());
  final eager = UiPathBuilder(transform());
  commands(deferred);
  // The read builds the empty path: later commands go to it directly.
  final eagerPath = eager.path;
  commands(eager);
  expect(eager.debugBuilt, isTrue);
  final a = deferred.path;
  final b = eager.path;
  expect(identical(b, eagerPath), isTrue);
  expect(a.getBounds(), b.getBounds());
  expect(_contours(a), _contours(b));
  final diff = comparePixels(await _renderPath(a), await _renderPath(b));
  expect(diff.differing, 0, reason: '$diff');
}

/// The transform `scale(2, 2)`, `translate(3.5, 1.25)`: a similarity, as
/// `retinaScale` and `translate` give.
UiTransform _retina() => UiTransform()
  ..scale(2, 2)
  ..translate(3.5, 1.25);

/// Draws [draw] with plain `dart:ui` on [width] x [height] pixels, and gives
/// the rendered bytes.
Future<Render> _renderUi(
  void Function(ui.Canvas canvas) draw, {
  int width = 160,
  int height = 160,
}) async {
  final recorder = ui.PictureRecorder();
  draw(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return Render(data!.buffer.asUint8List(), width, height);
}

/// Ends the current recording of [ctx], as the paint of a host does.
void _paint(UiCanvasContext ctx) {
  final recorder = ui.PictureRecorder();
  ctx.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
  recorder.endRecording().dispose();
}

ui.Paint _fill(int argb) => ui.Paint()..color = ui.Color(argb);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('N1: a native save only for a state with a clip of its own', () {
    /// A full circle at (x, y), filled and stroked.
    void circle(UiCanvasContext ctx, double x, double y) {
      ctx
        ..beginPath()
        ..arc(x, y, 3, 0, 2 * math.pi)
        ..fill()
        ..stroke();
    }

    test('a save and a restore with no clip keep the circle run', () {
      final ctx = UiCanvasElement(width: 100, height: 100).getContext2d()
        ..fillStyle = '#ff0000'
        ..strokeStyle = '#0000ff';
      circle(ctx, 10, 10);
      ctx
        ..save()
        ..translate(20, 0);
      circle(ctx, 10, 10);
      ctx.restore();
      circle(ctx, 50, 10);
      // Three fills and three strokes wait in one run.
      expect(ctx.debugPendingCircles, 6);
      ctx
        ..save()
        ..beginPath()
        ..rect(0, 0, 50, 50)
        ..clip();
      // A clip draws the run first.
      expect(ctx.debugPendingCircles, 0);
      circle(ctx, 10, 30);
      expect(ctx.debugPendingCircles, 2);
      ctx.restore();
      // The restore of a state with a clip draws the run under the clip.
      expect(ctx.debugPendingCircles, 0);
    });

    test('a clip in a nested state cuts until its restore', () async {
      final port = await renderContext((ctx) {
        ctx
          ..fillStyle = '#ff0000'
          ..save()
          ..save()
          ..beginPath()
          ..rect(0, 0, 80, 160)
          ..clip()
          // A state with no clip of its own inside the clip.
          ..save()
          ..translate(10, 0)
          ..fillRect(0, 0, 160, 40)
          ..restore()
          // Still clipped, and the translation is gone.
          ..fillStyle = '#00ff00'
          ..fillRect(0, 40, 160, 40)
          ..restore()
          // The clip is gone.
          ..fillStyle = '#0000ff'
          ..fillRect(0, 80, 160, 40)
          ..restore()
          ..fillStyle = '#000000'
          ..fillRect(0, 120, 160, 40);
      });
      final reference = await _renderUi((canvas) {
        canvas
          ..save()
          ..clipRect(const ui.Rect.fromLTRB(0, 0, 80, 160))
          ..drawRect(const ui.Rect.fromLTRB(10, 0, 170, 40), _fill(0xFFFF0000))
          ..drawRect(const ui.Rect.fromLTRB(0, 40, 160, 80), _fill(0xFF00FF00))
          ..restore()
          ..drawRect(const ui.Rect.fromLTRB(0, 80, 160, 120), _fill(0xFF0000FF))
          ..drawRect(
            const ui.Rect.fromLTRB(0, 120, 160, 160),
            _fill(0xFF000000),
          );
      });
      expect(comparePixels(port, reference).differing, 0);
    });

    test('a new recording replays the levels with clips only', () async {
      final port = await renderContext((ctx) {
        ctx
          ..fillStyle = '#ff0000'
          ..fillRect(0, 0, 10, 10)
          // Level 1 has a clip, level 2 has none, level 3 has a clip.
          ..save()
          ..beginPath()
          ..rect(0, 0, 120, 160)
          ..clip()
          ..save()
          ..translate(5, 0)
          ..save()
          ..beginPath()
          ..rect(0, 0, 40, 160)
          ..clip();
        // The end of a recording: the next draw starts a new one.
        _paint(ctx);
        ctx
          ..fillStyle = '#00ff00'
          ..fillRect(0, 20, 160, 20)
          ..restore()
          ..fillStyle = '#0000ff'
          ..fillRect(0, 60, 160, 20);
        _paint(ctx);
        ctx
          ..restore()
          ..fillStyle = '#000000'
          ..fillRect(0, 100, 160, 20)
          ..restore()
          ..fillRect(0, 140, 160, 20);
      });
      final reference = await _renderUi((canvas) {
        canvas
          ..drawRect(const ui.Rect.fromLTRB(0, 0, 10, 10), _fill(0xFFFF0000))
          ..save()
          ..clipRect(const ui.Rect.fromLTRB(0, 0, 120, 160))
          ..save()
          ..clipRect(const ui.Rect.fromLTRB(5, 0, 45, 160))
          ..drawRect(const ui.Rect.fromLTRB(5, 20, 165, 40), _fill(0xFF00FF00))
          ..restore()
          ..drawRect(const ui.Rect.fromLTRB(5, 60, 165, 80), _fill(0xFF0000FF))
          ..drawRect(
            const ui.Rect.fromLTRB(0, 100, 160, 120),
            _fill(0xFF000000),
          )
          ..restore()
          // The first state has the red fill.
          ..drawRect(
            const ui.Rect.fromLTRB(0, 140, 160, 160),
            _fill(0xFFFF0000),
          );
      });
      expect(comparePixels(port, reference).differing, 0);
    });

    test('a restore without a save does nothing', () async {
      final port = await renderContext((ctx) {
        ctx
          ..restore()
          ..save()
          ..beginPath()
          ..rect(0, 0, 80, 80)
          ..clip()
          ..restore()
          ..restore()
          ..fillStyle = '#ff0000'
          ..fillRect(0, 0, 160, 160);
      });
      final reference = await _renderUi(
        (canvas) => canvas.drawRect(
          const ui.Rect.fromLTRB(0, 0, 160, 160),
          _fill(0xFFFF0000),
        ),
      );
      expect(comparePixels(port, reference).differing, 0);
    });

    test('a resize in a nested state starts at the first state', () async {
      final element = UiCanvasElement(width: 100, height: 100);
      final ctx = element.getContext2d()
        ..save()
        ..beginPath()
        ..rect(0, 0, 10, 10)
        ..clip()
        ..save();
      element.width = 100;
      ctx
        ..restore()
        ..fillStyle = '#ff0000'
        ..fillRect(0, 0, 100, 100);
      final recorder = ui.PictureRecorder();
      ctx.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
      final image = await recorder.endRecording().toImage(100, 100);
      final data = (await image.toByteData())!;
      image.dispose();
      // The clip went with the reset: the fill covers the bitmap.
      expect(data.getUint32((99 * 100 + 99) * 4), 0xFF0000FF);
    });
  });

  group('N2: no draw call for a fill with no area', () {
    test('a rectangle with no width or no height draws nothing', () async {
      var changes = 0;
      late bool empty;
      final port = await renderContext((ctx) {
        ctx
          ..onChanged = (() => changes++)
          ..fillStyle = '#ff0000'
          ..beginPath()
          ..rect(10, 10, 0, 50)
          ..fill()
          ..beginPath()
          ..rect(10, 10, 50, 0)
          ..fill('evenodd')
          ..beginPath()
          ..roundRect(20, 20, 0, 40, 4)
          ..fill();
        // The fills still count as drawn content, as before.
        empty = ctx.isEmpty;
      });
      expect(port.ink, 0);
      expect(empty, isFalse);
      expect(changes, 1);
    });

    test('the border ring and the inner fill of a narrow bar', () async {
      // A bar of 0.6 pixels with borders of 1 pixel: parseBorderWidth
      // clamps the borders, and the inner rectangle has a width of 0
      // (element.bar.js:188-198). Only the border ring has pixels.
      void bar(UiCanvasContext ctx, double x) {
        ctx
          ..save()
          ..beginPath()
          ..rect(x, 20, 0.6, 100)
          ..rect(x + 0.3, 21, 0, 98)
          ..fillStyle = '#36a2eb'
          ..fill('evenodd')
          ..beginPath()
          ..rect(x + 0.3, 21, 0, 98)
          ..fillStyle = '#ff0000'
          ..fill()
          ..restore();
      }

      final port = await renderContext((ctx) {
        for (var i = 0; i < 40; i++) {
          bar(ctx, 10 + i * 3.4);
        }
      });
      final reference = await renderContext((ctx) {
        ctx.fillStyle = '#36a2eb';
        for (var i = 0; i < 40; i++) {
          ctx.fillRect(10 + i * 3.4, 20, 0.6, 100);
        }
      });
      final diff = comparePixels(port, reference);
      expect(diff.differing, 0, reason: '$diff');
      expect(port.ink, greaterThan(40 * 0.6 * 100 * 0.9));
    });

    test('a fill with no area between two draws keeps their order', () async {
      final port = await renderContext((ctx) {
        ctx
          ..fillStyle = '#ff0000'
          ..fillRect(0, 0, 80, 80)
          ..beginPath()
          ..rect(40, 40, 0, 80)
          ..fill()
          ..fillStyle = '#0000ff'
          ..fillRect(40, 40, 80, 80);
      });
      final reference = await _renderUi((canvas) {
        canvas
          ..drawRect(const ui.Rect.fromLTRB(0, 0, 80, 80), _fill(0xFFFF0000))
          ..drawRect(
            const ui.Rect.fromLTRB(40, 40, 120, 120),
            _fill(0xFF0000FF),
          );
      });
      expect(comparePixels(port, reference).differing, 0);
    });
  });

  group('N3: the deferred path', () {
    /// Each kind of command: lines, curves, a rectangle, two rounded
    /// rectangles (`addRRect`, and the segments of a flipped one), arcs of
    /// both directions, a full circle, an ellipse, a DOM `arcTo` and closes.
    void everyCommand(CanvasPath p) {
      p
        ..moveTo(5, 5)
        ..lineTo(30, 8)
        ..quadraticCurveTo(40, 20, 30, 30)
        ..bezierCurveTo(20, 40, 10, 30, 5, 20)
        ..closePath()
        ..rect(40, 5, 20, 15)
        ..roundRect(5, 40, 25, 20, 6)
        ..roundRect(60, 40, -25, 20, [3, 8])
        ..arc(20, 70, 9, 0.3, 2.5)
        ..arc(45, 70, 8, 4, 1, true)
        ..lineTo(60, 60)
        ..arc(30, 5, 4, 0, 2 * math.pi)
        ..ellipse(50, 30, 8, 4, 0.5, 0, 5)
        ..arcTo(70, 10, 70, 30, 5)
        ..closePath();
    }

    test('the build gives the path of the direct calls', () async {
      await _expectDeferredPath(UiTransform.new, everyCommand);
      await _expectDeferredPath(_retina, everyCommand);
    });

    test('under a non-uniform scale and a skew', () async {
      await _expectDeferredPath(
        () => UiTransform()..scale(1.5, 0.75),
        everyCommand,
      );
      await _expectDeferredPath(
        () => UiTransform()..multiply(1, 0.2, 0.4, 1, 3, 2),
        everyCommand,
      );
      // A mirror: x goes to 90 - 1.25 x.
      await _expectDeferredPath(
        () => UiTransform()..setValues(-1.25, 0, 0, 1.25, 90, 0),
        everyCommand,
      );
    });

    test('a pending circle and the commands after it', () async {
      await _expectDeferredPath(
        _retina,
        (p) => p
          ..arc(30, 30, 10, 1, 1 + 2 * math.pi)
          ..closePath()
          ..closePath()
          ..lineTo(60, 60)
          ..arc(60, 30, 5, 0, -2 * math.pi, true),
      );
      await _expectDeferredPath(
        _retina,
        (p) => p
          ..arc(30, 30, 10, 0, 2 * math.pi)
          ..arcTo(60, 30, 60, 60, 8),
      );
    });

    test('more commands than the buffer, and a read in the middle', () async {
      void polyline(CanvasPath p) {
        p.moveTo(2, 2);
        for (var i = 0; i < 3 * deferredPathCommands; i++) {
          if (i % 7 == 3) {
            p.arc(4 + i * 0.7, 40, 3, 0, 2.2);
          } else {
            p.lineTo(2 + i * 0.7, 10 + (i % 5) * 9.0);
          }
        }
        p.closePath();
      }

      await _expectDeferredPath(_retina, polyline);
      final builder = UiPathBuilder(_retina());
      for (var i = 0; i < deferredPathCommands; i++) {
        builder.lineTo(i * 2.0, (i % 3) * 5.0);
      }
      expect(builder.debugBuilt, isFalse);
      builder.lineTo(70, 70);
      expect(builder.debugBuilt, isTrue);

      // A read builds the path, and the later commands go to it.
      await _expectDeferredPath(_retina, (p) {
        p
          ..moveTo(5, 5)
          ..arc(20, 20, 10, 0, 3);
        if (p is UiPathBuilder) expect(p.path.getBounds().isEmpty, isFalse);
        p
          ..lineTo(50, 5)
          ..closePath();
      });
    });

    test('the current point on an arc for the DOM arcTo', () {
      // The tangent arc reads the end of the arc before it. A path with the
      // end point as an explicit line gives the same geometry.
      const end = 2.5;
      final lazy = UiPathBuilder(_retina())
        ..arc(30, 30, 12, 0.4, end)
        ..arcTo(5, 60, 40, 70, 6)
        ..lineTo(60, 60);
      final explicit = UiPathBuilder(_retina())
        ..arc(30, 30, 12, 0.4, end)
        ..lineTo(30 + 12 * math.cos(end), 30 + 12 * math.sin(end))
        ..arcTo(5, 60, 40, 70, 6)
        ..lineTo(60, 60);
      expect(lazy.path.getBounds(), explicit.path.getBounds());
      final a = _contours(lazy.path);
      final b = _contours(explicit.path);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i], closeTo(b[i], 1e-9));
      }
    });

    test('a fast path builds no ui.Path', () {
      final ctx = UiCanvasElement(width: 100, height: 100).getContext2d();
      void expectFill(void Function() commands, {required bool built}) {
        ctx.beginPath();
        commands();
        ctx.fill('evenodd');
        expect(ctx.debugPath.debugBuilt, built);
      }

      expectFill(() => ctx.rect(10, 10, 20, 20), built: false);
      expectFill(() => ctx.roundRect(10, 10, 20, 20, 4), built: false);
      expectFill(
        () => ctx
          ..rect(10, 10, 20, 20)
          ..rect(12, 12, 16, 16),
        built: false,
      );
      expectFill(
        () => ctx
          ..arc(50, 50, 5, 0, 2 * math.pi)
          ..closePath(),
        built: false,
      );
      expectFill(
        () => ctx
          ..moveTo(10, 10)
          ..lineTo(50, 10)
          ..lineTo(30, 40),
        built: true,
      );
      ctx
        ..beginPath()
        ..rect(10, 10, 20, 20)
        ..stroke();
      expect(ctx.debugPath.debugBuilt, isTrue);
    });

    test('beginPath after a build starts an empty path', () async {
      final port = await renderContext((ctx) {
        ctx
          ..strokeStyle = '#ff0000'
          ..lineWidth = 4
          ..beginPath()
          ..moveTo(10, 10)
          ..lineTo(150, 10)
          ..stroke()
          ..beginPath()
          ..moveTo(10, 80)
          ..lineTo(150, 80)
          ..strokeStyle = '#0000ff'
          ..stroke();
      });
      final reference = await _renderUi((canvas) {
        final paint = ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas
          ..drawLine(
            const ui.Offset(10, 10),
            const ui.Offset(150, 10),
            paint..color = const ui.Color(0xFFFF0000),
          )
          ..drawLine(
            const ui.Offset(10, 80),
            const ui.Offset(150, 80),
            paint..color = const ui.Color(0xFF0000FF),
          );
      });
      expect(comparePixels(port, reference).differing, 0);
    });
  });
}
