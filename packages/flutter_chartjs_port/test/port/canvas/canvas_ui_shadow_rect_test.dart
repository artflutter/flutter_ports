// Original code, not ported from Chart.js: the shadow of a rectangle.
@TestOn('vm')
library;

// Keep canvas state transitions and their observations as separate steps.
// ignore_for_file: cascade_invocations

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' hide Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

const _paper = ui.Color(0xFFEEEEEE);
const _border = ui.Color(0xFF224466);
const _fill = ui.Color(0xFF4488CC);
const _other = ui.Color(0xB0CC8844);
const _shadow = ui.Color(0x80000000);

/// A canvas that logs the name of each native call and draws nothing.
final class _LogCanvas(final List<String> _log, ui.PictureRecorder recorder)
    implements ui.Canvas {
  this {
    ui.Canvas(recorder);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = '${invocation.memberName}';
    _log.add(name.substring(8, name.length - 2));
    return null;
  }
}

/// A recording canvas that draws the shadow of a rectangle as the shadow of
/// its path, the form before the row `adapt-rect-shadow-ops`: a rectangle
/// between the `translate` and the `restore` of a shadow becomes the path
/// that `rect()` builds, with the same paint. Each other call goes to the
/// real canvas as it is.
///
/// The context maps each point itself, so only a shadow translates the
/// recording canvas.
final class _PathShadowCanvas(ui.PictureRecorder recorder)
    implements ui.Canvas {
  this {
    _to = ui.Canvas(recorder);
  }

  late final ui.Canvas _to;
  bool _inShadow = false;

  /// The count of the rectangles that became paths.
  static int paths = 0;

  @override
  void save() => _to.save();

  @override
  void restore() {
    _to.restore();
    _inShadow = false;
  }

  @override
  void translate(double dx, double dy) {
    _to.translate(dx, dy);
    _inShadow = true;
  }

  @override
  void drawRect(ui.Rect rect, ui.Paint paint) {
    if (!_inShadow) {
      _to.drawRect(rect, paint);
      return;
    }
    paths++;
    _to.drawPath(
      ui.Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close(),
      paint,
    );
  }

  @override
  void drawPath(ui.Path path, ui.Paint paint) => _to.drawPath(path, paint);

  @override
  void drawDRRect(ui.RRect outer, ui.RRect inner, ui.Paint paint) =>
      _to.drawDRRect(outer, inner, paint);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

/// A bar that the fused draw declines: it takes the canvas sequence of
/// `element.bar.js`.
class _SequenceBar(super.cfg) extends BarElement;

Map<String, Object?> _cfg(
  double x, {
  double width = 12,
  double y = 40,
  double borderWidth = 0,
  ui.Color fill = _fill,
}) => {
  'x': x,
  'y': y,
  'base': 130.0,
  'width': width,
  'height': width,
  'horizontal': false,
  'enableBorderRadius': true,
  'inflateAmount': 0.0,
  'borderSkipped': BorderSkipped()..bottom = true,
  'options': BarOptions({
    'borderWidth': borderWidth,
    'borderRadius': 0.0,
    'borderColor': _border,
    'backgroundColor': fill,
  }),
};

/// Nine bars in steps, on fractions of a pixel, with two colors in turn.
List<BarElement> _bars({
  required bool fused,
  double borderWidth = 0,
  double width = 12,
  double step = 15.5,
  int count = 9,
}) => [
  for (var i = 0; i < count; i++)
    if (fused)
      BarElement(
        _cfg(
          14.25 + i * step,
          width: width,
          y: 30.5 + i % 23,
          borderWidth: borderWidth,
          fill: i.isEven ? _fill : _other,
        ),
      )
    else
      _SequenceBar(
        _cfg(
          14.25 + i * step,
          width: width,
          y: 30.5 + i % 23,
          borderWidth: borderWidth,
          fill: i.isEven ? _fill : _other,
        ),
      ),
];

/// The scene of a dataset with a shadow, as the plugin of `ChartView` draws
/// it: `save`, the four shadow attributes, the shapes and `restore`.
void _scene(
  UiCanvasContext ctx,
  void Function() draw, {
  required double blur,
  double dx = 3,
  double dy = 2,
}) {
  ctx.fillStyle = _paper;
  ctx.fillRect(0, 0, 160, 160);
  ctx.save();
  ctx.shadowColor = _shadow;
  ctx.shadowBlur = blur;
  ctx.shadowOffsetX = dx;
  ctx.shadowOffsetY = dy;
  draw();
  ctx.restore();
}

/// The render of [draw], with the shadow of each rectangle as the shadow of
/// its path when [asPaths] is true.
Future<Render> _render(
  void Function(UiCanvasContext ctx) draw, {
  bool asPaths = false,
}) async {
  if (asPaths) UiCanvasContext.debugRecordingCanvas = _PathShadowCanvas.new;
  try {
    return await renderContext(draw);
  } finally {
    UiCanvasContext.debugRecordingCanvas = null;
  }
}

List<String> _calls(void Function(UiCanvasContext ctx) draw) {
  final calls = <String>[];
  UiCanvasContext.debugRecordingCanvas = (recorder) =>
      _LogCanvas(calls, recorder);
  final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
  try {
    draw(ctx);
    final recorder = ui.PictureRecorder();
    ctx.paint(ui.Canvas(recorder), ui.Offset.zero, 1, 1);
    recorder.endRecording().dispose();
  } finally {
    ctx.dispose();
    UiCanvasContext.debugRecordingCanvas = null;
  }
  return calls;
}

/// The fused draw of a rectangle with no border.
bool _fused(
  UiCanvasContext ctx,
  double x,
  double y,
  double w,
  double h, {
  double border = 0,
  ui.Color fill = _fill,
}) => ctx.tryDrawRectBar(
  outerX: x - border,
  outerY: y - border,
  outerWidth: w + 2 * border,
  outerHeight: h + 2 * border,
  innerX: x,
  innerY: y,
  innerWidth: w,
  innerHeight: h,
  borderColor: _border,
  backgroundColor: fill,
);

/// The canvas sequence of a rectangle with no border.
void _sequence(
  UiCanvasContext ctx,
  double x,
  double y,
  double w,
  double h, {
  Object fill = _fill,
}) {
  ctx.save();
  ctx.beginPath();
  ctx.rect(x, y, w, h);
  ctx.fillStyle = fill;
  ctx.fill();
  ctx.restore();
}

/// The rectangle as four lines: the context has no single rectangle, so the
/// shadow is the shadow of the path.
void _lines(
  UiCanvasContext ctx,
  double x,
  double y,
  double w,
  double h, {
  ui.Color fill = _fill,
}) {
  ctx.save();
  ctx.beginPath();
  ctx.moveTo(x, y);
  ctx.lineTo(x + w, y);
  ctx.lineTo(x + w, y + h);
  ctx.lineTo(x, y + h);
  ctx.closePath();
  ctx.fillStyle = fill;
  ctx.fill();
  ctx.restore();
}

const _shadowOfRect = ['save', 'translate', 'drawRect', 'restore'];
const _shadowOfPath = ['save', 'translate', 'drawPath', 'restore'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => UiCanvasContext.debugRecordingCanvas = null);

  group('the pixels of the shadow of a rectangle', () {
    for (final blur in [0.0, 7.0]) {
      for (final borderWidth in [0.0, 1.5]) {
        test('bars: the path shadow and the sequence, blur $blur and border '
            '$borderWidth', () async {
          void draw(UiCanvasContext ctx, {required bool fused}) => _scene(
            ctx,
            () {
              for (final bar in _bars(fused: fused, borderWidth: borderWidth)) {
                bar.draw(ctx);
              }
            },
            blur: blur,
          );
          final before = _PathShadowCanvas.paths;
          final fused = await _render((ctx) => draw(ctx, fused: true));
          final sequence = await _render((ctx) => draw(ctx, fused: false));
          final paths = await _render(
            (ctx) => draw(ctx, fused: true),
            asPaths: true,
          );
          expect(fused.ink, greaterThan(0));
          expect(sequence.bytes, fused.bytes);
          expect(paths.bytes, fused.bytes);
          // Each bar cast one rectangle shadow: its fill.
          expect(_PathShadowCanvas.paths - before, 9);
        });
      }
    }

    test('bars thinner than a pixel, with no blur and with a blur', () async {
      for (final blur in [0.0, 5.0]) {
        void draw(UiCanvasContext ctx, {required bool fused}) => _scene(
          ctx,
          () {
            for (final bar in _bars(
              fused: fused,
              width: 0.31,
              step: 0.39,
              count: 300,
            )) {
              bar.draw(ctx);
            }
          },
          blur: blur,
          dx: 0,
          dy: 3,
        );
        final fused = await _render((ctx) => draw(ctx, fused: true));
        final sequence = await _render((ctx) => draw(ctx, fused: false));
        final paths = await _render(
          (ctx) => draw(ctx, fused: true),
          asPaths: true,
        );
        expect(sequence.bytes, fused.bytes, reason: 'blur $blur');
        expect(paths.bytes, fused.bytes, reason: 'blur $blur');
      }
    });

    test('under a scale, with a global alpha and a blend mode', () async {
      void draw(UiCanvasContext ctx, {required bool fused}) {
        ctx.setTransform(1.25, 0, 0, 0.75, 0.5, 1.5);
        ctx.globalAlpha = 0.6;
        _scene(ctx, () {
          for (final bar in _bars(fused: fused, count: 6)) {
            bar.draw(ctx);
          }
          ctx.globalCompositeOperation = CanvasCompositeOperation.multiply;
          ctx.globalAlpha = 0.9;
          for (final bar in _bars(fused: fused, count: 6, step: 14)) {
            bar.draw(ctx);
          }
        }, blur: 5);
      }

      final fused = await _render((ctx) => draw(ctx, fused: true));
      final sequence = await _render((ctx) => draw(ctx, fused: false));
      final paths = await _render(
        (ctx) => draw(ctx, fused: true),
        asPaths: true,
      );
      expect(sequence.bytes, fused.bytes);
      expect(paths.bytes, fused.bytes);
    });

    test('the fused draw, the sequence and the path of four lines', () async {
      for (final blur in [0.0, 6.0]) {
        Future<Render> draw(
          void Function(UiCanvasContext, double, double, double, double) rect,
        ) => _render(
          (ctx) => _scene(ctx, () {
            for (var i = 0; i < 8; i++) {
              rect(ctx, 12.25 + i * 16.5, 30.5 + i * 3, 11.75, 80.25 - i * 3);
            }
          }, blur: blur),
        );
        final fused = await draw(
          (ctx, x, y, w, h) => expect(_fused(ctx, x, y, w, h), isTrue),
        );
        final sequence = await draw(_sequence);
        final lines = await draw(_lines);
        expect(sequence.bytes, fused.bytes, reason: 'blur $blur');
        expect(lines.bytes, fused.bytes, reason: 'blur $blur');
      }
    });

    // The path of four lines takes `_castShadow`, which writes each value of
    // its shadow paint for each shape. So it shows a kept paint that did not
    // follow one of its keys.
    test('the kept paint follows the fill, the shadow color, the global '
        'alpha, the blend mode and the blur', () async {
      const translucent = ui.Color(0x804488CC);
      const warm = ui.Color(0xC0CC3311);
      for (final blur in [0.0, 5.0]) {
        Future<Render> draw(
          void Function(
            UiCanvasContext ctx,
            double x,
            double y,
            double w,
            double h,
            ui.Color fill,
          )
          rect,
        ) => _render((ctx) {
          ctx.fillStyle = _paper;
          ctx.fillRect(0, 0, 160, 160);
          ctx.save();
          ctx.shadowColor = _shadow;
          ctx.shadowBlur = blur;
          ctx.shadowOffsetX = 5;
          ctx.shadowOffsetY = 4;
          var i = 0;
          void next(ui.Color fill) {
            rect(ctx, 6.25 + i * 15.5, 24.5 + i * 2, 8.75, 90.25, fill);
            i++;
          }

          next(_fill);
          // Another fill object, with an alpha.
          next(translucent);
          next(_fill);
          // The fill object of before under another global alpha.
          ctx.globalAlpha = 0.5;
          next(_fill);
          ctx.globalAlpha = 1;
          next(_fill);
          // The fill object of before under another shadow color object.
          ctx.shadowColor = warm;
          next(_fill);
          // The fill and the shadow color of before under another blend
          // mode, and back.
          ctx.globalCompositeOperation = CanvasCompositeOperation.multiply;
          next(_fill);
          ctx.globalCompositeOperation = CanvasCompositeOperation.sourceOver;
          next(_fill);
          // Another blur.
          ctx.shadowBlur = blur + 3;
          next(_fill);
          ctx.restore();
        });

        final fused = await draw(
          (ctx, x, y, w, h, fill) =>
              expect(_fused(ctx, x, y, w, h, fill: fill), isTrue),
        );
        final sequence = await draw(
          (ctx, x, y, w, h, fill) => _sequence(ctx, x, y, w, h, fill: fill),
        );
        final lines = await draw(
          (ctx, x, y, w, h, fill) => _lines(ctx, x, y, w, h, fill: fill),
        );
        expect(lines.ink, greaterThan(0));
        expect(fused.bytes, lines.bytes, reason: 'blur $blur');
        expect(sequence.bytes, lines.bytes, reason: 'blur $blur');
      }
    });
  });

  group('the native calls', () {
    List<String> shadowed(void Function(UiCanvasContext ctx) draw) =>
        _calls((ctx) {
          ctx.save();
          ctx.shadowColor = _shadow;
          ctx.shadowBlur = 6;
          ctx.shadowOffsetX = 3;
          draw(ctx);
          ctx.restore();
        });

    test('a fused bar with no border: 5 calls and no path', () {
      final calls = shadowed((ctx) {
        for (var i = 0; i < 4; i++) {
          expect(_fused(ctx, 10.0 + i * 20, 20, 12, 90), isTrue);
        }
      });
      expect(calls, [
        for (var i = 0; i < 4; i++) ...[..._shadowOfRect, 'drawRect'],
      ]);
    });

    test('the sequence of one rectangle records the same calls', () {
      final calls = shadowed((ctx) => _sequence(ctx, 10, 20, 12, 90));
      expect(calls, [..._shadowOfRect, 'drawRect']);
    });

    test('a bar with a border declines the fused draw: the ring casts the '
        'shadow of its path', () {
      final calls = shadowed((ctx) {
        expect(_fused(ctx, 10, 20, 12, 90, border: 2), isFalse);
        // Nothing drew.
        expect(ctx.isEmpty, isTrue);
        BarElement(_cfg(40, borderWidth: 2)).draw(ctx);
      });
      expect(calls, [
        ..._shadowOfPath,
        'drawDRRect',
        ..._shadowOfRect,
        'drawRect',
      ]);
    });

    test('a gradient keeps the shadow of the path', () {
      const gradient = ChartGradient.linear(
        ui.Offset(0, 20),
        ui.Offset(0, 110),
        [_fill, _other],
      );
      final calls = shadowed(
        (ctx) => _sequence(ctx, 10, 20, 12, 90, fill: gradient),
      );
      expect(calls, [..._shadowOfPath, 'drawRect']);
    });

    test('a rotated rectangle and a path of lines keep the shadow of the '
        'path', () {
      final rotated = shadowed((ctx) {
        ctx.rotate(0.3);
        expect(_fused(ctx, 40, 20, 12, 60), isFalse);
        _sequence(ctx, 40, 20, 12, 60);
      });
      expect(rotated, [..._shadowOfPath, 'drawPath']);
      final lines = shadowed((ctx) => _lines(ctx, 10, 20, 12, 90));
      expect(lines, [..._shadowOfPath, 'drawPath']);
    });

    test('a rectangle with no area in 32-bit numbers keeps the shadow of '
        'the path', () {
      // 100 and 100 + 1e-9 are two 64-bit numbers and one 32-bit number.
      const w = 1e-9;
      expect(const ui.Rect.fromLTWH(100, 20, w, 90).isEmpty, isFalse);
      final calls = shadowed((ctx) {
        expect(_fused(ctx, 100, 20, w, 90), isFalse);
        expect(ctx.isEmpty, isTrue);
        _sequence(ctx, 100, 20, w, 90);
      });
      expect(calls, [..._shadowOfPath, 'drawRect']);
      // With no shadow the fused draw takes it, as before.
      final plain = _calls(
        (ctx) => expect(_fused(ctx, 100, 20, w, 90), isTrue),
      );
      expect(plain, ['drawRect']);
    });

    test('a fill that paints nothing casts no shadow', () {
      final calls = shadowed((ctx) {
        ctx.globalAlpha = 0;
        expect(_fused(ctx, 10, 20, 12, 90), isTrue);
        _sequence(ctx, 40, 20, 12, 90);
      });
      expect(calls, isEmpty);
    });

    test('no shadow: the fused bar and the sequence are one rectangle', () {
      final calls = _calls((ctx) {
        expect(_fused(ctx, 10, 20, 12, 90), isTrue);
        _sequence(ctx, 40, 20, 12, 90);
      });
      expect(calls, ['drawRect', 'drawRect']);
    });
  });

  group('the kept objects', () {
    test('one mask filter for equal blur values in a row', () {
      final kit = UiShadowKit();
      final four = kit.filter(4);
      expect(identical(kit.filter(4), four), isTrue);
      final five = kit.filter(5);
      expect(five, const ui.MaskFilter.blur(ui.BlurStyle.normal, 5));
      expect(identical(kit.filter(5), five), isTrue);
      expect(kit.filter(4), four);
    });

    test('the context keeps the filter and the paint over the bars', () {
      final ctx = UiCanvasElement(width: 160, height: 160).getContext2d();
      addTearDown(ctx.dispose);
      final kit = ctx.debugShadows;
      _scene(ctx, () {
        for (final bar in _bars(fused: true, count: 4)) {
          bar.draw(ctx);
        }
      }, blur: 8);
      expect(kit.rectSigma, 4);
      expect(kit.rectPaint.maskFilter, kit.filter(4));
      expect(identical(kit.filter(4), kit.filter(4)), isTrue);
      expect(kit.rectShadow, same(_shadow));
      expect(kit.rectAlpha, 1);
      // A paint keeps its color in 32-bit numbers, and in 8 bits on the web.
      expect(kit.rectPaint.color.a, closeTo(_shadow.a * _other.a, 0.004));
      // A sharp shadow takes the filter away.
      _scene(ctx, () => _bars(fused: true, count: 1).single.draw(ctx), blur: 0);
      expect(kit.rectSigma, 0);
      expect(kit.rectPaint.maskFilter, isNull);
      expect(kit.rectPaint.color.a, closeTo(_shadow.a * _fill.a, 0.004));
    });

    test('a color of another class is never kept', () {
      final kit = UiShadowKit();
      kit.keepRectColor(_fill, _shadow, 0.5);
      expect(kit.rectFill, same(_fill));
      expect(kit.rectShadow, same(_shadow));
      expect(kit.rectAlpha, 0.5);
      kit.keepRectColor(const ColorSwatch<int>(0xFF4488CC, {}), _shadow, 1);
      expect(kit.rectFill, isNull);
      expect(kit.rectShadow, isNull);
      kit.keepRectColor(_fill, const ColorSwatch<int>(0x80000000, {}), 1);
      expect(kit.rectFill, isNull);
      expect(kit.rectShadow, isNull);
    });

    test('the area in 32-bit numbers', () {
      bool area(double l, double t, double r, double b) =>
          UiShadowKit.hasFloat32Area(ui.Rect.fromLTRB(l, t, r, b));
      expect(area(0, 0, 1, 1), isTrue);
      expect(area(100, 20, 100.31, 90), isTrue);
      expect(area(100, 20, 100, 90), isFalse);
      expect(area(100, 20, 100 + 1e-9, 90), isFalse);
      expect(area(10, 5000000000, 20, 5000000001), isFalse);
      expect(area(20, 0, 10, 1), isFalse);
      expect(area(0, 0, 1e-46, 1), isFalse);
      expect(area(0, 0, 1e39, 1), isFalse);
      expect(area(-1e39, 0, 1e39, 1), isFalse);
      expect(area(double.nan, 0, 1, 1), isFalse);
      expect(area(0, 0, 1, double.infinity), isFalse);
    });
  });

  group('a bar chart in a ChartView', () {
    const shadow = ChartShadow(color: _shadow, blur: 8, offset: Offset(3, 4));

    ChartConfig config({double? borderWidth}) => ChartConfig(
      labels: [for (var i = 0; i < 40; i++) '$i'],
      datasets: [
        BarDataset(
          data: [for (var i = 0; i < 40; i++) 1 + (i * 7 % 11) / 3],
          backgroundColor: const ChartValue.constant(.solid(_fill)),
          borderColor: const ChartValue.constant(.solid(_border)),
          borderWidth: borderWidth,
          shadow: shadow,
        ),
      ],
      scales: const {
        'x': CategoryAxis(display: ScaleDisplay.off),
        'y': LinearAxis(min: 0, max: 5, display: ScaleDisplay.off),
      },
      animation: ChartAnimation.none,
      legend: const ChartLegend(display: false),
    );

    Chart chartOf(WidgetTester tester) => Chart.getChart(
      tester.renderObject<RenderChartHost>(find.byType(ChartHost)).canvas,
    )!;

    Future<Render> draw(WidgetTester tester, {double? borderWidth}) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              height: 200,
              child: ChartView(config: config(borderWidth: borderWidth)),
            ),
          ),
        ),
      );
      final canvas = chartOf(tester).canvas! as UiCanvasElement;
      final w = canvas.width;
      final h = canvas.height;
      final recorder = ui.PictureRecorder();
      final c = ui.Canvas(recorder)
        ..drawRect(
          ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
          ui.Paint()..color = _paper,
        );
      canvas.getContext2d().paint(c, ui.Offset.zero, 1, 1);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(w, h);
      try {
        final data = await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawStraightRgba),
        );
        return Render(Uint8List.fromList(data!.buffer.asUint8List()), w, h);
      } finally {
        image.dispose();
        picture.dispose();
      }
    }

    for (final borderWidth in [null, 2.0]) {
      testWidgets('the fused bars and the sequence, border $borderWidth', (
        tester,
      ) async {
        final fused = await draw(tester, borderWidth: borderWidth);
        // A picture observer makes each fused draw decline: the bars take
        // the canvas sequence.
        final before = ui.Picture.onCreate;
        ui.Picture.onCreate = (_) {};
        addTearDown(() => ui.Picture.onCreate = before);
        final sequence = await draw(tester, borderWidth: borderWidth);
        ui.Picture.onCreate = before;
        expect(fused.ink, greaterThan(0));
        expect(sequence.bytes, fused.bytes);
      });
    }
  });
}
