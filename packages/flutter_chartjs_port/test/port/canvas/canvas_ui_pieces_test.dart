// Original code, not ported from Chart.js: long paths in pieces.
@TestOn('vm')
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' show Chart;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_path.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

const _blue = ui.Color(0xff4f6bed);
const _soft = ui.Color(0x264f6bed);
const _half = ui.Color(0x804f6bed);

const double _base = 280;

double _end(int count) => 10 + (count - 1) * 480 / count;

/// A line that goes up in x.
void _top(CanvasPath path, int count, {bool curved = true, double noise = 40}) {
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
      ctx
        ..fillStyle = color
        ..beginPath();
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

/// Strokes [shape] as a `Path2D` in both forms, with the line join [join], on
/// a canvas of 500 x [height] pixels.
Future<(Render, Render, int)> _strokes(
  void Function(CanvasPath) shape, {
  _Setup setup = _none,
  ui.Color color = _blue,
  double width = 2,
  ui.StrokeJoin join = ui.StrokeJoin.miter,
  int height = 300,
}) async {
  var draws = -1;
  Future<Render> one({required bool pieces}) => renderContext(
    (ctx) {
      UiCanvasContext.debugDrawLongPathsInPieces = pieces;
      setup(ctx);
      ctx
        ..strokeStyle = color
        ..lineWidth = width
        ..lineJoin = join;
      final path = Path2D();
      shape(path);
      ctx.stroke(path);
      if (pieces) draws = ctx.debugPieceDraws;
    },
    width: 500,
    height: height,
  );
  return (await one(pieces: false), await one(pieces: true), draws);
}

/// The systems that Flutter reports for a browser on a desktop (Chart.js ADR
/// 0113).
const _desktop = <TargetPlatform>[
  TargetPlatform.macOS,
  TargetPlatform.windows,
  TargetPlatform.linux,
];

/// The other systems. Null keeps the system of the test, Android, which
/// Flutter also reports for a browser on an unknown system.
const _otherSystems = <TargetPlatform?>[
  null,
  TargetPlatform.android,
  TargetPlatform.iOS,
  TargetPlatform.fuchsia,
];

/// Runs [body] with [platform] as the system of the browser, then restores
/// the system of the test.
Future<T> _on<T>(TargetPlatform? platform, Future<T> Function() body) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    return await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

/// A short line of [commands] commands on a canvas of 500 x 400 pixels, with
/// large jumps, so that the pieces cut it at most of its vertices. A [closed]
/// line has the form of the line of a radar: a move, the segments to the other
/// points, a segment back to the first point and a close.
void _shortLine(
  CanvasPath p,
  int commands, {
  required bool curved,
  required bool closed,
}) {
  final r = math.Random(commands * 4 + (curved ? 2 : 0) + (closed ? 1 : 0));
  final points = <(double, double)>[];
  if (closed) {
    // A move, the segments of the points after the first, a segment back to
    // the first point and a close.
    final count = math.max(commands - 2, 1);
    for (var i = 0; i < count; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / count;
      final radius = 40 + 150 * r.nextDouble();
      points.add((250 + radius * math.cos(a), 200 + radius * math.sin(a)));
    }
    if (commands >= 3) points.add(points.first);
  } else {
    for (var i = 0; i < commands; i++) {
      final x = commands == 1 ? 20.0 : 20 + i * 460 / (commands - 1);
      points.add((x, 30 + 340 * r.nextDouble()));
    }
  }
  final (x0, y0) = points.first;
  p.moveTo(x0, y0);
  for (var i = 1; i < points.length; i++) {
    final (px, py) = points[i - 1];
    final (x, y) = points[i];
    if (curved) {
      // The control points of a monotone line in x, and of a smooth ring.
      final dx = (x - px) * .3;
      final dy = closed ? (y - py) * .3 : 0;
      p.bezierCurveTo(px + dx, py + dy, x - dx, y - dy, x, y);
    } else {
      p.lineTo(x, y);
    }
  }
  if (closed) p.closePath();
}

/// The look holds: no pixel flips, and the inked area stays within 1.5%. The
/// test engine draws on the CPU and takes another anti-aliasing for a complex
/// path, so that edge pixels differ with no change of shape.
void _sameLook(Render a, Render b, [String why = '']) {
  final diff = comparePixels(a, b);
  expect(diff.opaqueFlips, 0, reason: '$why $diff');
  expect(diff.solidDiffering, 0, reason: '$why $diff');
  expect(diff.inkRatio, lessThan(.015), reason: '$why $diff');
}

/// The pixels whose alpha differs by at least [step] between [a] and [b]. For
/// a translucent line of the alpha [step], it counts a notch or a hole, which
/// the flip checks of [_sameLook] cannot see: they need alpha 0 or 255.
int _alphaJumps(Render a, Render b, int step) {
  var count = 0;
  for (var y = 0; y < a.height; y++) {
    for (var x = 0; x < a.width; x++) {
      if ((a.alpha(x, y) - b.alpha(x, y)).abs() >= step) count++;
    }
  }
  return count;
}

/// The bytes of the bitmap of [chart].
Future<Render> _chartRender(WidgetTester tester, Chart chart) async {
  final source = (chart.canvas! as UiCanvasElement).toImageSource();
  final data = await tester.runAsync(source.image.toByteData);
  final render = Render(
    data!.buffer.asUint8List(),
    source.image.width,
    source.image.height,
  );
  source.image.dispose();
  return render;
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

    // The fast path of a line ends its last pixel column at the average x of
    // the column, before the x of its last point, where the filler starts the
    // base: the side goes on in x. A line whose last point lies on the base
    // gives the same commands.
    for (final (count, curved, noise) in [
      (1000, false, 40.0),
      (5000, false, 40.0),
      (5000, false, 200.0),
      (20000, false, 40.0),
      (1000, true, 40.0),
    ]) {
      for (final step in [.37, .989, 30.0]) {
        for (final color in [_soft, _blue]) {
          test('a side that goes on in x by $step: $count points, curved '
              '$curved, noise $noise, $color', () async {
            void shape(CanvasPath p) {
              _top(p, count, curved: curved, noise: noise);
              p
                ..lineTo(_end(count) + step, _base)
                ..lineTo(_end(count) + step, _base)
                ..lineTo(10, _base)
                ..lineTo(10, _base)
                ..closePath();
            }

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
    }

    test('a side that goes on in x: no seam when sparse', () async {
      // Few and wide segments with one straight edge and a slanted side: the
      // pieces must give the bytes of the whole shape.
      for (final step in [.37, 30.0]) {
        void shape(CanvasPath p) {
          p.moveTo(10, 100);
          for (var i = 1; i < 200; i++) {
            p.lineTo(10 + i * 2.4, 100);
          }
          p
            ..lineTo(10 + 199 * 2.4 + step, _base)
            ..lineTo(10, _base)
            ..closePath();
        }

        for (final color in [_soft, _blue]) {
          final (a, b, draws) = await _fills(shape, color: color);
          expect(draws, 1);
          expect(comparePixels(a, b).differing, 0, reason: '$step $color');
        }
      }
    });

    test(
      'a side that goes on in x: a long side is a piece of its own',
      () async {
        // The side is the last line of the top edge, and its bounds pass the
        // area of a piece: the last piece has this one segment, with the base
        // below it, and ends at the first point of the base.
        void shape(CanvasPath p) {
          p.moveTo(10, 60);
          for (var i = 1; i < 300; i++) {
            p.lineTo(10 + i * .8, i.isEven ? 60 : 90);
          }
          p
            ..lineTo(460, _base)
            ..lineTo(460, _base)
            ..lineTo(10, _base)
            ..lineTo(10, _base)
            ..closePath();
        }

        for (final color in [_soft, _blue]) {
          for (final setup in [_none, _shifted, _double]) {
            final (a, b, draws) = await _fills(
              shape,
              setup: setup,
              color: color,
            );
            expect(draws, 1);
            _sameLook(a, b, '$color');
          }
        }
      },
    );

    test('a side that goes on in x: the top edge ends on the base', () async {
      // The last points of the line lie on the base. The base walk stops at
      // the last of them, which is then the end of the top edge.
      void shape(CanvasPath p) {
        _top(p, 1000, curved: false);
        p
          ..lineTo(_end(1000) + 2, _base)
          ..lineTo(_end(1000) + 4, _base)
          ..lineTo(_end(1000) + 4, _base)
          ..lineTo(10, _base)
          ..lineTo(10, _base)
          ..closePath();
      }

      for (final color in [_soft, _blue]) {
        for (final setup in [_none, _shifted, _double]) {
          final (a, b, draws) = await _fills(shape, setup: setup, color: color);
          expect(draws, 1);
          _sameLook(a, b, '$color');
        }
      }
    });

    test('each column belongs to one piece: no seam when sparse', () async {
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
            final ctx = UiCanvasElement(width: 500, height: 300).getContext2d()
              ..fillStyle = color
              ..beginPath();
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
          ctx
            ..fillStyle = _soft
            ..beginPath();
          if (pieces) ctx.deferCurrentPath();
          _shape(ctx, 1000);
          ctx.fill();
          if (pieces) {
            expect(ctx.debugPath.debugBuilt, isFalse);
            expect(ctx.debugPieceDraws, 1);
          }
          ctx
            ..strokeStyle = const ui.Color(0xffdd4400)
            ..lineWidth = .6
            ..stroke();
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
        'a side that goes back in x',
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
              ctx.fillStyle = const ChartGradient.linear(
                ui.Offset.zero,
                ui.Offset(500, 0),
                [_blue, _soft],
              );
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

    test('a short path keeps one draw off a desktop system', () async {
      for (final platform in _otherSystems) {
        await _on(platform, () async {
          expect(UiCanvasContext.strokePieceMinCommands, minPieceCommands);
          for (final commands in [2, 10, 100, minPieceCommands - 1]) {
            final (a, b, draws) = await _strokes((p) => _top(p, commands));
            expect(draws, 0, reason: '$platform $commands');
            expect(comparePixels(a, b).differing, 0);
          }
          final (a, b, draws) = await _strokes(
            (p) => _top(p, minPieceCommands),
          );
          expect(draws, 1, reason: '$platform');
          _sameLook(a, b);
        });
      }
    });

    test('a desktop system strokes a path in pieces from 2 commands', () async {
      for (final platform in _desktop) {
        await _on(platform, () async {
          expect(UiCanvasContext.strokePieceMinCommands, 2);
          final (a, b, draws) = await _strokes((p) => p.moveTo(10, 10));
          expect(draws, 0, reason: '$platform');
          expect(comparePixels(a, b).differing, 0);
          for (final commands in [2, 3, 100]) {
            final (a, b, draws) = await _strokes((p) => _top(p, commands));
            expect(draws, 1, reason: '$platform $commands');
            _sameLook(a, b);
          }
        });
      }
    });

    test('native apps keep one draw on a desktop system', () async {
      for (final platform in _desktop) {
        await _on(platform, () async {
          var draws = -1;
          await renderContext(
            (ctx) {
              UiCanvasContext.debugDrawLongPathsInPieces = false;
              ctx
                ..strokeStyle = _blue
                ..lineWidth = 2;
              final path = Path2D();
              _top(path, 100);
              ctx.stroke(path);
              draws = ctx.debugPieceDraws;
            },
            width: 500,
            height: 300,
          );
          expect(draws, 0, reason: '$platform');
        });
      }
    });

    test('other commands keep one draw', () async {
      for (final platform in [null, TargetPlatform.macOS]) {
        await _on(platform, () async {
          for (final shape in <void Function(CanvasPath)>[
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
            (p) => p
              ..moveTo(10, 10)
              ..arc(100, 100, 20, 0, 3),
          ]) {
            final (a, b, draws) = await _strokes(shape);
            expect(draws, 0, reason: '$platform');
            expect(comparePixels(a, b).differing, 0);
          }
        });
      }
    });

    test(
      'a dash, a cap, a shader, a blend mode and a skew keep one draw',
      () async {
        for (final setup in <_Setup>[
          (ctx) => ctx.setLineDash(const [4, 2]),
          (ctx) => ctx.lineCap = ui.StrokeCap.round,
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
              ctx.strokeStyle = const ChartGradient.linear(
                ui.Offset.zero,
                ui.Offset(500, 0),
                [_blue, _soft],
              );
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
      final pieces = UiPathPieces(1, 2)..moveTo(0, 0);
      for (var i = 1; i <= 1000; i++) {
        pieces.lineTo(i * .01, 0);
      }
      pieces.finish();
      expect(
        pieces.pieces.length,
        greaterThanOrEqualTo(1000 ~/ maxPieceCommands),
      );
      final wide = UiPathPieces(1, 2)..moveTo(0, 0);
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

  group('short strokes on a desktop system (Chart.js ADR 0113)', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.macOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    for (final commands in [2, 3, 10, 40, 100]) {
      for (final curved in [false, true]) {
        for (final closed in [false, true]) {
          test('$commands commands, curved $curved, closed $closed', () async {
            void shape(CanvasPath p) =>
                _shortLine(p, commands, curved: curved, closed: closed);
            final path = Path2D();
            shape(path);
            expect(path.version, commands);
            // From 10 commands, the cut gives several pieces: most vertices
            // are joins at a cut. A move and a close give no piece, and the
            // stroke keeps one draw.
            final cut = uiPathPiecesOf(path, 1, 2)?.pieces.length ?? 0;
            if (commands >= 10) expect(cut, greaterThan(1));
            if (commands == 2 && closed) expect(cut, 0);
            for (final setup in [_none, _shifted]) {
              for (final color in [_blue, _half]) {
                for (final width in [1.0, 2.0, 6.0, 12.0]) {
                  for (final join in ui.StrokeJoin.values) {
                    final (a, b, draws) = await _strokes(
                      shape,
                      setup: setup,
                      color: color,
                      width: width,
                      join: join,
                      height: 400,
                    );
                    final why = '$cut pieces, $color, $width, $join';
                    // A translucent line of one pixel keeps one draw.
                    expect(
                      draws,
                      cut == 0 || (color == _half && width <= 1) ? 0 : 1,
                      reason: why,
                    );
                    _sameLook(a, b, why);
                    if (color == _half) {
                      // 0x80: the alpha of the translucent line.
                      expect(_alphaJumps(a, b, 0x80), 0, reason: why);
                    }
                  }
                }
              }
            }
          });
        }
      }
    }
  });

  group('a filled line on a desktop system (Chart.js ADR 0113)', () {
    test('a line of 100 points strokes in pieces and fills in one draw', () {
      return _on(TargetPlatform.macOS, () async {
        Future<Render> one({required bool pieces}) => renderContext(
          (ctx) {
            UiCanvasContext.debugDrawLongPathsInPieces = pieces;
            if (pieces) expect(ctx.deferredFillMinPoints, minPieceCommands);
            ctx
              ..fillStyle = _soft
              ..beginPath();
            // Also a deferred path of fewer commands fills in one draw.
            if (pieces) ctx.deferCurrentPath();
            _shape(ctx, 100);
            ctx.fill();
            if (pieces) expect(ctx.debugPieceDraws, 0);
            ctx
              ..strokeStyle = _blue
              ..lineWidth = 2;
            final path = Path2D();
            _top(path, 100);
            ctx.stroke(path);
            if (pieces) expect(ctx.debugPieceDraws, 1);
          },
          width: 500,
          height: 300,
        );
        _sameLook(await one(pieces: false), await one(pieces: true));
      });
    });

    testWidgets('a line chart with a fill', (tester) async {
      Chart chartOf(int count) => acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>[for (var i = 0; i < count; i++) '$i'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[
                for (var i = 0; i < count; i++) 50 + 40 * math.sin(i * .2),
              ],
              'borderColor': const ChartPaint.solid(_blue),
              'backgroundColor': const ChartPaint.solid(_soft),
              'fill': FillTarget.toOrigin,
              'pointRadius': 0.0,
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'display': false},
            'y': <String, Object?>{'display': false, 'min': 0.0},
          },
          'plugins': <String, Object?>{'legend': false, 'title': false},
        },
      });
      int pieceDraws(Chart chart) =>
          (chart.ctx! as UiCanvasContext).debugPieceDraws;

      try {
        for (final (platform, count, draws) in <(TargetPlatform, int, int)>[
          // The stroke in pieces, the fill in one draw.
          (TargetPlatform.macOS, 100, 1),
          // Both in one draw.
          (TargetPlatform.android, 100, 0),
          (TargetPlatform.iOS, 100, 0),
          // From 128 points the fill takes pieces too.
          (TargetPlatform.macOS, 200, 2),
          (TargetPlatform.android, 200, 2),
        ]) {
          debugDefaultTargetPlatformOverride = platform;
          UiCanvasContext.debugDrawLongPathsInPieces = false;
          final wholeChart = chartOf(count);
          // A native app keeps one draw on each system.
          expect(pieceDraws(wholeChart), 0, reason: '$platform $count');
          final whole = await _chartRender(tester, wholeChart);
          UiCanvasContext.debugDrawLongPathsInPieces = true;
          final chart = chartOf(count);
          expect(pieceDraws(chart), draws, reason: '$platform $count');
          final render = await _chartRender(tester, chart);
          if (draws == 0) {
            // No piece: the bytes of one draw.
            expect(
              comparePixels(whole, render).differing,
              0,
              reason: '$platform $count',
            );
          } else {
            _sameLook(whole, render);
          }
        }
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('a straight line with a fill ends inside a pixel column or on '
        'the base', (tester) async {
      // Tick labels on the x axis, a legend at the right and a gap put the
      // end of a line between two whole pixels. Then the last pixel column of
      // the fast path has several points, and the top edge ends at their
      // average x, before the x of the base. A line whose last [zeros] points
      // lie on the base has its last segment as the side, also when the chart
      // area ends on a whole pixel.
      const count = 2000;
      Chart chartOf({
        Object fill = FillTarget.toOrigin,
        bool ticks = true,
        bool legend = false,
        bool gap = false,
        int datasets = 1,
        int zeros = 0,
      }) => acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'datasets': <Object?>[
            for (var d = 0; d < datasets; d++)
              <String, Object?>{
                'label': 'Series $d',
                'data': <Object?>[
                  for (var i = 0; i < count; i++)
                    <String, Object?>{
                      'x': i * 100 / (count - 1),
                      'y': gap && i == count ~/ 2
                          ? null
                          : i >= count - zeros
                          ? 0.0
                          : 50 + 38 * math.sin(i * .02 + d),
                    },
                ],
                'borderColor': const ChartPaint.solid(_blue),
                'backgroundColor': const ChartPaint.solid(_soft),
                'fill': fill,
                'pointRadius': 0.0,
              },
          ],
        },
        'options': <String, Object?>{
          'parsing': false,
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'type': 'linear',
              'min': 0.0,
              'max': 100.0,
              'display': ticks,
              'grid': <String, Object?>{'display': false},
              'ticks': <String, Object?>{'maxRotation': 0.0},
            },
            'y': <String, Object?>{
              'type': 'linear',
              'min': 0.0,
              'max': 100.0,
              'display': false,
            },
          },
          'plugins': <String, Object?>{
            'legend': legend
                ? <String, Object?>{'position': ChartPosition.right}
                : false,
            'title': false,
          },
        },
      });
      int pieceDraws(Chart chart) =>
          (chart.ctx! as UiCanvasContext).debugPieceDraws;

      for (final (name, make, draws, inside)
          in <(String, Chart Function(), int, bool)>[
            // The stroke and the fill.
            ('origin', chartOf, 2, true),
            ('start', () => chartOf(fill: FillTarget.toStart), 2, true),
            ('end', () => chartOf(fill: FillTarget.toEnd), 2, true),
            ('legend', () => chartOf(ticks: false, legend: true), 2, true),
            // The stroke and the fill of each of the two parts.
            ('gap', () => chartOf(gap: true), 3, true),
            ('three datasets', () => chartOf(datasets: 3), 6, true),
            // The last points of the line lie on the base.
            ('zero', () => chartOf(ticks: false, zeros: 1), 2, false),
            ('zeros', () => chartOf(ticks: false, zeros: 40), 2, false),
          ]) {
        UiCanvasContext.debugDrawLongPathsInPieces = false;
        final wholeChart = make();
        expect(pieceDraws(wholeChart), 0, reason: name);
        // The end of the line is not on a whole pixel, except in the cases of
        // a line that ends on the base.
        final right = wholeChart.chartArea!.right;
        expect(right == right.roundToDouble(), !inside, reason: name);
        final whole = await _chartRender(tester, wholeChart);
        UiCanvasContext.debugDrawLongPathsInPieces = true;
        final chart = make();
        expect(pieceDraws(chart), draws, reason: name);
        _sameLook(whole, await _chartRender(tester, chart), name);
      }
    });
  });
}
