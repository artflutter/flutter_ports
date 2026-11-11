// Original code, not ported from Chart.js: one native call for a fan of lines.
@TestOn('vm')
library;

// Keep canvas state transitions and their observations as separate steps.
// ignore_for_file: cascade_invocations

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CanvasCompositeOperation;
import 'package:flutter_chartjs_port/src/canvas/canvas_line_fan.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'line_fan_engine.dart';
import 'pixel_compare.dart';

// The twins of Chart.js ADR 0103. The route is the context method; its twin is
// the Canvas 2D sequence of the same lines on a new context. `flutter test`
// runs them on Skia on the CPU, and `flutter test --enable-impeller` on
// Impeller on Vulkan, where the route needs no switch. The CI job
// `test-impeller` runs the second form.

const double _x = 80.25;
const double _y = 79.75;
const ui.Color _translucent = ui.Color(0x80336699);

/// [count] end points around (x, y), each at its own fraction of a pixel.
List<double> _ends(
  int count, {
  double x = _x,
  double y = _y,
  double radius = 70,
}) => [
  for (var i = 0; i < count; i++) ...[
    x + math.cos(i * 2 * math.pi / count + 0.1) * radius,
    y + math.sin(i * 2 * math.pi / count + 0.1) * radius,
  ],
];

/// The Canvas 2D sequence of the lines.
void _ordinary(
  UiCanvasContext ctx,
  List<double> ends, {
  double x = _x,
  double y = _y,
}) {
  for (var i = 0; i < ends.length; i += 2) {
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineTo(ends[i], ends[i + 1]);
    ctx.stroke();
  }
}

/// The fan of the lines: true when the context takes it.
bool _fan(
  UiCanvasContext ctx,
  List<double> ends, {
  double x = _x,
  double y = _y,
}) => ctx.tryStrokeLineFan(x, y, ends.length ~/ 2, (out) {
  out.setAll(0, ends);
});

/// The current path of a context, as its state after a stroke.
String _pathOf(UiCanvasContext ctx) {
  final path = ctx.debugPath;
  return [
    path.isEmpty,
    path.hasSubpath,
    path.hasSingleLine,
    if (path.hasSingleLine) ...[
      path.lineX0,
      path.lineY0,
      path.lineX1,
      path.lineY1,
    ],
  ].join(' ');
}

/// The styles of a context, which neither form writes.
String _stylesOf(UiCanvasContext ctx) => [
  ctx.strokeStyle,
  ctx.fillStyle,
  ctx.lineWidth,
  ctx.lineCap,
  ctx.lineJoin,
  ctx.miterLimit,
  ctx.getLineDash(),
  ctx.lineDashOffset,
  ctx.globalAlpha,
  ctx.globalCompositeOperation,
].join(' ');

void _expectSame(Render a, Render b, [String? reason]) {
  final diff = comparePixels(a, b);
  expect(diff.differing, 0, reason: '$reason: $diff');
  expect(a.bytes, b.bytes, reason: reason);
}

/// Renders [ends] through the fan and through the Canvas 2D sequence, after
/// [setUp] and before [after], and compares the bytes and the state.
Future<Render> _twin({
  List<double>? ends,
  void Function(UiCanvasContext ctx)? setUp,
  void Function(UiCanvasContext ctx)? after,
  String? reason,
  double x = _x,
  double y = _y,
}) async {
  final lines = ends ?? _ends(40);
  String? fanPath;
  String? fanStyles;
  final fan = await renderContext((ctx) {
    ctx.strokeStyle = _translucent;
    setUp?.call(ctx);
    expect(
      _fan(ctx, lines, x: x, y: y),
      isTrue,
      reason: reason,
    );
    fanPath = _pathOf(ctx);
    fanStyles = _stylesOf(ctx);
    after?.call(ctx);
  });
  String? ordinaryPath;
  String? ordinaryStyles;
  final ordinary = await renderContext((ctx) {
    ctx.strokeStyle = _translucent;
    setUp?.call(ctx);
    _ordinary(ctx, lines, x: x, y: y);
    ordinaryPath = _pathOf(ctx);
    ordinaryStyles = _stylesOf(ctx);
    after?.call(ctx);
  });
  _expectSame(fan, ordinary, reason);
  expect(fanPath, ordinaryPath, reason: reason);
  expect(fanStyles, ordinaryStyles, reason: reason);
  return fan;
}

/// The content below the lines of the canvas comparisons.
void _background(ui.Canvas canvas) {
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 80, 160),
    ui.Paint()..color = const ui.Color(0xFF77CC44),
  );
  canvas.drawCircle(
    const ui.Offset(110, 80),
    40,
    ui.Paint()..color = const ui.Color(0x8066AAFF),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpLineFanEngine();

  group('the engine draws each line of one call as its own stroke', () {
    // The canvas alone: one `drawRawPoints` against a `drawLine` for each line.
    Future<Uint8List> render(
      void Function(ui.Canvas canvas) setUp,
      void Function(ui.Canvas canvas) draw,
    ) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      setUp(canvas);
      draw(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(160, 160);
      final data = await image.toByteData();
      image.dispose();
      picture.dispose();
      return data!.buffer.asUint8List();
    }

    Float32List points(int count) {
      final ends = _ends(count);
      final list = Float32List(count * 4);
      for (var i = 0; i < count; i++) {
        list[i * 4] = _x;
        list[i * 4 + 1] = _y;
        list[i * 4 + 2] = ends[i * 2];
        list[i * 4 + 3] = ends[i * 2 + 1];
      }
      return list;
    }

    Future<void> compare(
      ui.Paint paint,
      Float32List list, {
      void Function(ui.Canvas canvas) setUp = _background,
      String? reason,
    }) async {
      final lines = await render(setUp, (canvas) {
        for (var i = 0; i < list.length; i += 4) {
          canvas.drawLine(
            ui.Offset(list[i], list[i + 1]),
            ui.Offset(list[i + 2], list[i + 3]),
            paint,
          );
        }
      });
      final one = await render(setUp, (canvas) {
        canvas.drawRawPoints(ui.PointMode.lines, list, paint);
      });
      expect(one, lines, reason: reason);
    }

    ui.Paint stroke(
      ui.Color color,
      double width, {
      ui.StrokeCap cap = ui.StrokeCap.butt,
      ui.BlendMode mode = ui.BlendMode.srcOver,
    }) => ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..color = color
      ..strokeWidth = width
      ..strokeCap = cap
      ..blendMode = mode;

    test('each color, width and cap', () async {
      final list = points(60);
      for (final color in const [
        ui.Color(0xFF3366CC),
        ui.Color(0x80FF0000),
        ui.Color(0x1A000000),
      ]) {
        for (final width in const [0.25, 1.0, 1.5, 3.0, 9.0]) {
          for (final cap in ui.StrokeCap.values) {
            await compare(
              stroke(color, width, cap: cap),
              list,
              reason: '$color $width $cap',
            );
          }
        }
      }
    });

    test('each blend mode, opaque and translucent', () async {
      final list = points(60);
      for (final mode in ui.BlendMode.values) {
        await compare(
          stroke(const ui.Color(0x99CC3366), 2, mode: mode),
          list,
          reason: '$mode',
        );
        await compare(
          stroke(const ui.Color(0xFFCC3366), 2, mode: mode),
          list,
          reason: '$mode opaque',
        );
      }
    });

    test('a clip, a transform and many thin lines', () async {
      final paint = stroke(const ui.Color(0x80000000), 1.5);
      final list = points(60);
      await compare(
        paint,
        list,
        setUp: (c) => c.clipRect(const ui.Rect.fromLTWH(20.5, 10.25, 90, 70)),
      );
      await compare(
        paint,
        list,
        setUp: (c) => c.clipPath(
          ui.Path()..addOval(const ui.Rect.fromLTWH(15, 15, 110, 90)),
        ),
      );
      await compare(
        paint,
        list,
        setUp: (c) {
          c.translate(10.5, 20.25);
          c.scale(0.7, 0.7);
          c.rotate(0.3);
        },
      );
      await compare(stroke(const ui.Color(0x1A000000), 1), points(3000));
      await compare(stroke(const ui.Color(0xFF000000), 1), points(3000));
    });
  });

  group('a fan gives the bytes of separate strokes', () {
    test('translucent and opaque colors, each cap and each width', () async {
      for (final color in const [
        ui.Color(0xFF3366CC),
        _translucent,
        ui.Color(0x1A000000),
      ]) {
        for (final cap in ui.StrokeCap.values) {
          for (final width in const [0.25, 1.0, 1.5, 3.0, 9.0]) {
            final render = await _twin(
              setUp: (c) {
                c.strokeStyle = color;
                c.lineCap = cap;
                c.lineWidth = width;
              },
              reason: '$color $cap $width',
            );
            expect(render.ink, greaterThan(0));
          }
        }
      }
    });

    test('many lines over each other', () async {
      await _twin(ends: _ends(2000));
      await _twin(ends: _ends(2000, radius: 300));
      await _twin(
        ends: _ends(2000),
        setUp: (c) => c.strokeStyle = const ui.Color(0xFF000000),
      );
    });

    test('each direction, also an axis and a line below a pixel', () async {
      await _twin(
        ends: const [
          _x + 60,
          _y,
          _x - 60,
          _y,
          _x,
          _y + 60,
          _x,
          _y - 60,
          _x + 0.25,
          _y,
          _x,
          _y - 0.25,
        ],
      );
    });

    test('each composite operation', () async {
      for (final op in CanvasCompositeOperation.values) {
        await _twin(
          setUp: (c) {
            c.fillStyle = const ui.Color(0x8022AA44);
            c.fillRect(0, 0, 120, 70);
            c.globalCompositeOperation = op;
          },
          reason: '$op',
        );
      }
    });

    test('a clip of a rectangle, a rounded rectangle and a path', () async {
      for (final path in <void Function(UiCanvasContext)>[
        (c) => c.rect(20.5, 10.25, 90, 70),
        (c) => c.roundRect(20.5, 10.25, 90, 70, 12),
        (c) => c.arc(80, 80, 50.5, 0, 2 * math.pi),
        (c) {
          c.moveTo(10, 10);
          c.lineTo(150, 40);
          c.lineTo(40, 150);
          c.closePath();
        },
      ]) {
        await _twin(
          setUp: (c) {
            c.save();
            c.beginPath();
            path(c);
            c.clip();
          },
          after: (c) {
            c.restore();
            // A later draw outside the clip, on the same recording.
            c.fillStyle = const ui.Color(0xFF00AA00);
            c.fillRect(150, 150, 10, 10);
          },
        );
      }
    });

    test('each similarity transform', () async {
      for (final transform in <void Function(UiCanvasContext)>[
        (c) => c.setTransform(2.625, 0, 0, 2.625, 0, 0),
        (c) => c.scale(0.5, 0.5),
        (c) => c.translate(3.25, 7.5),
        (c) => c.rotate(0.4),
        (c) {
          c.translate(160, 0);
          c.scale(-1, 1);
        },
        (c) {
          c.translate(80, 80);
          c.rotate(2.2);
          c.scale(1.25, 1.25);
          c.translate(-80, -80);
        },
      ]) {
        await _twin(setUp: transform);
      }
    });

    test('global alpha', () async {
      final render = await _twin(setUp: (c) => c.globalAlpha = 0.4);
      expect(render.ink, greaterThan(0));
    });

    test('alpha 0 draws nothing, counts nothing, and keeps the path', () async {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.globalAlpha = 0;
      ctx.beginPath();
      ctx.arc(30, 30, 5, 0, 2 * math.pi);
      ctx.fill();
      expect(_fan(ctx, _ends(4)), isTrue);
      expect(ctx.isEmpty, isTrue);
      expect(ctx.debugPath.hasSingleLine, isTrue);
    });

    test('a color with bits beyond 8 and another color space', () async {
      await _twin(
        setUp: (c) => c.strokeStyle = const ui.Color.from(
          alpha: 0.5,
          red: 0.123,
          green: 0.456,
          blue: 0.789,
        ),
      );
      await _twin(
        setUp: (c) {
          c.strokeStyle = const ui.Color.from(
            alpha: 0.75,
            red: 1,
            green: 0.2,
            blue: 0.1,
            colorSpace: ui.ColorSpace.displayP3,
          );
        },
      );
    });
  });

  group('the batches of the context', () {
    test('a pending circle run draws first, in its order', () async {
      void circles(UiCanvasContext c) {
        c.fillStyle = const ui.Color(0xFFCC0000);
        for (var i = 0; i < 40; i++) {
          c.beginPath();
          c.arc(10.0 + i * 3, 80, 4, 0, 2 * math.pi);
          c.fill();
        }
        expect(c.debugPendingCircles, 40);
      }

      await _twin(
        setUp: circles,
        after: (c) => expect(c.debugPendingCircles, 0),
      );
    });

    test('a pending sector run draws first, in its order', () async {
      void sector(UiCanvasContext c) {
        final taken = c.tryDrawArcSector(
          x: 80,
          y: 80,
          outerRadius: 50,
          innerRadius: 0,
          startAngle: 0.25,
          endAngle: 2.5,
          backgroundColor: const ui.Color(0xFFCC0000),
          borderColor: const ui.Color(0xFFCC0000),
        );
        expect(taken, isTrue);
        expect(c.debugPendingSectors, 1);
      }

      await _twin(
        setUp: sector,
        after: (c) => expect(c.debugPendingSectors, 0),
      );
    });

    test('a fan with alpha 0 keeps a pending circle run', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.beginPath();
      ctx.arc(30, 30, 5, 0, 2 * math.pi);
      ctx.fill();
      expect(ctx.debugPendingCircles, 1);
      ctx.globalAlpha = 0;
      expect(_fan(ctx, _ends(4)), isTrue);
      expect(ctx.debugPendingCircles, 1);
    });

    test('one call is one draw of the split budget', () async {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.strokeStyle = _translucent;
      final ends = _ends(600);
      expect(_fan(ctx, ends), isTrue);
      expect(ctx.debugPictureCount, 1);
      for (var i = 1; i < 255; i++) {
        expect(_fan(ctx, ends), isTrue);
      }
      expect(ctx.debugPictureCount, 1);
      // The draw that reaches the limit ends the recording. Its picture stays,
      // and no new recording has content yet.
      expect(_fan(ctx, ends), isTrue);
      expect(ctx.debugPictureCount, 1);
      expect(_fan(ctx, ends), isTrue);
      expect(ctx.debugPictureCount, 2);

      final separate = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(separate.dispose);
      separate.strokeStyle = _translucent;
      _ordinary(separate, ends);
      expect(separate.debugPictureCount, 3);
    });

    test('a fan over the split budget keeps the pixels', () async {
      await _twin(
        setUp: (c) {
          c.fillStyle = const ui.Color(0xFF22AA44);
          for (var i = 0; i < 255; i++) {
            c.fillRect(i * 0.5, 40, 1, 40);
          }
        },
        after: (c) {
          c.fillStyle = const ui.Color(0x80AA2244);
          c.fillRect(0, 60, 160, 40);
        },
      );
    });

    test('the clips replay on the recording after a split', () async {
      await _twin(
        ends: _ends(40),
        setUp: (c) {
          c.save();
          c.beginPath();
          c.rect(20.5, 10.25, 90, 70);
          c.clip();
          c.fillStyle = const ui.Color(0xFF22AA44);
          for (var i = 0; i < 255; i++) {
            c.fillRect(i * 0.5, 40, 1, 40);
          }
        },
        after: (c) {
          c.fillStyle = const ui.Color(0x80AA2244);
          c.fillRect(0, 60, 160, 40);
          c.restore();
        },
      );
    });
  });

  group('the state after a fan is the state after the last stroke', () {
    test('a second stroke of the current path', () async {
      await _twin(after: (c) => c.stroke());
    });

    test('a path that goes on', () async {
      await _twin(
        after: (c) {
          c.lineTo(10, 150);
          c.stroke();
        },
      );
    });

    test('a fill and a clip of the current path', () async {
      await _twin(
        after: (c) {
          c.fillStyle = const ui.Color(0x8000AA00);
          c.lineTo(10, 150);
          c.closePath();
          c.fill();
        },
      );
      await _twin(
        after: (c) {
          c.lineTo(10, 150);
          c.closePath();
          c.save();
          c.clip();
          c.fillStyle = const ui.Color(0x8000AA00);
          c.fillRect(0, 0, 160, 160);
          c.restore();
        },
      );
    });

    test('the path does not build for the fan', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.beginPath();
      ctx.moveTo(1, 1);
      ctx.lineTo(2, 3);
      ctx.lineTo(9, 9);
      ctx.debugPath.path;
      expect(ctx.debugPath.debugBuilt, isTrue);
      expect(_fan(ctx, _ends(4)), isTrue);
      expect(ctx.debugPath.debugBuilt, isFalse);
      expect(ctx.debugPath.hasSingleLine, isTrue);
    });

    test('the last end point is the current path, in bitmap space', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.setTransform(2, 0, 0, 2, 3, 4);
      expect(_fan(ctx, const [40, 30, 50, 20], x: 10, y: 20), isTrue);
      expect(ctx.debugPath.lineX0, 23);
      expect(ctx.debugPath.lineY0, 44);
      expect(ctx.debugPath.lineX1, 103);
      expect(ctx.debugPath.lineY1, 44);
    });

    test('a notified context stays notified, once until the next paint', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      var calls = 0;
      ctx.onChanged = () => calls++;
      ctx.beginPath();
      ctx.moveTo(1, 1);
      ctx.lineTo(9, 9);
      ctx.stroke();
      expect(calls, 1);
      expect(_fan(ctx, _ends(4)), isTrue);
      expect(calls, 1);
    });

    test('the same list serves the next fan of its size', () async {
      final render = await renderContext((ctx) {
        ctx.strokeStyle = _translucent;
        expect(_fan(ctx, _ends(40)), isTrue);
        ctx.clearRect(0, 0, 160, 160);
        expect(_fan(ctx, _ends(7)), isTrue);
        expect(_fan(ctx, _ends(7, radius: 30)), isTrue);
      });
      final twin = await renderContext((ctx) {
        ctx.strokeStyle = _translucent;
        _ordinary(ctx, _ends(7));
        _ordinary(ctx, _ends(7, radius: 30));
      });
      _expectSame(render, twin);
    });
  });

  group('a fan declines with no change', () {
    /// A context with a path, a pending circle and content: no decline may
    /// touch them. It returns the context after [setUp] and the check.
    void declines(
      String name, {
      void Function(UiCanvasContext ctx)? setUp,
      List<double>? ends,
      double x = _x,
      double y = _y,
      bool readsEnds = false,
    }) {
      test(name, () {
        final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
        addTearDown(ctx.dispose);
        var calls = 0;
        ctx.onChanged = () => calls++;
        ctx.strokeStyle = _translucent;
        ctx.fillRect(1, 1, 2, 2);
        expect(calls, 1);
        setUp?.call(ctx);
        ctx.beginPath();
        ctx.arc(30, 30, 5, 0, 2 * math.pi);
        ctx.fill();
        final pending = ctx.debugPendingCircles;
        ctx.beginPath();
        ctx.moveTo(1, 2);
        ctx.lineTo(3, 4);
        final path = _pathOf(ctx);
        final styles = _stylesOf(ctx);
        final pictures = ctx.debugPictureCount;
        final notified = calls;

        var reads = 0;
        final lines = ends ?? _ends(4);
        final taken = ctx.tryStrokeLineFan(x, y, lines.length ~/ 2, (out) {
          reads++;
          out.setAll(0, lines);
        });

        expect(taken, isFalse);
        expect(reads, readsEnds ? 1 : 0);
        expect(_pathOf(ctx), path);
        expect(_stylesOf(ctx), styles);
        expect(ctx.debugPendingCircles, pending);
        expect(ctx.debugPictureCount, pictures);
        expect(calls, notified);
      });
    }

    declines('a dash', setUp: (c) => c.setLineDash([3, 2]));
    declines(
      'a gradient',
      setUp: (c) {
        c.strokeStyle = c.createLinearGradient(0, 0, 160, 0)
          ..addColorStop(0, const ui.Color(0xFFFF0000))
          ..addColorStop(1, const ui.Color(0xFF0000FF));
      },
    );
    declines('another transform', setUp: (c) => c.scale(2, 1));
    declines('a skew', setUp: (c) => c.transform(1, 0, 0.5, 1, 0, 0));
    declines('a single line', ends: const [1, 2]);
    declines('no line', ends: const []);
    declines('a start that is not a number', x: double.nan);
    declines('a start at infinity', y: double.infinity);
    declines('a start too far', x: 1e31);
    declines(
      'an end that is not a number',
      ends: const [1, 2, double.nan, 4],
      readsEnds: true,
    );
    declines(
      'an end at infinity',
      ends: const [1, 2, 3, double.infinity],
      readsEnds: true,
    );
    declines('an end too far', ends: const [1, 2, 3e30, 4], readsEnds: true);
    declines(
      'a line with no length',
      ends: const [1, 2, _x, _y],
      readsEnds: true,
    );

    test('a transform that is not invertible', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.scale(0, 0);
      expect(_fan(ctx, _ends(4)), isFalse);
    });

    test('a disposed context', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      ctx.dispose();
      expect(_fan(ctx, _ends(4)), isFalse);
    });

    test('a context whose next draw would notify', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      var calls = 0;
      ctx.onChanged = () => calls++;
      expect(_fan(ctx, _ends(4)), isFalse);
      expect(calls, 0);
      ctx.onChanged = null;
      expect(_fan(ctx, _ends(4)), isTrue);
    });

    test('an observer of a picture or an image', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      void pictureObserver(ui.Picture _) {}
      void imageObserver(ui.Image _) {}
      addTearDown(() {
        ui.Picture.onCreate = null;
        ui.Picture.onDispose = null;
        ui.Image.onCreate = null;
        ui.Image.onDispose = null;
      });
      ui.Picture.onCreate = pictureObserver;
      expect(_fan(ctx, _ends(4)), isFalse);
      ui.Picture.onCreate = null;
      ui.Picture.onDispose = pictureObserver;
      expect(_fan(ctx, _ends(4)), isFalse);
      ui.Picture.onDispose = null;
      ui.Image.onCreate = imageObserver;
      expect(_fan(ctx, _ends(4)), isFalse);
      ui.Image.onCreate = null;
      ui.Image.onDispose = imageObserver;
      expect(_fan(ctx, _ends(4)), isFalse);
      ui.Image.onDispose = null;
      expect(_fan(ctx, _ends(4)), isTrue);
    });

    test('an engine with no Impeller, with no switch of the tests', () {
      UiCanvasContext.debugLineFanWithoutImpeller = false;
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      expect(
        _fan(ctx, _ends(4)),
        ui.ImageFilter.isShaderFilterSupported,
      );
    });

    test('the context is the capability', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      expect(ctx, isA<LineFanCanvas>());
    });
  });

  test('a job of CI runs the twins on Impeller and requires that engine', () {
    var dir = Directory.current.absolute;
    while (!File('${dir.path}/.github/workflows/ci.yaml').existsSync()) {
      expect(dir.parent.path, isNot(dir.path), reason: 'no repository root');
      dir = dir.parent;
    }
    final lines = File(
      '${dir.path}/.github/workflows/ci.yaml',
    ).readAsLinesSync();
    final start = lines.indexOf('  test-impeller:');
    expect(start, isNot(-1), reason: 'ci.yaml has no job test-impeller');
    final job = lines
        .skip(start + 1)
        .takeWhile((line) => !RegExp(r'^  \S').hasMatch(line))
        .toList();
    expect(job, contains(matches(r'^\s+CHART_IMPELLER: "1"$')));
    expect(
      job,
      contains(
        matches(r'^\s+working-directory: packages/flutter_chartjs_port$'),
      ),
    );
    final run = job.firstWhere(
      (line) => RegExp(r'^\s+run: flutter test ').hasMatch(line),
      orElse: () => '',
    );
    expect(run, contains('--enable-impeller'));
    expect(run, contains('test/port/canvas/canvas_line_fan_test.dart'));
    expect(
      run,
      contains('test/port/scales/scale.radialLinear_line_fan_test.dart'),
    );
  });
}
