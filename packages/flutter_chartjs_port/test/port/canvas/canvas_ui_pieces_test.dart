// Original code, not ported from Chart.js: long paths in pieces.
@TestOn('vm')
library;

// Canvas observations are deliberately separate from mutations.
// ignore_for_file: cascade_invocations

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_path.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

const _blue = ui.Color(0xff4f6bed);
const _soft = ui.Color(0x264f6bed);
const _half = ui.Color(0x804f6bed);

const double _base = 280;

double _end(int count) => 10 + (count - 1) * 480 / count;

/// A line that goes up in x.
void _top(
  CanvasPath path,
  int count, {
  bool curved = true,
  double noise = 40,
}) {
  final r = math.Random(3);
  double y(int i) =>
      150 + 60 * math.sin(i * .01) + noise * (r.nextDouble() - .5);
  final step = 480 / count;
  var px = 10.0;
  var py = y(0);
  path.moveTo(px, py);
  for (var i = 1; i < count; i++) {
    final x = 10 + i * step;
    final ny = y(i);
    if (curved) {
      path.bezierCurveTo(px + step * .3, py, x - step * .3, ny, x, ny);
    } else {
      path.lineTo(x, ny);
    }
    px = x;
    py = ny;
  }
}

/// The path of a filler: the line, the base with its doubled points, a close.
void _shape(
  CanvasPath path,
  int count, {
  bool curved = true,
  double noise = 40,
}) {
  _top(path, count, curved: curved, noise: noise);
  path
    ..lineTo(_end(count), _base)
    ..lineTo(_end(count), _base)
    ..lineTo(10, _base)
    ..lineTo(10, _base)
    ..closePath();
}

typedef _Setup = void Function(UiCanvasContext ctx);
void _none(UiCanvasContext ctx) {}
void _shifted(UiCanvasContext ctx) => ctx.setTransform(1, 0, 0, 1, .25, .5);
void _double(UiCanvasContext ctx) => ctx.setTransform(.5, 0, 0, .5, 0, 0);

/// Fills [shape] in both forms, and gives the two renders.
Future<(Render, Render, int)> _fills(
  void Function(CanvasPath) shape, {
  _Setup setup = _none,
  ui.Color color = _soft,
  String? rule,
}) async {
  var draws = -1;
  Future<Render> one({required bool pieces}) => renderContext(
    (ctx) {
      UiCanvasContext.debugDrawLongPathsInPieces = pieces;
      setup(ctx);
      ctx.fillStyle = color;
      ctx.beginPath();
      if (pieces) ctx.deferCurrentPath();
      shape(ctx);
      if (rule == null) {
        ctx.fill();
      } else {
        ctx.fill(rule);
      }
      if (pieces) draws = ctx.debugPieceDraws;
    },
    width: 500,
    height: 300,
  );
  return (await one(pieces: false), await one(pieces: true), draws);
}

/// Strokes [shape] as a `Path2D` in both forms.
Future<(Render, Render, int)> _strokes(
  void Function(CanvasPath) shape, {
  _Setup setup = _none,
  ui.Color color = _blue,
  double width = 2,
}) async {
  var draws = -1;
  Future<Render> one({required bool pieces}) => renderContext(
    (ctx) {
      UiCanvasContext.debugDrawLongPathsInPieces = pieces;
      setup(ctx);
      ctx.strokeStyle = color;
      ctx.lineWidth = width;
      final path = Path2D();
      shape(path);
      ctx.stroke(path);
      if (pieces) draws = ctx.debugPieceDraws;
    },
    width: 500,
    height: 300,
  );
  return (await one(pieces: false), await one(pieces: true), draws);
}

/// The look holds: no pixel flips, and the inked area stays within 1.5%. The
/// test engine draws on the CPU and takes another anti-aliasing for a complex
/// path, so that edge pixels differ with no change of shape.
void _sameLook(Render a, Render b) {
  final diff = comparePixels(a, b);
  expect(diff.opaqueFlips, 0, reason: '$diff');
  expect(diff.solidDiffering, 0, reason: '$diff');
  expect(diff.inkRatio, lessThan(.015), reason: '$diff');
}

void main() {
  tearDown(() => UiCanvasContext.debugDrawLongPathsInPieces = false);

  group('the fill', () {
    for (final (count, curved, noise) in [
      (200, true, 40.0),
      (1000, true, 40.0),
      (1000, false, 40.0),
      (5000, true, 40.0),
      (5000, false, 40.0),
      (5000, true, 200.0),
      (20000, false, 40.0),
    ]) {
      for (final color in [_soft, _blue]) {
        test('$count points, curved $curved, noise $noise, $color', () async {
          void shape(CanvasPath p) =>
              _shape(p, count, curved: curved, noise: noise);
          for (final setup in [_none, _shifted, _double]) {
            final (a, b, draws) = await _fills(
              shape,
              setup: setup,
              color: color,
            );
            expect(draws, 1);
            _sameLook(a, b);
          }
        });
      }
    }

    test('each column belongs to one piece: no seam at sparse points', () async {
      // Few and wide segments with one straight edge: the pieces must give the
      // bytes of the whole shape in a translucent and in an opaque color.
      void shape(CanvasPath p) {
        p.moveTo(10, 100);
        for (var i = 1; i < 200; i++) {
          p.lineTo(10 + i * 2.4, 100);
        }
        p
          ..lineTo(10 + 199 * 2.4, _base)
          ..lineTo(10, _base)
          ..closePath();
      }

      for (final color in [_soft, _blue]) {
        final (a, b, draws) = await _fills(shape, color: color);
        expect(draws, 1);
        expect(comparePixels(a, b).differing, 0);
      }
    });

    test('no seam at a place or a scale off the pixel grid', () async {
      for (final color in [_soft, _blue]) {
        for (final (x, y, scale) in [
          (.25, .0, 1.0),
          (.5, .25, 1.0),
          (10.5, .0, 1.0),
          (.0, .0, .75),
          (.3, .0, .9),
        ]) {
          Future<Render> one({required bool pieces}) async {
            UiCanvasContext.debugDrawLongPathsInPieces = pieces;
            final ctx = UiCanvasElement(width: 500, height: 300).getContext2d();
            ctx.fillStyle = color;
            ctx.beginPath();
            if (pieces) ctx.deferCurrentPath();
            _shape(ctx, 5000);
            ctx.fill();
            final recorder = ui.PictureRecorder();
            ctx.paint(ui.Canvas(recorder), ui.Offset(x, y), scale, 1);
            final picture = recorder.endRecording();
            final image = await picture.toImage(520, 320);
            final data = await image.toByteData();
            image.dispose();
            picture.dispose();
            ctx.dispose();
            return Render(data!.buffer.asUint8List(), 520, 320);
          }

          final diff = comparePixels(
            await one(pieces: false),
            await one(pieces: true),
          );
          expect(diff.inkRatio, lessThan(.015), reason: '$x $y $scale $diff');
          expect(diff.opaqueFlips, 0, reason: '$x $y $scale $diff');
        }
      }
    });

    test('a closing curve after a vertical edge keeps one draw', () async {
      void shape(CanvasPath p) {
        p.moveTo(100, 20);
        for (var i = 0; i < 199; i++) {
          p.lineTo(100, 20.0 + i);
        }
        p
          ..bezierCurveTo(300, 60, 300, 260, 100, 250)
          ..closePath();
      }

      final (a, b, draws) = await _fills(shape);
      expect(draws, 0);
      expect(comparePixels(a, b).differing, 0);
    });

    test('a vertex past the float range keeps one draw', () async {
      void shape(CanvasPath p) {
        p.moveTo(10, 100);
        for (var i = 1; i < 200; i++) {
          p.lineTo(10 + i * 2.0, i == 100 ? -1e38 : 100);
        }
        p
          ..lineTo(10 + 199 * 2.0, _base)
          ..lineTo(10, _base)
          ..closePath();
      }

      final (a, b, draws) = await _fills(shape);
      expect(draws, 0);
      expect(comparePixels(a, b).differing, 0);
    });

    test('both fill rules', () async {
      void shape(CanvasPath p) => _shape(p, 1000);
      final (a, b, draws) = await _fills(shape, rule: 'evenodd');
      expect(draws, 1);
      _sameLook(a, b);
    });

    test('the current path stays for a later read', () async {
      Future<Render> one({required bool pieces}) => renderContext(
        (ctx) {
          UiCanvasContext.debugDrawLongPathsInPieces = pieces;
          ctx.fillStyle = _soft;
          ctx.beginPath();
          if (pieces) ctx.deferCurrentPath();
          _shape(ctx, 1000);
          ctx.fill();
          if (pieces) {
            expect(ctx.debugPath.debugBuilt, isFalse);
            expect(ctx.debugPieceDraws, 1);
          }
          ctx.strokeStyle = const ui.Color(0xffdd4400);
          ctx.lineWidth = .6;
          ctx.stroke();
        },
        width: 500,
        height: 300,
      );
      _sameLook(await one(pieces: false), await one(pieces: true));
    });

    for (final (name, shape) in <(String, void Function(CanvasPath))>[
      ('a short path', (p) => _shape(p, 100)),
      (
        'a line that goes back in x',
        (p) {
          _top(p, 1000);
          p
            ..lineTo(30, 120)
            ..lineTo(30, _base)
            ..lineTo(10, _base)
            ..closePath();
        },
      ),
      (
        'a slanted side',
        (p) {
          _top(p, 1000);
          p
            ..lineTo(_end(1000) - 40, _base)
            ..lineTo(10, _base)
            ..closePath();
        },
      ),
      (
        'a slanted base',
        (p) {
          _top(p, 1000);
          p
            ..lineTo(_end(1000), _base)
            ..lineTo(10, _base - 40)
            ..closePath();
        },
      ),
      (
        'no close',
        (p) {
          _top(p, 1000);
          p
            ..lineTo(_end(1000), _base)
            ..lineTo(10, _base);
        },
      ),
      (
        'two subpaths',
        (p) {
          _shape(p, 1000);
          _shape(p, 1000);
        },
      ),
      (
        'an arc',
        (p) {
          _top(p, 1000);
          p
            ..arc(400, 200, 20, 0, 3)
            ..lineTo(_end(1000), _base)
            ..lineTo(10, _base)
            ..closePath();
        },
      ),
      (
        'a control point outside its segment',
        (p) {
          p.moveTo(10, 100);
          for (var i = 1; i < 200; i++) {
            p.bezierCurveTo(
              10 + i * 2.4 + 30,
              90,
              10 + i * 2.4,
              110,
              10 + i * 2.4,
              100,
            );
          }
          p
            ..lineTo(10 + 199 * 2.4, _base)
            ..lineTo(10, _base)
            ..closePath();
        },
      ),
    ]) {
      test('$name keeps one draw with the same bytes', () async {
        final (a, b, draws) = await _fills(shape);
        expect(draws, 0);
        expect(comparePixels(a, b).differing, 0);
      });
    }

    test('a shader and another blend mode keep one draw', () async {
      for (final style in [0, 1]) {
        Future<Render> one({required bool pieces}) => renderContext(
          (ctx) {
            UiCanvasContext.debugDrawLongPathsInPieces = pieces;
            if (style == 0) {
              ctx.fillStyle = ctx.createLinearGradient(0, 0, 500, 0)
                ..addColorStop(0, _blue)
                ..addColorStop(1, _soft);
            } else {
              ctx
                ..fillStyle = _soft
                ..globalCompositeOperation = CanvasCompositeOperation.multiply;
            }
            ctx.beginPath();
            if (pieces) ctx.deferCurrentPath();
            _shape(ctx, 1000);
            ctx.fill();
            if (pieces) expect(ctx.debugPieceDraws, 0);
          },
          width: 500,
          height: 300,
        );
        expect(
          comparePixels(
            await one(pieces: false),
            await one(pieces: true),
          ).differing,
          0,
        );
      }
    });
  });

  group('the stroke', () {
    for (final (count, curved, noise) in [
      (200, true, 40.0),
      (1000, true, 40.0),
      (1000, false, 40.0),
      (5000, true, 40.0),
      (5000, false, 40.0),
      (5000, true, 200.0),
      (20000, false, 40.0),
    ]) {
      for (final color in [_blue, _half]) {
        test('$count points, curved $curved, noise $noise, $color', () async {
          void shape(CanvasPath p) =>
              _top(p, count, curved: curved, noise: noise);
          for (final setup in [_none, _shifted, _double]) {
            final (a, b, draws) = await _strokes(
              shape,
              setup: setup,
              color: color,
            );
            // A translucent line of one pixel keeps one draw.
            expect(draws, color == _half && setup == _double ? 0 : 1);
            _sameLook(a, b);
          }
        });
      }
    }

    test('a closed path and several subpaths', () async {
      void loop(CanvasPath p) {
        p.moveTo(250 + 120, 150);
        for (var i = 1; i < 400; i++) {
          final a = i * math.pi * 2 / 400;
          final r = 120 + 10 * math.sin(i * .7);
          p.lineTo(250 + r * math.cos(a), 150 + r * math.sin(a));
        }
        p.closePath();
      }

      void gaps(CanvasPath p) {
        for (var s = 0; s < 3; s++) {
          p.moveTo(10, 40.0 + s * 80);
          for (var i = 1; i < 300; i++) {
            p.lineTo(10 + i * 1.6, 40 + s * 80 + 20 * math.sin(i * .3));
          }
        }
      }

      for (final shape in [loop, gaps]) {
        for (final color in [_blue, _half]) {
          final (a, b, draws) = await _strokes(shape, color: color);
          expect(draws, 1);
          _sameLook(a, b);
        }
      }
    });

    test('a coordinate that is not finite and a path with no start', () async {
      void shape(CanvasPath p) {
        p.lineTo(10, 10);
        for (var i = 1; i < 300; i++) {
          if (i % 50 == 0) p.lineTo(double.nan, 3);
          if (i % 70 == 0) {
            p.bezierCurveTo(double.infinity, 3, 4, 5, 6, 7);
          }
          p.lineTo(10 + i * 1.6, 100 + 30 * math.sin(i * .4));
        }
      }

      final (a, b, draws) = await _strokes(shape);
      expect(draws, 1);
      _sameLook(a, b);
    });

    test('short paths and other commands keep one draw', () async {
      for (final shape in <void Function(CanvasPath)>[
        (p) => _top(p, 100),
        (p) {
          _top(p, 300);
          p.arc(100, 100, 20, 0, 3);
        },
        (p) {
          _top(p, 300);
          p.quadraticCurveTo(10, 10, 20, 20);
        },
        (p) {
          _top(p, 300);
          p.rect(10, 10, 20, 20);
        },
      ]) {
        final (a, b, draws) = await _strokes(shape);
        expect(draws, 0);
        expect(comparePixels(a, b).differing, 0);
      }
    });

    test(
      'a dash, a cap, a shader, a blend mode and a skew keep one draw',
      () async {
        for (final setup in <_Setup>[
          (ctx) => ctx.setLineDash(const [4, 2]),
          (ctx) => ctx.lineCap = 'round',
          (ctx) =>
              ctx.globalCompositeOperation = CanvasCompositeOperation.multiply,
          (ctx) => ctx.setTransform(1, 0, .3, 1, 0, 0),
          (ctx) => ctx.setTransform(2, 0, 0, 1, 0, 0),
        ]) {
          final (a, b, draws) = await _strokes(
            (p) => _top(p, 300),
            setup: setup,
          );
          expect(draws, 0);
          expect(comparePixels(a, b).differing, 0);
        }
        final (a, b) = await () async {
          Future<Render> one({required bool pieces}) => renderContext(
            (ctx) {
              UiCanvasContext.debugDrawLongPathsInPieces = pieces;
              ctx.strokeStyle = ctx.createLinearGradient(0, 0, 500, 0)
                ..addColorStop(0, _blue)
                ..addColorStop(1, _soft);
              final path = Path2D();
              _top(path, 300);
              ctx.stroke(path);
              if (pieces) expect(ctx.debugPieceDraws, 0);
            },
            width: 500,
            height: 300,
          );
          return (await one(pieces: false), await one(pieces: true));
        }();
        expect(comparePixels(a, b).differing, 0);
      },
    );

    test('the pieces of a path stay until it changes', () {
      final path = Path2D();
      _top(path, 300);
      final first = uiPathPiecesOf(path, 1, 2)!;
      expect(identical(uiPathPiecesOf(path, 1, 2), first), isTrue);
      // The whole path of the same cache stays free.
      final whole = uiPathOf(path);
      expect(identical(uiPathOf(path), whole), isTrue);
      expect(identical(uiPathPiecesOf(path, 1, 2), first), isTrue);
      path.lineTo(1, 1);
      expect(identical(uiPathPiecesOf(path, 1, 2), first), isFalse);
      expect(identical(uiPathOf(path), whole), isFalse);
    });

    test('a piece has at most its commands and its area', () {
      final pieces = UiPathPieces(1, 2);
      pieces.moveTo(0, 0);
      for (var i = 1; i <= 1000; i++) {
        pieces.lineTo(i * .01, 0);
      }
      pieces.finish();
      expect(
        pieces.pieces.length,
        greaterThanOrEqualTo(1000 ~/ maxPieceCommands),
      );
      final wide = UiPathPieces(1, 2);
      wide.moveTo(0, 0);
      for (var i = 1; i <= 100; i++) {
        wide.lineTo(i * 5.0, i.isEven ? 0 : 400);
      }
      wide.finish();
      expect(wide.pieces.length, greaterThanOrEqualTo(5));
      for (final piece in wide.pieces) {
        final b = piece.getBounds();
        // One segment can pass the limit on its own, so the limit has room for
        // the last segment and the short line of the join.
        expect(b.width * b.height, lessThanOrEqualTo(maxPieceArea + 500 * 410));
      }
      expect(wide.bounds, const ui.Rect.fromLTRB(0, 0, 500, 400));
    });

    test('another scale or width makes new pieces', () {
      final path = Path2D();
      _top(path, 300);
      final first = uiPathPiecesOf(path, 1, 2)!;
      expect(identical(uiPathPiecesOf(path, 2, 2), first), isFalse);
      final second = uiPathPiecesOf(path, 2, 2)!;
      expect(identical(uiPathPiecesOf(path, 2, 2), second), isTrue);
      expect(identical(uiPathPiecesOf(path, 2, 3), second), isFalse);
    });

    test('a list that a reader got takes one draw', () {
      final path = Path2D();
      _top(path, 300);
      expect(uiPathPiecesOf(path, 1, 2), isNotNull);
      path.commands;
      expect(uiPathPiecesOf(path, 1, 2), isNull);
    });

    test('a coordinate past the float range takes one draw', () {
      final path = Path2D();
      _top(path, 300);
      path.lineTo(250, 1e38);
      expect(uiPathPiecesOf(path, 1, 2), isNull);
    });

    test('no seam across a smooth dense line', () async {
      void shape(CanvasPath p) {
        p.moveTo(10, 150);
        for (var i = 1; i < 5000; i++) {
          final x = 10 + i * .096;
          p.lineTo(x, 150 + 40 * math.sin(i * .002));
        }
      }

      for (final color in [_blue, _half]) {
        final (a, b, draws) = await _strokes(shape, color: color, width: 8);
        expect(draws, 1);
        final diff = comparePixels(a, b);
        expect(diff.inkRatio, lessThan(.015), reason: '$diff');
        // The pixels inside the line stay: a seam would change them. An edge
        // pixel under the short overlap of two pieces can differ.
        var inner = 0;
        var worst = 0;
        for (var y = 1; y < a.height - 1; y++) {
          for (var x = 1; x < a.width - 1; x++) {
            final alpha = a.alpha(x, y);
            if (alpha == 0) continue;
            var solid = true;
            for (var dy = -1; dy <= 1 && solid; dy++) {
              for (var dx = -1; dx <= 1 && solid; dx++) {
                solid = a.alpha(x + dx, y + dy) == alpha;
              }
            }
            if (!solid) continue;
            inner++;
            worst = math.max(worst, (alpha - b.alpha(x, y)).abs());
          }
        }
        expect(inner, greaterThan(1000));
        expect(worst, lessThanOrEqualTo(2), reason: '$inner inner pixels');
      }
    });

    for (final width in [6.0, 30.0]) {
      test('a turn at a cut keeps its join at width $width', () async {
        for (final build in <void Function(CanvasPath)>[
          (p) {
            // A zero-length line at the cut.
            p.moveTo(20, 40);
            for (var i = 1; i <= 64; i++) {
              p.lineTo(20 + i * 1.5, 40);
            }
            p
              ..lineTo(20 + 64 * 1.5, 40)
              ..lineTo(20 + 64 * 1.5, 240);
            for (var i = 1; i < 80; i++) {
              p.lineTo(20 + 64 * 1.5 + i * 1.5, 240);
            }
          },
          (p) {
            // A nearly straight curve at the cut.
            p.moveTo(20, 40);
            for (var i = 1; i <= 64; i++) {
              p.lineTo(20 + i * 1.5, 40);
            }
            p.bezierCurveTo(116.1, 60, 116, 200, 116, 200);
            for (var i = 1; i < 80; i++) {
              p.lineTo(116 + i * 1.5, 200);
            }
          },
          (p) {
            // A curve with both control points at its start.
            p.moveTo(20, 40);
            for (var i = 1; i <= 64; i++) {
              p.lineTo(20 + i * 1.5, 40);
            }
            p.bezierCurveTo(116, 40, 116, 40, 116, 200);
            for (var i = 1; i < 80; i++) {
              p.lineTo(116 + i * 1.5, 200);
            }
          },
        ]) {
          final (a, b, draws) = await _strokes(build, width: width);
          expect(draws, 1);
          expect(comparePixels(a, b).opaqueFlips, 0);
        }
      });
    }
  });
}
