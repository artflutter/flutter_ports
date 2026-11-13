// Original code, not ported from Chart.js: fills of varying radii in an atlas.
@TestOn('vm')
library;

// Keep canvas state transitions and their observations as separate steps.
// ignore_for_file: cascade_invocations

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CanvasCompositeOperation;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui_batch.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

const _white = ui.Color(0xFFFFFFFF);
const _wideRed = ui.Color.from(
  alpha: 1,
  red: 0.8,
  green: 0.2,
  blue: 0.2,
  colorSpace: ui.ColorSpace.displayP3,
);
const _wideBlue = ui.Color.from(
  alpha: 1,
  red: 0.2,
  green: 0.2,
  blue: 0.8,
  colorSpace: ui.ColorSpace.displayP3,
);

/// Circles that do not overlap, with random radii between `low` and `high` and
/// random centers.
final class _Circles(double low, double high, {int size = 700}) {
  this {
    final random = math.Random(7);
    var y = 4.0;
    while (y + 2 * high + 8 < size) {
      var x = 4.0;
      var row = 0.0;
      while (true) {
        final r = low + random.nextDouble() * (high - low);
        if (x + 2 * r + 8 > size) break;
        xs.add(x + r + random.nextDouble());
        ys.add(y + r + random.nextDouble());
        rs.add(r);
        x += 2 * r + 8;
        row = math.max(row, 2 * r + 8);
      }
      y += row;
    }
  }

  final List<double> xs = [];
  final List<double> ys = [];
  final List<double> rs = [];
}

/// The fills of [c] on a canvas context, as `drawPointLegend` makes them.
void _fills(UiCanvasContext ctx, _Circles c, {ui.Color color = _white}) {
  ctx.fillStyle = color;
  for (var i = 0; i < c.rs.length; i++) {
    ctx.beginPath();
    ctx.arc(c.xs[i], c.ys[i], c.rs[i], 0, 2 * math.pi);
    ctx.closePath();
    ctx.fill();
  }
}

Future<Render> _picture(int size, void Function(ui.Canvas canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final data = await image.toByteData();
  image.dispose();
  picture.dispose();
  return Render(data!.buffer.asUint8List(), size, size);
}

/// [c] with `drawCircle`.
Future<Render> _direct(_Circles c, int size, {ui.Color color = _white}) =>
    _picture(size, (canvas) {
      final paint = ui.Paint()..color = color;
      for (var i = 0; i < c.rs.length; i++) {
        canvas.drawCircle(ui.Offset(c.xs[i], c.ys[i]), c.rs[i], paint);
      }
    });

/// The first [n] circles of [c], each in `colors[i % colors.length]`, on a
/// canvas context.
void _fillsIn(UiCanvasContext ctx, _Circles c, int n, List<ui.Color> colors) {
  for (var i = 0; i < n; i++) {
    ctx.fillStyle = colors[i % colors.length];
    ctx.beginPath();
    ctx.arc(c.xs[i], c.ys[i], c.rs[i], 0, 2 * math.pi);
    ctx.closePath();
    ctx.fill();
  }
}

/// The first [n] circles of [c], each with `drawCircle` in
/// `colors[i % colors.length]`.
Future<Render> _directIn(_Circles c, int n, List<ui.Color> colors, int size) =>
    _picture(size, (canvas) {
      for (var i = 0; i < n; i++) {
        canvas.drawCircle(
          ui.Offset(c.xs[i], c.ys[i]),
          c.rs[i],
          ui.Paint()..color = colors[i % colors.length],
        );
      }
    });

/// [c] in the form that the batch has for a fixed radius (Chart.js ADR 0055
/// §8.5): the rasterized circle of the exact radius at the nearest quarter
/// pixel, at a whole pixel.
Future<Render> _lattice(_Circles c, int size) async {
  final sprites = <double, (ui.Image, double, double)>{};
  final fill = ui.Paint()..color = _white;
  final render = await _picture(size, (canvas) {
    final transform = Float32List(4);
    final rect = Float32List(4);
    final paint = ui.Paint()..filterQuality = ui.FilterQuality.low;
    for (var i = 0; i < c.rs.length; i++) {
      final r = c.rs[i];
      final (image, cell, center) = sprites.putIfAbsent(r, () {
        final cell = (2 * r + 4).ceilToDouble();
        final center = (cell / 2).floorToDouble();
        final recorder = ui.PictureRecorder();
        final sprite = ui.Canvas(recorder);
        for (var px = 0; px < 4; px++) {
          for (var py = 0; py < 4; py++) {
            sprite.drawCircle(
              ui.Offset(
                px * cell + center + px / 4,
                py * cell + center + py / 4,
              ),
              r,
              fill,
            );
          }
        }
        final picture = recorder.endRecording();
        final image = picture.toImageSync((4 * cell).ceil(), (4 * cell).ceil());
        picture.dispose();
        return (image, cell, center);
      });
      final qx = (c.xs[i] * 4).roundToDouble();
      final qy = (c.ys[i] * 4).roundToDouble();
      final bx = (qx / 4).floorToDouble();
      final by = (qy / 4).floorToDouble();
      final left = (qx - bx * 4) * cell;
      final top = (qy - by * 4) * cell;
      transform
        ..[0] = 1
        ..[1] = 0
        ..[2] = bx - center
        ..[3] = by - center;
      rect
        ..[0] = left
        ..[1] = top
        ..[2] = left + cell
        ..[3] = top + cell;
      canvas.drawRawAtlas(image, transform, rect, null, null, null, paint);
    }
  });
  for (final (image, _, _) in sprites.values) {
    image.dispose();
  }
  return render;
}

/// The largest difference and the 99th percentile of the differing pixels.
({int max, int p99, int differing}) _difference(Render a, Render b) {
  final counts = List<int>.filled(256, 0);
  var differing = 0;
  var max = 0;
  for (var i = 0; i < a.bytes.length; i += 4) {
    var worst = 0;
    for (var k = 0; k < 4; k++) {
      worst = math.max(worst, (a.bytes[i + k] - b.bytes[i + k]).abs());
    }
    if (worst > 0) {
      differing++;
      counts[worst]++;
      max = math.max(max, worst);
    }
  }
  var seen = 0;
  var p99 = 0;
  for (var d = 255; d > 0; d--) {
    seen += counts[d];
    if (seen > differing / 100) {
      p99 = d;
      break;
    }
  }
  return (max: max, p99: p99, differing: differing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the pixel bound against drawCircle', () {
    // The bound of the ink depends on the range: Skia on the CPU draws a
    // circle with an ink of -3 % to +4 % from its area, and it changes with
    // the radius. The figures of 12 grids are in Chart.js ADR 0097.
    for (final (low, high, size, ink) in const [
      (2.0, 2.5, 700, 0.055),
      (2.5, 4.0, 700, 0.03),
      (4.0, 8.0, 700, 0.025),
      (8.0, 16.0, 700, 0.016),
      (16.0, 48.0, 1000, 0.01),
      (2.0, 8.0, 700, 0.02),
      (4.0, 16.0, 700, 0.02),
      (16.0, 40.0, 1000, 0.02),
    ]) {
      test(
        'radii from $low to $high: no worse than the fixed-radius form',
        () async {
          final c = _Circles(low, high, size: size);
          expect(c.rs.length, greaterThanOrEqualTo(minLadderRun));
          final direct = await _direct(c, size);
          final ladder = await renderContext(
            (ctx) => _fills(ctx, c),
            width: size,
            height: size,
          );
          final lattice = await _lattice(c, size);
          final ladderDiff = _difference(ladder, direct);
          final latticeDiff = _difference(lattice, direct);
          // Skia on the CPU rasterizes a circle as a flat polygon with its own
          // error. It has no ramp to reach exactly, so the accepted form has a
          // large figure on these radii too: the 46 of 255 of Chart.js ADR 0055
          // is the radius 3 of its test. Below a radius of 4 that form has a
          // flatter error, and its largest difference is about 10 lower.
          if (low >= 4) {
            expect(
              ladderDiff.max,
              lessThanOrEqualTo(latticeDiff.max),
              reason: 'ladder $ladderDiff, lattice $latticeDiff',
            );
          }
          expect(
            ladderDiff.p99,
            lessThanOrEqualTo(latticeDiff.p99),
            reason: 'ladder $ladderDiff, lattice $latticeDiff',
          );
          expect(ladderDiff.max, lessThanOrEqualTo(120), reason: '$ladderDiff');
          expect(ladderDiff.p99, lessThanOrEqualTo(72), reason: '$ladderDiff');
          // The solid parts stay: a pixel that one render has solid and the
          // other empty would be a difference of area.
          final diff = comparePixels(ladder, direct);
          expect(diff.opaqueFlips, 0, reason: '$diff');
          expect(diff.inkRatio, lessThan(ink), reason: '$diff');
        },
      );
    }

    test('a chart color on white', () async {
      const size = 700;
      const blue = ui.Color(0xFF4F6BED);
      final c = _Circles(4, 16);
      final direct = await _picture(size, (canvas) {
        canvas.drawColor(_white, ui.BlendMode.src);
        final paint = ui.Paint()..color = blue;
        for (var i = 0; i < c.rs.length; i++) {
          canvas.drawCircle(ui.Offset(c.xs[i], c.ys[i]), c.rs[i], paint);
        }
      });
      final ladder = await renderContext(
        (ctx) {
          ctx.fillStyle = _white;
          ctx.fillRect(0, 0, 700, 700);
          _fills(ctx, c, color: blue);
        },
        width: size,
        height: size,
      );
      final diff = _difference(ladder, direct);
      expect(diff.max, lessThanOrEqualTo(80), reason: '$diff');
    });

    test('a translucent color keeps the color of a solid part', () async {
      const color = ui.Color(0x804F6BED);
      final c = _Circles(10, 16);
      final direct = await _direct(c, 700, color: color);
      final ladder = await renderContext(
        (ctx) => _fills(ctx, c, color: color),
        width: 700,
        height: 700,
      );
      for (var i = 0; i < c.rs.length; i++) {
        final x = c.xs[i].floor();
        final y = c.ys[i].floor();
        final at = (y * 700 + x) * 4;
        expect(ladder.bytes[at + 3], closeTo(direct.bytes[at + 3], 1));
        expect(ladder.bytes[at + 2], closeTo(direct.bytes[at + 2], 1));
      }
    });

    test('the order of overlapping fills stays', () async {
      // The later circle covers the earlier one, in each color.
      const colors = [ui.Color(0xFFDD1100), ui.Color(0xFF0022DD)];
      final render = await renderContext(
        (ctx) {
          for (var i = 0; i < 200; i++) {
            ctx.fillStyle = colors[i % 2];
            ctx.beginPath();
            ctx.arc(20.0 + i, 40, 12 + (i % 7) * 0.3, 0, 2 * math.pi);
            ctx.fill();
          }
          expect(ctx.debugPendingCircles, 200);
        },
        width: 240,
        height: 80,
      );
      // At y 40, the last circle that covers x wins.
      double radius(int i) => 12 + (i % 7) * 0.3;
      var checked = 0;
      for (var x = 12; x < 228; x++) {
        final center = x + 0.5;
        var last = -1;
        var edge = false;
        for (var i = 199; i >= 0 && last < 0; i--) {
          final d = (20.0 + i - center).abs();
          if (d < radius(i) + 1) edge = d > radius(i) - 1;
          if (d <= radius(i) - 1) last = i;
          if (edge) break;
        }
        if (edge || last < 0) continue;
        final at = (40 * 240 + x) * 4;
        expect(
          render.bytes[at] > render.bytes[at + 2],
          last.isEven,
          reason: 'x $x, circle $last',
        );
        checked++;
      }
      expect(checked, greaterThan(40));
    });

    test('a run longer than one atlas call', () async {
      // 512 instances fit in one call.
      final c = _Circles(2, 4);
      expect(c.rs.length, greaterThan(512));
      final direct = await _direct(c, 700);
      final ladder = await renderContext(
        (ctx) => _fills(ctx, c),
        width: 700,
        height: 700,
      );
      final diff = comparePixels(ladder, direct);
      expect(diff.opaqueFlips, 0, reason: '$diff');
      expect(diff.inkRatio, lessThan(0.03), reason: '$diff');
    });
  });

  group('a run with varying radii', () {
    UiCanvasContext context() {
      final ctx = UiCanvasElement(width: 300, height: 300).getContext2d();
      addTearDown(ctx.dispose);
      return ctx;
    }

    void fill(UiCanvasContext ctx, double radius, {double x = 20}) {
      ctx.beginPath();
      ctx.arc(x, 20, radius, 0, 2 * math.pi);
      ctx.fill();
    }

    void stroke(UiCanvasContext ctx, double radius) {
      ctx.beginPath();
      ctx.arc(20, 20, radius, 0, 2 * math.pi);
      ctx.fill();
      ctx.stroke();
    }

    test('takes each radius', () {
      final ctx = context();
      for (var i = 0; i < 100; i++) {
        fill(ctx, 2 + i * 0.1);
      }
      expect(ctx.debugPendingCircles, 100);
    });

    test(
      'below the minimum, it keeps the exact pixels of drawCircle',
      () async {
        const n = minLadderRun - 1;
        final c = _Circles(2, 8, size: 300);
        final some = _Circles(2, 8, size: 300)
          ..xs.length = n
          ..ys.length = n
          ..rs.length = n;
        expect(c.rs.length, greaterThan(n));
        final direct = await _direct(some, 300);
        final render = await renderContext(
          (ctx) => _fills(ctx, some),
          width: 300,
          height: 300,
        );
        expect(comparePixels(render, direct).differing, 0);
      },
    );

    test('a run of one radius stays one run of sprites', () {
      final ctx = context();
      for (var i = 0; i < minAtlasRun; i++) {
        fill(ctx, 3);
      }
      fill(ctx, 4);
      // The long run of radius 3 drew with its sprites.
      expect(ctx.debugPendingCircles, 1);
    });

    test('a streak of one radius ends it', () {
      final ctx = context();
      fill(ctx, 4);
      for (var i = 0; i < minAtlasRun + 4; i++) {
        fill(ctx, 3);
      }
      // One of radius 4 and `minAtlasRun` of radius 3 went; the rest wait.
      expect(ctx.debugPendingCircles, 4);
    });

    test('a stroke ends it, and a stroked bubble keeps its one radius', () {
      final ctx = context();
      fill(ctx, 3);
      fill(ctx, 4);
      expect(ctx.debugPendingCircles, 2);
      ctx.stroke();
      expect(ctx.debugPendingCircles, 1);
      stroke(ctx, 5);
      // The stroke of radius 4 with its run, then the fill and the stroke of
      // radius 5.
      expect(ctx.debugPendingCircles, 2);
    });

    test('a radius too small takes no ladder', () {
      final ctx = context();
      fill(ctx, 0.2);
      fill(ctx, 0.3);
      expect(ctx.debugPendingCircles, 1);
      fill(ctx, 3);
      expect(ctx.debugPendingCircles, 1);
      fill(ctx, 0.4);
      expect(ctx.debugPendingCircles, 1);
      fill(ctx, 1.9);
      expect(ctx.debugPendingCircles, 1);
      fill(ctx, 1.8);
      expect(ctx.debugPendingCircles, 1);
      fill(ctx, 2);
      expect(ctx.debugPendingCircles, 1);
      fill(ctx, 2.5);
      expect(ctx.debugPendingCircles, 2);
    });

    test(
      'a radius below 2 keeps the exact pixels of drawCircle: its ramp would '
      'add ink',
      () async {
        for (final (low, high) in const [(0.5, 1.0), (1.0, 2.0)]) {
          final c = _Circles(low, high);
          expect(c.rs.length, greaterThan(minLadderRun));
          final direct = await _direct(c, 700);
          final render = await renderContext(
            (ctx) => _fills(ctx, c),
            width: 700,
            height: 700,
          );
          final diff = comparePixels(render, direct);
          expect(diff.differing, 0, reason: '$low to $high: $diff');
        }
      },
    );

    test('radii on both sides of 2 keep the ink', () async {
      final c = _Circles(1, 4);
      final direct = await _direct(c, 700);
      final render = await renderContext(
        (ctx) => _fills(ctx, c),
        width: 700,
        height: 700,
      );
      final diff = comparePixels(render, direct);
      expect(diff.opaqueFlips, 0, reason: '$diff');
      expect(diff.inkRatio, lessThan(0.02), reason: '$diff');
    });

    test('below the minimum, each fill keeps its exact color, also when the '
        'color changes', () async {
      // The alpha of these colors has no 8-bit form: 0.5 is not 128 / 255.
      const hovered = ui.Color.fromRGBO(79, 107, 237, 0.5);
      const others = ui.Color.fromRGBO(220, 57, 18, 0.5);
      Future<void> check(_Circles c, int n, List<ui.Color> colors) async {
        final render = await renderContext(
          (ctx) => _fillsIn(ctx, c, n, colors),
          width: 300,
          height: 300,
        );
        final direct = await _directIn(c, n, colors, 300);
        final diff = comparePixels(render, direct);
        expect(diff.differing, 0, reason: '$n fills: $diff');
        expect(render.ink, greaterThan(0));
      }

      // A hover: three points of one color and radius, then a point with
      // another color and radius.
      final hover = _Circles(3, 3, size: 300)
        ..rs[3] = 4
        ..xs[3] += 1;
      final render = await renderContext(
        (ctx) {
          ctx.fillStyle = others;
          for (var i = 0; i < 3; i++) {
            ctx.beginPath();
            ctx.arc(hover.xs[i], hover.ys[i], 3, 0, 2 * math.pi);
            ctx.closePath();
            ctx.fill();
          }
          ctx.fillStyle = hovered;
          ctx.beginPath();
          ctx.arc(hover.xs[3], hover.ys[3], 4, 0, 2 * math.pi);
          ctx.closePath();
          ctx.fill();
          expect(ctx.debugPendingCircles, 4);
        },
        width: 300,
        height: 300,
      );
      final direct = await _picture(300, (canvas) {
        final paint = ui.Paint()..color = others;
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(ui.Offset(hover.xs[i], hover.ys[i]), 3, paint);
        }
        paint.color = hovered;
        canvas.drawCircle(ui.Offset(hover.xs[3], hover.ys[3]), 4, paint);
      });
      final diff = comparePixels(render, direct);
      expect(diff.differing, 0, reason: 'the hover: $diff');

      // Each color change in a run with varying radii, up to its last fill
      // below the minimum.
      final c = _Circles(2, 8, size: 300);
      expect(c.rs.length, greaterThanOrEqualTo(minLadderRun));
      await check(c, 2, const [hovered, others]);
      await check(c, minLadderRun - 1, const [hovered, others]);
      await check(c, minLadderRun - 1, const [hovered, others, others]);
    });

    test('from the minimum on, a solid pixel is within 1 of 255', () async {
      // The atlas has the 8-bit form of a color. Its alpha of 0.5 is 128 / 255.
      const color = ui.Color.fromRGBO(79, 107, 237, 0.5);
      final c = _Circles(10, 16);
      expect(c.rs.length, greaterThanOrEqualTo(minLadderRun));
      final direct = await _direct(c, 700, color: color);
      final ladder = await renderContext(
        (ctx) => _fills(ctx, c, color: color),
        width: 700,
        height: 700,
      );
      for (var i = 0; i < c.rs.length; i++) {
        final at = (c.ys[i].floor() * 700 + c.xs[i].floor()) * 4;
        for (var k = 0; k < 4; k++) {
          expect(ladder.bytes[at + k], closeTo(direct.bytes[at + k], 1));
        }
      }
    });

    test('a radius too large draws directly, in its place', () async {
      final render = await renderContext(
        (ctx) {
          ctx.fillStyle = const ui.Color(0xFFDD1100);
          for (var i = 0; i < 80; i++) {
            fill(ctx, 3 + i * 0.01, x: 10 + i.toDouble());
          }
          ctx.fillStyle = const ui.Color(0xFF0022DD);
          ctx.beginPath();
          ctx.arc(40, 40, 60, 0, 2 * math.pi);
          ctx.fill();
          expect(ctx.debugPendingCircles, 0);
          ctx.fillStyle = const ui.Color(0xFF00AA00);
          for (var i = 0; i < 80; i++) {
            fill(ctx, 3 + i * 0.01, x: 10 + i.toDouble());
          }
          expect(ctx.debugPendingCircles, 80);
        },
        width: 300,
        height: 300,
      );
      const at = (20 * 300 + 40) * 4;
      expect(render.bytes[at + 1], 0xAA);
    });

    test('a shader or a composite operation draws directly', () {
      final ctx = context();
      fill(ctx, 3);
      fill(ctx, 4);
      ctx.fillStyle = const ChartGradient.linear(
        Offset.zero,
        ui.Offset(10, 0),
        [ui.Color(0xFFFF0000), ui.Color(0xFF0000FF)],
      );
      fill(ctx, 5);
      expect(ctx.debugPendingCircles, 0);
      ctx.fillStyle = _white;
      fill(ctx, 3);
      fill(ctx, 4);
      ctx.globalCompositeOperation = CanvasCompositeOperation.multiply;
      fill(ctx, 5);
      expect(ctx.debugPendingCircles, 0);
    });

    test('colors go with the instances', () async {
      const colors = [ui.Color(0xFFDD1100), ui.Color(0xFF0022DD)];
      final render = await renderContext(
        (ctx) {
          for (var i = 0; i < 100; i++) {
            ctx.fillStyle = colors[i % 2];
            ctx.beginPath();
            ctx.arc(
              15.0 + (i % 10) * 30,
              15.0 + (i ~/ 10) * 30,
              8 + i * 0.05,
              0,
              2 * math.pi,
            );
            ctx.fill();
          }
          expect(ctx.debugPendingCircles, 100);
        },
        width: 300,
        height: 300,
      );
      for (var i = 0; i < 100; i++) {
        final at = (((15 + (i ~/ 10) * 30) * 300) + 15 + (i % 10) * 30) * 4;
        final isRed = render.bytes[at] > render.bytes[at + 2];
        expect(isRed, i.isEven, reason: 'circle $i');
        expect(render.bytes[at + 3], 255);
      }
    });

    test('a clip, a full clear and a resize behave as for a batch', () async {
      final ctx = context();
      fill(ctx, 3);
      fill(ctx, 4);
      ctx.save();
      ctx.beginPath();
      ctx.rect(0, 0, 10, 10);
      ctx.clip();
      expect(ctx.debugPendingCircles, 0);
      ctx.restore();
      fill(ctx, 3);
      fill(ctx, 4);
      ctx.clearRect(0, 0, 300, 300);
      expect(ctx.debugPendingCircles, 0);
      expect(ctx.isEmpty, isTrue);
    });
  });

  group('a color that the batch cannot keep in 32 bits draws directly', () {
    test('one wide-gamut color with varying radii', () async {
      final c = _Circles(2, 8);
      expect(c.rs.length, greaterThanOrEqualTo(minLadderRun));
      final direct = await _direct(c, 700, color: _wideRed);
      final render = await renderContext(
        (ctx) {
          _fills(ctx, c, color: _wideRed);
          expect(ctx.debugPendingCircles, 0);
        },
        width: 700,
        height: 700,
      );
      final diff = comparePixels(render, direct);
      expect(diff.differing, 0, reason: '$diff');
    });

    test(
      'two wide-gamut colors with varying radii, below the minimum',
      () async {
        final c = _Circles(2, 8, size: 300);
        const colors = [_wideRed, _wideBlue];
        final render = await renderContext(
          (ctx) => _fillsIn(ctx, c, 10, colors),
          width: 300,
          height: 300,
        );
        final direct = await _directIn(c, 10, colors, 300);
        final diff = comparePixels(render, direct);
        expect(diff.differing, 0, reason: '$diff');
      },
    );

    test('a wide-gamut color with one radius, also in a long run', () async {
      final c = _Circles(3, 3, size: 300);
      expect(c.rs.length, greaterThanOrEqualTo(minAtlasRun));
      const colors = [_wideRed, _wideBlue];
      for (final (n, palette) in [
        (minAtlasRun - 1, colors),
        (minAtlasRun + 4, colors),
        (minAtlasRun + 4, const [_wideRed]),
      ]) {
        final render = await renderContext(
          (ctx) {
            _fillsIn(ctx, c, n, palette);
            expect(ctx.debugPendingCircles, 0);
          },
          width: 300,
          height: 300,
        );
        final direct = await _directIn(c, n, palette, 300);
        final diff = comparePixels(render, direct);
        expect(diff.differing, 0, reason: '$n fills: $diff');
      }
    });

    test('a wide-gamut fill between fills in sRGB keeps its place', () async {
      final c = _Circles(8, 8, size: 300);
      for (var i = 0; i < 8; i++) {
        c.xs[i] = 40.0 + i * 6;
        c.ys[i] = 40;
        c.rs[i] = 8 + i * 0.5;
      }
      const colors = [
        ui.Color(0xFFDD1100),
        ui.Color(0xFFDD1100),
        ui.Color(0xFF0022DD),
        _wideRed,
        ui.Color(0xFF00AA44),
        ui.Color(0xFF00AA44),
        _wideBlue,
        ui.Color(0xFF0022DD),
      ];
      final render = await renderContext(
        (ctx) => _fillsIn(ctx, c, 8, colors),
        width: 300,
        height: 300,
      );
      final direct = await _directIn(c, 8, colors, 300);
      final diff = comparePixels(render, direct);
      expect(diff.differing, 0, reason: '$diff');
    });

    test('a channel that is not finite does not throw', () async {
      final c = _Circles(2, 8);
      const color = ui.Color.from(
        alpha: double.nan,
        red: 0.8,
        green: 0.2,
        blue: 0.2,
      );
      final direct = await _direct(c, 700, color: color);
      final render = await renderContext(
        (ctx) => _fills(ctx, c, color: color),
        width: 700,
        height: 700,
      );
      final diff = comparePixels(render, direct);
      expect(diff.differing, 0, reason: '$diff');
    });
  });

  group('direct circles count in the budget of the recording', () {
    test('stroked bubbles split the recording and keep their pixels', () async {
      final centers = [
        for (var i = 0; i < 1200; i++)
          (5.0 + (i % 40) * 7.3, 5.0 + (i ~/ 40) * 9.1, 2 + (i % 17) * 0.11),
      ];
      const fill = ui.Color(0x804F6BED);
      const stroke = ui.Color(0xFF4F6BED);
      void bubbles(UiCanvasContext ctx) {
        ctx.fillStyle = fill;
        ctx.strokeStyle = stroke;
        for (final (x, y, r) in centers) {
          ctx.beginPath();
          ctx.arc(x, y, r, 0, 2 * math.pi);
          ctx.closePath();
          ctx.fill();
          ctx.stroke();
        }
      }

      final split = UiCanvasElement(width: 300, height: 300).getContext2d();
      addTearDown(split.dispose);
      bubbles(split);
      expect(split.debugPictureCount, greaterThan(4));

      final render = await renderContext(bubbles, width: 300, height: 300);
      final direct = await _picture(300, (canvas) {
        final fillPaint = ui.Paint()..color = fill;
        final strokePaint = ui.Paint()
          ..color = stroke
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1;
        for (final (x, y, r) in centers) {
          canvas
            ..drawCircle(ui.Offset(x, y), r, fillPaint)
            ..drawCircle(ui.Offset(x, y), r, strokePaint);
        }
      });
      expect(comparePixels(render, direct).differing, 0);
    });

    test('a run that ends in a restore or a paint does not split', () {
      final ctx = UiCanvasElement(width: 100, height: 100).getContext2d();
      addTearDown(ctx.dispose);
      for (var i = 0; i < 8; i++) {
        ctx.beginPath();
        ctx.arc(10, 10, 2 + i * 0.1, 0, 2 * math.pi);
        ctx.fill();
      }
      expect(ctx.debugPictureCount, 1);
      final recorder = ui.PictureRecorder();
      ctx.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
      recorder.endRecording().dispose();
      expect(ctx.debugPictureCount, 1);
    });
  });
}
