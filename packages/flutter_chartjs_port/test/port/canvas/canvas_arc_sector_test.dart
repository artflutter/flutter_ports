// Original code, not ported from Chart.js: the run of adjacent arc sectors.
@TestOn('vm')
library;

// Keep canvas state transitions and their observations as separate steps.
// ignore_for_file: cascade_invocations

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

const _blue = ui.Color(0xFF3366CC);
const _red = ui.Color(0xFFDC3912);
const _white = ui.Color(0xFFFFFFFF);
const _background = ui.Color(0xFFFFFFFF);

bool _sector(
  UiCanvasContext ctx,
  double start,
  double end, {
  double inner = 0,
  double outer = 70,
  double x = 80,
  double y = 80,
  ui.Color color = _blue,
}) => ctx.tryDrawArcSector(
  x: x,
  y: y,
  outerRadius: outer,
  innerRadius: inner,
  startAngle: start,
  endAngle: end,
  backgroundColor: color,
  borderColor: _white,
);

/// The fill of one sector, with the calls of the ordinary sequence.
void _ordinarySector(
  UiCanvasContext ctx,
  double start,
  double end, {
  double inner = 0,
  double outer = 70,
  double x = 80,
  double y = 80,
  ui.Color color = _blue,
}) {
  final middle = (start + end) / 2;
  ctx
    ..save()
    ..fillStyle = color
    ..beginPath()
    ..arc(x, y, outer, start, middle)
    ..arc(x, y, outer, middle, end)
    ..lineTo(x + inner * math.cos(end), y + inner * math.sin(end));
  if (inner > 0) {
    ctx
      ..arc(x, y, inner, end, middle, true)
      ..arc(x, y, inner, middle, start, true);
  }
  ctx
    ..lineTo(x + outer * math.cos(start), y + outer * math.sin(start))
    ..closePath()
    ..fill()
    ..restore();
}

/// [count] slices of one color over a full turn, less a gap.
List<(double, double)> _slices(int count, {double total = 6}) => [
  for (var i = 0; i < count; i++)
    (i * total / count - 1.5, (i + 1) * total / count - 1.5),
];

Future<Render> _render(void Function(UiCanvasContext ctx) draw) =>
    renderContext((ctx) {
      ctx.fillStyle = _background;
      ctx.fillRect(0, 0, 160, 160);
      draw(ctx);
    });

/// The difference of the red channel of two renders. The red of the color is
/// below the red of the background, so `lighter` is how much less solid the
/// run is, and `lighterCount` the count of such pixels.
({int max, int differing, int lighter, int lighterCount}) _seams(
  Render merged,
  Render separate,
) {
  var max = 0;
  var differing = 0;
  var lighter = 0;
  var lighterCount = 0;
  for (var i = 0; i < merged.bytes.length; i += 4) {
    final m = merged.bytes[i];
    final s = separate.bytes[i];
    if (m != s) {
      differing++;
      max = math.max(max, (m - s).abs());
      // The red of the color is below the red of the background.
      if (m > s) {
        lighterCount++;
        lighter = math.max(lighter, m - s);
      }
    }
  }
  return (
    max: max,
    differing: differing,
    lighter: lighter,
    lighterCount: lighterCount,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('adjacent sectors of one color draw once', () {
    test('the run counts them until a flush', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      for (final (start, end) in _slices(8)) {
        expect(_sector(ctx, start, end), isTrue);
      }
      expect(ctx.debugPendingSectors, 8);
      expect(ctx.isEmpty, isFalse);
      expect(ctx.debugPictureCount, 1);
      final recorder = ui.PictureRecorder();
      ctx.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
      recorder.endRecording().dispose();
      expect(ctx.debugPendingSectors, 0);
    });

    for (final inner in [0.0, 30.0]) {
      final name = inner == 0 ? 'wedges' : 'ring sectors';

      test('$name of 24 slices: only the seams differ', () async {
        final merged = await _render((ctx) {
          for (final (start, end) in _slices(24)) {
            _sector(ctx, start, end, inner: inner);
          }
          expect(ctx.debugPendingSectors, 24);
        });
        final separate = await _render((ctx) {
          for (final (start, end) in _slices(24)) {
            _ordinarySector(ctx, start, end, inner: inner);
          }
        });
        final seams = _seams(merged, separate);
        // Measured on flutter_tester (Skia on the CPU), with a contrast of 204
        // in the red channel: at most 74 of 255, in 1715 to 2394 pixels. Two
        // fills that share a pixel leave some of the background in it, up to
        // a quarter for two halves, and the rasterizer adds its own noise.
        expect(seams.max, lessThanOrEqualTo(80), reason: '$seams');
        // 24 radial lines of at most 70 pixels, about two pixels wide.
        expect(seams.differing, lessThan(24 * 70 * 2), reason: '$seams');
        // A rim of many short arcs against one long arc: few pixels, either
        // way.
        expect(seams.lighter, lessThanOrEqualTo(64), reason: '$seams');
        expect(seams.lighterCount, lessThan(400), reason: '$seams');
        // The rim and the ends of the run stay.
        final one = await _render((ctx) {
          _sector(ctx, -1.5, 4.5, inner: inner);
        });
        expect(comparePixels(merged, one).maxChannel, lessThanOrEqualTo(8));
      });
    }

    test('20000 slices below a pixel: one solid sector', () async {
      final merged = await _render((ctx) {
        for (final (start, end) in _slices(20000, total: 6.2)) {
          _sector(ctx, start, end);
        }
        expect(ctx.debugPendingSectors, 20000);
      });
      final one = await _render((ctx) => _sector(ctx, -1.5, 4.7));
      expect(comparePixels(merged, one).maxChannel, lessThanOrEqualTo(8));
      final separate = await _render((ctx) {
        for (final (start, end) in _slices(20000, total: 6.2)) {
          _ordinarySector(ctx, start, end);
        }
      });
      // This is the largest difference of the run, and the whole disc has it.
      // Each separate fill covers a small part of a pixel. In 8 bits most of
      // these fills add nothing on flutter_tester (Skia on the CPU), so the
      // separate fills leave a pale disc where the run draws a solid one:
      // measured 199 of the contrast of 204, in 15450 pixels, and the separate
      // disc is never more solid by more than 17. A renderer with sample
      // coverage does not lose them; that one is not measured here.
      final seams = _seams(merged, separate);
      expect(seams.max, lessThanOrEqualTo(204), reason: '$seams');
      expect(seams.lighter, lessThanOrEqualTo(24), reason: '$seams');
    });

    test('translucent slices: seams only, by the alpha', () async {
      const color = ui.Color(0x803366CC);
      final merged = await _render((ctx) {
        for (final (start, end) in _slices(24)) {
          _sector(ctx, start, end, color: color);
        }
      });
      final separate = await _render((ctx) {
        for (final (start, end) in _slices(24)) {
          _ordinarySector(ctx, start, end, color: color);
        }
      });
      // Measured: 31 of 255, on the seams.
      final diff = comparePixels(merged, separate);
      expect(diff.maxChannel, lessThanOrEqualTo(36), reason: '$diff');
    });

    test('a run under globalAlpha joins by the result color', () async {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      ctx.globalAlpha = 0.5;
      _sector(ctx, 0, 1);
      _sector(ctx, 1, 2);
      expect(ctx.debugPendingSectors, 2);
      ctx.globalAlpha = 0.25;
      _sector(ctx, 2, 3);
      expect(ctx.debugPendingSectors, 1);
    });
  });

  group('what ends a run', () {
    void expectEnds(void Function(UiCanvasContext ctx) next) {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      _sector(ctx, 0, 1);
      _sector(ctx, 1, 2);
      expect(ctx.debugPendingSectors, 2);
      next(ctx);
      expect(ctx.debugPendingSectors, lessThan(2));
    }

    test(
      'another color',
      () => expectEnds((c) {
        _sector(c, 2, 3, color: _red);
        expect(c.debugPendingSectors, 1);
      }),
    );
    test('a gap', () => expectEnds((c) => _sector(c, 2.5, 3)));
    test('an overlap', () => expectEnds((c) => _sector(c, 1.5, 3)));
    test(
      'another outer radius',
      () => expectEnds((c) => _sector(c, 2, 3, outer: 40)),
    );
    test(
      'another inner radius',
      () => expectEnds((c) => _sector(c, 2, 3, inner: 4)),
    );
    test('another center', () => expectEnds((c) => _sector(c, 2, 3, x: 79)));
    test(
      'a rotation',
      () => expectEnds((c) {
        c.rotate(0.1);
        _sector(c, 2, 3);
      }),
    );
    test(
      'a fill of another form',
      () => expectEnds((c) => c.fillRect(0, 0, 4, 4)),
    );
    test(
      'a circle',
      () => expectEnds((c) {
        c.beginPath();
        c.arc(5, 5, 3, 0, 2 * math.pi);
        c.fill();
        expect(c.debugPendingSectors, 0);
        expect(c.debugPendingCircles, 1);
      }),
    );
    test(
      'a clip',
      () => expectEnds((c) {
        c.save();
        c.beginPath();
        c.rect(0, 0, 40, 40);
        c.clip();
      }),
    );
    test(
      'a full clear drops it',
      () => expectEnds((c) {
        c.clearRect(0, 0, 160, 160);
        expect(c.isEmpty, isTrue);
      }),
    );
    test(
      'a resize drops it',
      () => expectEnds((c) {
        c.canvas.width = 160;
        expect(c.isEmpty, isTrue);
      }),
    );

    test('a save with no clip and its restore do not', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      _sector(ctx, 0, 1);
      ctx.save();
      _sector(ctx, 1, 2);
      ctx.restore();
      _sector(ctx, 2, 3);
      expect(ctx.debugPendingSectors, 3);
    });

    test('the path of the last sector stays through the run', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      _sector(ctx, 0, 1);
      _sector(ctx, 1, 2);
      final sector = ctx.debugPath.singleSector!;
      expect(sector.start, 1);
      expect(sector.sweep, closeTo(1, 1e-12));
      expect(ctx.debugPendingSectors, 2);
    });

    test('a run stops below a full turn', () async {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      for (var i = 0; i < 8; i++) {
        _sector(ctx, i * 1.0, (i + 1) * 1.0);
      }
      // Six slices of one radian fit below a full turn; the seventh starts a
      // new run.
      expect(ctx.debugPendingSectors, 2);
    });

    test('a full ring of slices has no gap', () async {
      final merged = await _render((ctx) {
        const n = 400;
        for (var i = 0; i < n; i++) {
          _sector(
            ctx,
            i * 2 * math.pi / n,
            (i + 1) * 2 * math.pi / n,
            inner: 30,
          );
        }
      });
      // At the angle 0, the end of the turn meets the start.
      for (var r = 32; r < 68; r += 3) {
        final i = (80 * 160 + 80 + r) * 4;
        expect(
          merged.bytes[i],
          lessThanOrEqualTo(_blue.toARGB32() >> 16 & 255),
        );
      }
    });
  });

  group('the order of the draws', () {
    test('later draws cover a run, and a run covers earlier draws', () async {
      void before(UiCanvasContext ctx) {
        ctx.fillStyle = const ui.Color(0xFF00AA00);
        ctx.fillRect(40, 40, 30, 30);
      }

      void after(UiCanvasContext ctx) {
        ctx.fillStyle = const ui.Color(0xFFAA00AA);
        ctx.fillRect(60, 60, 30, 30);
      }

      final merged = await _render((ctx) {
        before(ctx);
        _sector(ctx, 0, 1.5);
        _sector(ctx, 1.5, 3);
        _sector(ctx, 3, 4.5);
        after(ctx);
      });
      final one = await _render((ctx) {
        before(ctx);
        _ordinarySector(ctx, 0, 4.5);
        after(ctx);
      });
      expect(comparePixels(merged, one).maxChannel, lessThanOrEqualTo(8));
    });

    test('a restore of a clip draws the run under the clip', () async {
      void clip(UiCanvasContext ctx) {
        ctx.save();
        ctx.beginPath();
        ctx.rect(50, 50, 40, 40);
        ctx.clip();
      }

      final merged = await _render((ctx) {
        clip(ctx);
        _sector(ctx, 0, 1.5);
        _sector(ctx, 1.5, 3);
        ctx.restore();
        ctx.fillStyle = const ui.Color(0x80000000);
        ctx.fillRect(0, 0, 20, 20);
      });
      final one = await _render((ctx) {
        clip(ctx);
        _ordinarySector(ctx, 0, 3);
        ctx.restore();
        ctx.fillStyle = const ui.Color(0x80000000);
        ctx.fillRect(0, 0, 20, 20);
      });
      expect(comparePixels(merged, one).maxChannel, lessThanOrEqualTo(8));
    });

    test('a run ended in the paint of another fill keeps that paint', () async {
      // The flush inside `_c` must not change the paint of the waiting fill.
      final merged = await _render((ctx) {
        _sector(ctx, 0, 1);
        _sector(ctx, 1, 2);
        ctx.fillStyle = const ui.Color(0xFF00AA00);
        ctx.beginPath();
        ctx.rect(10, 10, 20, 20);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(120, 40, 10, 0, 1);
        ctx.lineTo(120, 40);
        ctx.closePath();
        ctx.fill();
      });
      expect(merged.bytes[(20 * 160 + 20) * 4 + 1], 0xAA);
      expect(merged.bytes[(20 * 160 + 20) * 4], 0);
    });

    test('a snapshot and toDataURL hold the pending run', () async {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      _sector(ctx, 0, 1);
      _sector(ctx, 1, 2);
      final source = ctx.canvas.toImageSource();
      expect(ctx.debugPendingSectors, 0);
      final data = (await source.image.toByteData())!;
      final x = 80 + (40 * math.cos(1)).round();
      final y = 80 + (40 * math.sin(1)).round();
      expect(data.getUint8((y * 160 + x) * 4 + 3), 255);
      source.image.dispose();
    });

    test('runs and a long frame split their recording', () async {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      for (var i = 0; i < 600; i++) {
        _sector(ctx, i * 0.01, (i + 1) * 0.01, color: i.isEven ? _blue : _red);
      }
      expect(ctx.debugPictureCount, greaterThan(1));
    });
  });
}
