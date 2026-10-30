// Original code, not ported from Chart.js: tests of the native draw path.
@TestOn('vm')
library;

// dart:ui and flutter_test: the web legs cannot compile this file. The
// forms N1 to N5 of canvas-cuts-plan.md §7 keep the Canvas 2D calls and
// change how the layer gives them to dart:ui. Each pixel test compares a
// form with the same drawing on another path.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_batch.dart'
    show maxAtlasInstances;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_path.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
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

/// A circle of a reference drawing: its center, its radius, its fill and
/// stroke colors (null for none) and the stroke width.
typedef _Dot = ({
  ui.Offset c,
  double r,
  ui.Color? fill,
  ui.Color? stroke,
  double width,
});

/// The CSS text of [color] for `fillStyle` and `strokeStyle`.
String _css(ui.Color color) =>
    'rgba(${(color.r * 255).round()}, ${(color.g * 255).round()}, '
    '${(color.b * 255).round()}, ${color.a})';

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

  group('N4: the sector fill with drawArc', () {
    /// The calls of `pathArc` (element.arc.ts:230-286) for an arc with no
    /// border radius, no spacing and no offset: the two halves of the outer
    /// arc, the line to the inner arc, the two halves of the inner arc
    /// backwards and the line back. The inner arcs of a wedge ([inner] 0)
    /// have the NaN angles of `innerEnd / innerRadius` and add nothing.
    void sectorCalls(
      CanvasPath p,
      double x,
      double y,
      double outer,
      double inner,
      double start,
      double end,
    ) {
      final corner = 0 / inner;
      final outerMid = (start + end) / 2;
      final innerStart = end - corner;
      final innerEnd = start + corner;
      final innerMid = (innerStart + innerEnd) / 2;
      p
        ..arc(x, y, outer, start, outerMid)
        ..arc(x, y, outer, outerMid, end)
        ..lineTo(x + math.cos(end) * inner, y + math.sin(end) * inner)
        ..arc(x, y, inner, innerStart, innerMid, true)
        ..arc(x, y, inner, innerMid, innerEnd, true)
        ..lineTo(x + math.cos(start) * outer, y + math.sin(start) * outer)
        ..closePath();
    }

    /// A context of 320 x 320 pixels under `retinaScale` at a device pixel
    /// ratio of 2.
    UiCanvasContext retina() => UiCanvasElement(
      width: 320,
      height: 320,
    ).getContext2d()..setTransform(2, 0, 0, 2, 0, 0);

    UiSector? sectorOf(
      void Function(UiCanvasContext ctx) calls, {
      UiCanvasContext? context,
    }) {
      final ctx = (context ?? retina())..beginPath();
      calls(ctx);
      return ctx.debugPath.singleSector;
    }

    test('the arc of a doughnut is a ring sector', () {
      final sector = sectorOf(
        (ctx) => sectorCalls(ctx, 80, 70, 50, 25, 0.3, 2.1),
      )!;
      expect(sector.x, 160);
      expect(sector.y, 140);
      expect(sector.radius, 100);
      expect(sector.inner, 50);
      expect(sector.start, closeTo(0.3, 1e-12));
      expect(sector.sweep, closeTo(1.8, 1e-12));
    });

    test('the arc of a pie and a wedge from the center are wedges', () {
      final pie = sectorOf((ctx) => sectorCalls(ctx, 80, 70, 50, 0, -1, 4))!;
      expect(pie.inner, 0);
      expect(pie.radius, 100);
      expect(pie.sweep, closeTo(5, 1e-12));
      final wedge = sectorOf(
        (ctx) => ctx
          ..moveTo(80, 70)
          ..arc(80, 70, 40, 1, 2.5)
          ..closePath(),
      )!;
      expect(wedge.inner, 0);
      expect(wedge.radius, 80);
      expect(wedge.start, 1);
      expect(wedge.sweep, closeTo(1.5, 1e-12));
    });

    test('other directions and similarity transforms', () {
      // The outer arc counterclockwise and the inner arc back.
      final ring = sectorOf(
        (ctx) => ctx
          ..arc(80, 80, 60, 2, 0.5, true)
          ..arc(80, 80, 20, 0.5, 2),
      )!;
      expect(ring.inner, 40);
      expect(ring.radius, 120);
      expect(ring.start, 2);
      expect(ring.sweep, closeTo(-1.5, 1e-12));
      // The smaller radius first.
      final inside = sectorOf(
        (ctx) => ctx
          ..arc(80, 80, 20, 0, 1)
          ..arc(80, 80, 60, 1, 0, true)
          ..closePath(),
      )!;
      expect(inside.inner, 40);
      expect(inside.radius, 120);
      // A rotation and a mirror keep a sector.
      final turned = retina()
        ..rotate(0.7)
        ..scale(-1, 1);
      expect(
        sectorOf(
          (ctx) => sectorCalls(ctx, -80, 30, 40, 10, 0.2, 1.9),
          context: turned,
        ),
        isNotNull,
      );
    });

    test('other paths are no sector', () {
      final cases = <String, void Function(UiCanvasContext ctx)>{
        // A corner of a border radius is an arc on another center.
        'a border radius': (ctx) => ctx
          ..arc(80, 80, 60, 0.2, 1.5)
          ..arc(50, 120, 5, 1.5, 2)
          ..lineTo(80 + math.cos(1.5) * 20, 80 + math.sin(1.5) * 20)
          ..arc(80, 80, 20, 1.5, 0.2, true)
          ..closePath(),
        // The parallel spacing of upstream: other angles on the inner arc.
        'other inner angles': (ctx) => ctx
          ..arc(80, 80, 60, 0.2, 1.5)
          ..arc(80, 80, 20, 1.45, 0.25, true)
          ..closePath(),
        'a chord': (ctx) => ctx
          ..arc(80, 80, 60, 0.2, 1.5)
          ..closePath(),
        'a line off the radius': (ctx) => ctx
          ..arc(80, 80, 60, 0.2, 1.5)
          ..lineTo(70, 70)
          ..lineTo(80, 80)
          ..closePath(),
        'two subpaths': (ctx) => ctx
          ..arc(80, 80, 60, 0.2, 1.5)
          ..lineTo(80, 80)
          ..closePath()
          ..moveTo(10, 10)
          ..lineTo(20, 10),
        'a full ring': (ctx) => ctx
          ..arc(80, 80, 60, 0, 2 * math.pi)
          ..moveTo(100, 80)
          ..arc(80, 80, 20, 2 * math.pi, 0, true)
          ..closePath(),
        'a full turn with the center': (ctx) => ctx
          ..moveTo(80, 80)
          ..arc(80, 80, 60, 0, 3.2)
          ..arc(80, 80, 60, 3.2, 2 * math.pi)
          ..closePath(),
        'an ellipse': (ctx) => ctx
          ..scale(1, 0.5)
          ..moveTo(80, 80)
          ..arc(80, 80, 60, 0.2, 1.5)
          ..closePath(),
        'a curve': (ctx) => ctx
          ..moveTo(80, 80)
          ..arc(80, 80, 60, 0.2, 1.5)
          ..quadraticCurveTo(10, 10, 80, 80),
        'a read of the path': (ctx) {
          ctx
            ..moveTo(80, 80)
            ..arc(80, 80, 60, 0.2, 1.5)
            ..closePath();
          expect(ctx.debugPath.path.getBounds().isEmpty, isFalse);
        },
      };
      for (final MapEntry(key: name, value: calls) in cases.entries) {
        expect(sectorOf(calls), isNull, reason: name);
      }
    });

    /// Draws [draw] at [factor] times the scale on [factor] times the size,
    /// and gives the mean of each block of [factor] x [factor] pixels: the
    /// coverage of the shapes to about 1/[factor] of a pixel. The curves of
    /// a path and of a stroke flatten within about 1/4 of a device pixel, so
    /// two forms of one region can differ by that much on an edge pixel at
    /// the device scale (the probe of canvas-cuts-plan.md §7.5).
    Future<Render> supersampled(
      void Function(UiCanvasContext ctx) draw, {
      int size = 320,
      int factor = 4,
    }) async {
      final big = await renderContext(
        (ctx) {
          ctx.scale(factor.toDouble(), factor.toDouble());
          draw(ctx);
        },
        width: size * factor,
        height: size * factor,
      );
      final out = Uint8List(size * size * 4);
      final area = factor * factor;
      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          for (var c = 0; c < 4; c++) {
            var sum = 0;
            for (var dy = 0; dy < factor; dy++) {
              final row = (y * factor + dy) * size * factor;
              for (var dx = 0; dx < factor; dx++) {
                sum += big.bytes[(row + x * factor + dx) * 4 + c];
              }
            }
            out[(y * size + x) * 4 + c] = (sum / area).round();
          }
        }
      }
      return Render(out, size, size);
    }

    /// Expects that the fill of [calls] with [style] draws a sector, with the
    /// pixels of the fill before form N4: the same calls with the path
    /// built, which `fill` draws with `drawPath`. At the device scale, no
    /// pixel differs in area: the two forms flatten their curves in other
    /// ways, and a ring of 2 pixels can gain or lose 4 % of its ink in each.
    /// At four times the scale, the worst channel differs by at most 24 of
    /// 255 and the inked areas by less than 1 %.
    Future<void> expectSectorPixels(
      String reason,
      void Function(UiCanvasContext ctx) style,
      void Function(CanvasPath p) calls, {
      String rule = 'nonzero',
    }) async {
      void sector(UiCanvasContext ctx) {
        style(ctx);
        ctx.beginPath();
        calls(ctx);
        expect(ctx.debugPath.singleSector, isNotNull, reason: reason);
        ctx.fill(rule);
        expect(ctx.debugPath.debugBuilt, isFalse, reason: reason);
      }

      void path(UiCanvasContext ctx) {
        style(ctx);
        ctx.beginPath();
        calls(ctx);
        // A read builds the path: the fill takes drawPath.
        expect(ctx.debugPath.path.getBounds().isEmpty, isFalse);
        expect(ctx.debugPath.singleSector, isNull, reason: reason);
        ctx.fill(rule);
      }

      final device = comparePixels(
        await renderContext(sector, width: 320, height: 320),
        await renderContext(path, width: 320, height: 320),
      );
      expect(device.inkA, greaterThan(1), reason: reason);
      expect(device.solidDiffering, 0, reason: '$reason: $device');
      expect(device.opaqueFlips, 0, reason: '$reason: $device');
      final fine = comparePixels(
        await supersampled(sector),
        await supersampled(path),
      );
      expect(fine.maxChannel, lessThanOrEqualTo(24), reason: '$reason: $fine');
      expect(fine.inkRatio, lessThan(0.01), reason: '$reason: $fine');
    }

    test('the fill of a sector gives the pixels of its path', () async {
      void retinaStyle(UiCanvasContext ctx) => ctx
        ..scale(2, 2)
        ..fillStyle = 'rgba(54, 162, 235, 0.45)';
      const angles = [
        (0.3, 2.1),
        (-1.4, 3.0),
        (2.0, 2.02),
        (0.5, 0.5 + 2 * math.pi - 0.01),
        (5.0, 7.5),
      ];
      const radii = [(60.0, 30.0), (60.0, 59.0), (60.0, 1.0), (60.0, 0.0)];
      for (final (start, end) in angles) {
        for (final (outer, inner) in radii) {
          await expectSectorPixels(
            'angles $start to $end, radii $outer and $inner',
            retinaStyle,
            (p) => sectorCalls(p, 80, 80, outer, inner, start, end),
          );
        }
      }
      await expectSectorPixels(
        'the even-odd rule',
        retinaStyle,
        (p) => sectorCalls(p, 80, 80, 60, 30, 0.3, 2.1),
        rule: 'evenodd',
      );
    });

    test('styles and transforms of a sector fill', () async {
      await expectSectorPixels(
        'a gradient',
        (ctx) {
          final gradient = ctx.createLinearGradient(20, 0, 140, 0)
            ..addColorStop(0, '#ff0000')
            ..addColorStop(1, '#0000ff');
          ctx
            ..scale(2, 2)
            ..fillStyle = gradient;
        },
        (p) => sectorCalls(p, 80, 80, 60, 30, -0.5, 2.5),
      );
      await expectSectorPixels(
        'globalAlpha and a rotation',
        (ctx) => ctx
          ..scale(2, 2)
          ..translate(80, 80)
          ..rotate(0.7)
          ..globalAlpha = 0.5
          ..fillStyle = '#00aa00',
        (p) => sectorCalls(p, 0, 0, 60, 20, 0.2, 4),
      );
      await expectSectorPixels(
        'a mirror',
        (ctx) => ctx
          ..transform(-2, 0, 0, 2, 320, 0)
          ..fillStyle = '#aa00aa',
        (p) => sectorCalls(p, 80, 80, 60, 0, 0.4, 2.4),
      );
      await expectSectorPixels(
        'a device pixel ratio of 2.625',
        (ctx) => ctx
          ..scale(2.625, 2.625)
          ..fillStyle = '#ff6384',
        (p) => sectorCalls(p, 60, 60, 50, 25, 1.1, 3.3),
      );
      await expectSectorPixels(
        'a composite operation',
        (ctx) => ctx
          ..scale(2, 2)
          ..fillStyle = '#000000'
          ..fillRect(0, 0, 160, 80)
          ..globalCompositeOperation = 'xor'
          ..fillStyle = '#ff0000',
        (p) => sectorCalls(p, 80, 80, 60, 30, -0.5, 2.5),
      );
    });

    test('a doughnut of arcs with their borders', () async {
      void doughnut(UiCanvasContext ctx, {required bool built}) {
        ctx
          ..scale(2, 2)
          ..lineJoin = 'bevel'
          ..lineWidth = 2
          ..strokeStyle = '#ffffff';
        var start = -math.pi / 2;
        for (var i = 0; i < 24; i++) {
          final end = start + (0.1 + (i % 5) * 0.06);
          ctx
            ..save()
            ..fillStyle = 'hsla(${i * 15}, 70%, 50%, 0.8)'
            ..beginPath();
          sectorCalls(ctx, 80, 80, 70, 35, start, end);
          if (built) ctx.debugPath.path;
          ctx
            ..fill()
            ..beginPath();
          sectorCalls(ctx, 80, 80, 70, 35, start, end);
          ctx
            ..stroke()
            ..restore();
          start = end;
        }
      }

      final device = comparePixels(
        await renderContext(
          (ctx) => doughnut(ctx, built: false),
          width: 320,
          height: 320,
        ),
        await renderContext(
          (ctx) => doughnut(ctx, built: true),
          width: 320,
          height: 320,
        ),
      );
      expect(device.solidDiffering, 0, reason: '$device');
      expect(device.opaqueFlips, 0, reason: '$device');
      final fine = comparePixels(
        await supersampled((ctx) => doughnut(ctx, built: false)),
        await supersampled((ctx) => doughnut(ctx, built: true)),
      );
      expect(fine.maxChannel, lessThanOrEqualTo(24), reason: '$fine');
    });

    test('the arcs of ArcElement fill as sectors', () {
      // With no border, the current path after the draw is the path of the
      // fill (element.arc.ts:289-309).
      for (final inner in const [0.0, 25.0]) {
        final ctx = retina();
        ArcElement({
          'x': 80,
          'y': 80,
          'startAngle': 0.25,
          'endAngle': 2,
          'innerRadius': inner,
          'outerRadius': 60,
          'circumference': 1.75,
          'options': <String, Object?>{
            'backgroundColor': 'rgba(54, 162, 235, 0.45)',
            'borderColor': '#36A2EB',
            'borderWidth': 0,
            'circular': true,
          },
        }).draw(ctx);
        final sector = ctx.debugPath.singleSector;
        expect(sector, isNotNull, reason: 'inner $inner');
        expect(sector!.inner, inner * 2);
        expect(sector.radius, 120);
        expect(ctx.debugPath.debugBuilt, isFalse);
      }
    });
  });

  group('N5: a color for each instance of a short circle run', () {
    /// [dots] drawn with `drawCircle`, in order. The centers of the first
    /// [snapped] dots (all by default) are at the nearest 1/4 pixel, as the
    /// atlas of the circle batch places them.
    Future<Render> reference(List<_Dot> dots, {int? snapped}) =>
        _renderUi((canvas) {
          for (final (i, d) in dots.indexed) {
            final snap = i < (snapped ?? dots.length);
            double place(double v) => snap ? (v * 4).roundToDouble() / 4 : v;
            final c = ui.Offset(place(d.c.dx), place(d.c.dy));
            if (d.fill != null) {
              canvas.drawCircle(c, d.r, ui.Paint()..color = d.fill!);
            }
            if (d.stroke != null) {
              canvas.drawCircle(
                c,
                d.r,
                ui.Paint()
                  ..color = d.stroke!
                  ..style = ui.PaintingStyle.stroke
                  ..strokeWidth = d.width,
              );
            }
          }
        });

    /// Draws [dots] as `drawPointLegend` draws circles: a full circle, its
    /// fill and its stroke.
    void draw(UiCanvasContext ctx, List<_Dot> dots) {
      for (final d in dots) {
        ctx
          ..beginPath()
          ..arc(d.c.dx, d.c.dy, d.r, 0, 2 * math.pi)
          ..closePath();
        if (d.fill != null) {
          ctx
            ..fillStyle = _css(d.fill!)
            ..fill();
        }
        if (d.stroke != null) {
          ctx
            ..lineWidth = d.width
            ..strokeStyle = _css(d.stroke!)
            ..stroke();
        }
      }
    }

    /// The centers of [count] points in rows of 14, at fractional pixels.
    List<ui.Offset> centers(int count) => [
      for (var i = 0; i < count; i++)
        ui.Offset(8 + (i % 14) * 10.37, 8 + (i ~/ 14) * 9.61),
    ];

    const red = ui.Color(0x73FF6384);
    const blue = ui.Color(0x7336A2EB);
    const green = ui.Color(0xCC4BC0C0);
    const border = ui.Color(0xFF36A2EB);
    // The largest difference of one channel from the reference with the
    // centers of the batch, as in the group 'circle batch' of
    // canvas_ui_test.dart.
    const tolerance = 8;

    test('two colors that alternate make one run', () async {
      final dots = <_Dot>[
        for (final (i, c) in centers(80).indexed)
          (c: c, r: 3, fill: i.isEven ? red : blue, stroke: border, width: 1),
      ];
      late int pending;
      final port = await renderContext((ctx) {
        draw(ctx, dots);
        pending = ctx.debugPendingCircles;
      });
      expect(pending, 160);
      final diff = comparePixels(port, await reference(dots));
      expect(diff.maxChannel, lessThanOrEqualTo(tolerance), reason: '$diff');
    });

    test('fills and strokes of several colors', () async {
      final colors = [red, blue, green, border];
      final dots = <_Dot>[
        for (final (i, c) in centers(140).indexed)
          (
            c: c,
            r: 3.5,
            fill: i % 7 == 3 ? null : colors[i % 4],
            stroke: i % 5 == 1 ? null : colors[(i + 1) % 4],
            width: 1.5,
          ),
      ];
      final port = await renderContext((ctx) => draw(ctx, dots));
      final diff = comparePixels(port, await reference(dots));
      expect(diff.maxChannel, lessThanOrEqualTo(tolerance), reason: '$diff');
    });

    test('globalAlpha multiplies the color of each instance', () async {
      final dots = <_Dot>[
        for (final (i, c) in centers(40).indexed)
          (c: c, r: 3, fill: i.isEven ? red : green, stroke: border, width: 1),
      ];
      final port = await renderContext((ctx) {
        ctx.globalAlpha = 0.5;
        draw(ctx, dots);
      });
      final faded = <_Dot>[
        for (final d in dots)
          (
            c: d.c,
            r: d.r,
            fill: d.fill!.withValues(alpha: d.fill!.a * 0.5),
            stroke: d.stroke!.withValues(alpha: 0.5),
            width: d.width,
          ),
      ];
      final diff = comparePixels(port, await reference(faded));
      // A probe on flutter_tester (Skia on the CPU): the stroke of 1 pixel of
      // a translucent color blends some edge pixels twice, where the pieces
      // of its outline meet, and an opaque white stroke clamps them. Thus
      // the white sprite times the color gives up to 13 of 255 less on these
      // pixels than drawCircle with the color, and 3.5 % less ink in each
      // ring; the sprite of one color has the double blend. The fills have
      // no such pixels.
      expect(diff.maxChannel, lessThanOrEqualTo(16), reason: '$diff');
      expect(diff.solidDiffering, 0, reason: '$diff');
      expect(diff.inkRatio, lessThan(0.02), reason: '$diff');
    });

    test('a run of one color of 16 circles or more draws first', () async {
      final dots = <_Dot>[
        for (final (i, c) in centers(12).indexed)
          (c: c, r: 3, fill: i < 10 ? red : blue, stroke: border, width: 1),
      ];
      final pending = <int>[];
      final port = await renderContext((ctx) {
        for (final d in dots) {
          draw(ctx, [d]);
          pending.add(ctx.debugPendingCircles);
        }
      });
      // The run of the 10 red points has 20 circles: the first blue point
      // draws it and starts a new run.
      expect(pending, [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 2, 4]);
      // The red run draws with the atlas, the blue run with drawCircle.
      final diff = comparePixels(port, await reference(dots, snapped: 10));
      expect(diff.maxChannel, lessThanOrEqualTo(tolerance), reason: '$diff');
    });

    test('a short run of several colors draws with drawCircle', () async {
      final dots = <_Dot>[
        for (final (i, c) in centers(5).indexed)
          (
            c: c,
            r: 4,
            fill: [red, blue, green][i % 3],
            stroke: border,
            width: 2,
          ),
      ];
      final port = await renderContext((ctx) => draw(ctx, dots));
      final diff = comparePixels(port, await reference(dots, snapped: 0));
      expect(diff.differing, 0, reason: '$diff');
    });

    test('a long run of several colors takes several atlas calls', () async {
      final dots = <_Dot>[
        for (final (i, c) in centers(14 * 16).indexed)
          for (final dy in const [0.0, 2.5, 5.0])
            (
              c: c.translate(0, dy),
              r: 2,
              fill: [red, blue, green][(i + dy.round()) % 3],
              stroke: border,
              width: 1,
            ),
      ];
      expect(dots.length * 2, greaterThan(2 * maxAtlasInstances));
      final port = await renderContext((ctx) => draw(ctx, dots));
      final diff = comparePixels(port, await reference(dots));
      expect(diff.maxChannel, lessThanOrEqualTo(tolerance), reason: '$diff');
    });
  });
}
