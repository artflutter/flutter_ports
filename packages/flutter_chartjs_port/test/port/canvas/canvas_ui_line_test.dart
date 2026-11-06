// Original code, not ported from Chart.js: drawLine of a single-line stroke.
@TestOn('vm')
library;

// Keep canvas state transitions and their observations as separate steps.
// ignore_for_file: cascade_invocations

import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CanvasCompositeOperation;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

const _color = ui.Color(0xFF3366CC);

/// The two renders of the line, with `drawLine` and with the built path: a read
/// of the path before the stroke takes the path route.
Future<(Render, Render)> _twin({
  double x0 = 10.25,
  double y0 = 20.5,
  double x1 = 140.75,
  double y1 = 100.5,
  void Function(UiCanvasContext ctx)? setUp,
}) async {
  Future<Render> render({required bool built}) => renderContext((ctx) {
    ctx.strokeStyle = _color;
    ctx.lineWidth = 3;
    setUp?.call(ctx);
    ctx.beginPath();
    ctx.moveTo(x0, y0);
    ctx.lineTo(x1, y1);
    if (built) ctx.debugPath.path;
    ctx.stroke();
    if (x0 != x1 || y0 != y1) expect(ctx.debugPath.debugBuilt, built);
  });
  return (await render(built: false), await render(built: true));
}

void _expectSame(Render a, Render b, [String? reason]) {
  final diff = comparePixels(a, b);
  expect(diff.differing, 0, reason: '$reason: $diff');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a single-line stroke gives the pixels of the path', () {
    test('each direction of a line', () async {
      for (final (x0, y0, x1, y1) in const [
        (10.0, 20.0, 140.0, 20.0),
        (140.5, 20.5, 10.5, 20.5),
        (20.5, 10.0, 20.5, 140.0),
        (20.25, 140.75, 20.25, 10.25),
        (10.0, 10.0, 150.0, 150.0),
        (150.25, 12.5, 11.75, 149.0),
        (50.0, 50.0, 50.25, 50.0),
      ]) {
        final (a, b) = await _twin(x0: x0, y0: y0, x1: x1, y1: y1);
        _expectSame(a, b, '$x0,$y0 $x1,$y1');
        expect(a.ink, greaterThan(0));
      }
    });

    test('each cap and each width', () async {
      for (final cap in const ['butt', 'round', 'square']) {
        for (final width in const [0.25, 1.0, 1.5, 3.0, 9.0]) {
          final (a, b) = await _twin(
            setUp: (c) {
              c.lineCap = cap;
              c.lineWidth = width;
            },
          );
          _expectSame(a, b, '$cap $width');
        }
      }
    });

    test('a similarity transform', () async {
      for (final transform in <void Function(UiCanvasContext)>[
        (c) => c.setTransform(2.625, 0, 0, 2.625, 0, 0),
        (c) => c.scale(0.5, 0.5),
        (c) => c.translate(3.25, 7.5),
        (c) => c.rotate(0.4),
        (c) {
          c.translate(160, 0);
          c.scale(-1, 1);
        },
      ]) {
        final (a, b) = await _twin(setUp: transform);
        _expectSame(a, b);
      }
    });

    test('alpha, a gradient and each composite operation', () async {
      final (a, b) = await _twin(setUp: (c) => c.globalAlpha = 0.4);
      _expectSame(a, b);
      final (g0, g1) = await _twin(
        setUp: (c) {
          c.strokeStyle = c.createLinearGradient(0, 0, 160, 0)
            ..addColorStop(0, const ui.Color(0xFFFF0000))
            ..addColorStop(1, const ui.Color(0xFF0000FF));
        },
      );
      _expectSame(g0, g1);
      for (final op in CanvasCompositeOperation.values) {
        final (x, y) = await _twin(
          setUp: (c) {
            c.fillStyle = const ui.Color(0x8022AA44);
            c.fillRect(0, 0, 120, 70);
            c.globalCompositeOperation = op;
          },
        );
        _expectSame(x, y, '$op');
      }
    });

    test('alpha 0 draws nothing and counts nothing', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.globalAlpha = 0;
      ctx.beginPath();
      ctx.moveTo(1, 1);
      ctx.lineTo(9, 9);
      ctx.stroke();
      expect(ctx.isEmpty, isTrue);
    });
  });

  group('the path route stays', () {
    Future<void> expectBuilt(
      void Function(UiCanvasContext ctx) draw, {
      required bool built,
    }) async {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.strokeStyle = _color;
      draw(ctx);
      ctx.stroke();
      expect(ctx.debugPath.debugBuilt, built);
    }

    test('for a line', () async {
      await expectBuilt((c) {
        c.moveTo(1, 2);
        c.lineTo(9, 9);
      }, built: false);
    });
    test('for a line with no moveTo: its first point is a move', () async {
      await expectBuilt((c) {
        c.lineTo(1, 2);
        c.lineTo(9, 9);
      }, built: false);
    });
    test('for a dash', () async {
      await expectBuilt((c) {
        c.setLineDash([3, 2]);
        c.moveTo(1, 2);
        c.lineTo(9, 9);
      }, built: true);
    });
    test('for no length', () async {
      await expectBuilt((c) {
        c.moveTo(5, 5);
        c.lineTo(5, 5);
      }, built: true);
    });
    test('for two lines', () async {
      await expectBuilt((c) {
        c.moveTo(1, 2);
        c.lineTo(9, 9);
        c.lineTo(9, 1);
      }, built: true);
    });
    test('for a closed line', () async {
      await expectBuilt((c) {
        c.moveTo(1, 2);
        c.lineTo(9, 9);
        c.closePath();
      }, built: true);
    });
    test('for two moves', () async {
      await expectBuilt((c) {
        c.moveTo(1, 2);
        c.moveTo(3, 4);
      }, built: true);
    });
    test('for a transform that is no similarity', () async {
      await expectBuilt((c) {
        c.scale(2, 1);
        c.moveTo(1, 2);
        c.lineTo(9, 9);
      }, built: true);
    });
    test('for a mapped point that is not finite', () async {
      await expectBuilt((c) {
        c.setTransform(1, 0, 0, 1, 1e308, 0);
        c.moveTo(1e308, 2);
        c.lineTo(1e308, 9);
      }, built: true);
    });

    test('no length gives the pixels of the path, for each cap', () async {
      for (final cap in const ['butt', 'round', 'square']) {
        final (a, b) = await _twin(
          x0: 50,
          y0: 50,
          x1: 50,
          y1: 50,
          setUp: (c) => c.lineCap = cap,
        );
        _expectSame(a, b, cap);
      }
    });
  });

  group('the path after the stroke', () {
    test('holds the same commands', () async {
      for (final use in <void Function(UiCanvasContext)>[
        (c) => c.stroke(),
        (c) {
          c.lineTo(5, 150);
          c.stroke();
        },
        (c) {
          c.strokeStyle = const ui.Color(0xFF00AA00);
          c.lineWidth = 1;
          c.stroke();
        },
        (c) {
          c.lineTo(5, 150);
          c.closePath();
          c.fill();
        },
        (c) {
          c.lineTo(5, 150);
          c.clip();
          c.fillRect(0, 0, 160, 160);
        },
        (c) {
          c.arcTo(40, 40, 80, 10, 20);
          c.stroke();
        },
      ]) {
        Future<Render> render({required bool built}) => renderContext((c) {
          c.strokeStyle = _color;
          c.lineWidth = 3;
          c.beginPath();
          c.moveTo(10, 20);
          c.lineTo(140, 100);
          if (built) c.debugPath.path;
          c.stroke();
          use(c);
        });
        _expectSame(await render(built: false), await render(built: true));
      }
    });

    test('reads the commands of the path', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.setTransform(2, 0, 0, 2, 1, 1);
      ctx.moveTo(10, 20);
      ctx.lineTo(40, 20);
      ctx.stroke();
      expect(ctx.debugPath.debugBuilt, isFalse);
      expect(ctx.debugPath.hasSingleLine, isTrue);
      final metrics = ctx.debugPath.path.computeMetrics().toList();
      expect(metrics.single.length, 60);
      expect(metrics.single.isClosed, isFalse);
      expect(
        ctx.debugPath.path.getBounds(),
        const ui.Rect.fromLTRB(21, 41, 81, 41),
      );
      expect(ctx.debugPath.hasSingleLine, isFalse);
    });

    test('a stroke counts in the budget of the recording', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      for (var i = 0; i < 600; i++) {
        ctx.beginPath();
        ctx.moveTo(0, i % 160);
        ctx.lineTo(160, i % 160);
        ctx.stroke();
      }
      expect(ctx.debugPictureCount, greaterThan(1));
    });
  });
}
