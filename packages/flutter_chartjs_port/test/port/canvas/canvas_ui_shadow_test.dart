// Original code, not ported from Chart.js: the shadows of Chart.js ADR 0106.
@TestOn('vm')
library;

import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pixel_compare.dart';

const _black = ui.Color(0xFF000000);
const _red = ui.Color(0xFFFF0000);

void _red20(
  UiCanvasContext ctx, {
  double blur = 0,
  double x = 0,
  double y = 0,
}) {
  ctx
    ..shadowColor = _red
    ..shadowBlur = blur
    ..shadowOffsetX = x
    ..shadowOffsetY = y;
}

extension on Render {
  int red(int x, int y) => bytes[(y * width + x) * 4];
}

void main() {
  group('the attributes', () {
    late UiCanvasContext ctx;
    setUp(() => ctx = UiCanvasElement(width: 10, height: 10).getContext2d());
    tearDown(() => ctx.dispose());

    test('have the DOM defaults', () {
      expect(ctx.shadowBlur, 0);
      expect(ctx.shadowColor, const ui.Color(0x00000000));
      expect(ctx.shadowOffsetX, 0);
      expect(ctx.shadowOffsetY, 0);
    });

    test('ignore values that the HTML rules ignore', () {
      ctx
        ..shadowBlur = 4
        ..shadowBlur = -1
        ..shadowBlur = double.nan
        ..shadowBlur = double.infinity
        ..shadowBlur = null;
      expect(ctx.shadowBlur, 4);
      ctx
        ..shadowOffsetX = -3
        ..shadowOffsetX = double.nan
        ..shadowOffsetY = 2
        ..shadowOffsetY = double.infinity;
      expect(ctx.shadowOffsetX, -3);
      expect(ctx.shadowOffsetY, 2);
    });

    test('an invalid color throws and keeps the color', () {
      ctx.shadowColor = _red;
      expect(() => ctx.shadowColor = 'red', throwsArgumentError);
      expect(ctx.shadowColor, _red);
    });

    test('save and restore keep them', () {
      _red20(ctx, blur: 5, x: 1, y: 2);
      ctx
        ..save()
        ..shadowBlur = 9
        ..shadowColor = _black
        ..shadowOffsetX = 3
        ..shadowOffsetY = 4
        ..restore();
      expect(ctx.shadowBlur, 5);
      expect(ctx.shadowColor, _red);
      expect(ctx.shadowOffsetX, 1);
      expect(ctx.shadowOffsetY, 2);
    });
  });

  group('a draw with no visible shadow', () {
    Future<Render> square(void Function(UiCanvasContext) setUp) =>
        renderContext((ctx) {
          setUp(ctx);
          ctx
            ..fillStyle = _black
            ..fillRect(20, 20, 40, 40);
        });

    test('a transparent color draws the same pixels', () async {
      final plain = await square((_) {});
      final other = await square((ctx) {
        ctx
          ..shadowBlur = 10
          ..shadowOffsetX = 5;
      });
      expect(other.bytes, plain.bytes);
    });

    test('no blur and no offset draw the same pixels', () async {
      final plain = await square((_) {});
      final other = await square((ctx) => ctx.shadowColor = _red);
      expect(other.bytes, plain.bytes);
    });
  });

  group('the pixels', () {
    test('a hard shadow lies at the offset', () async {
      final r = await renderContext((ctx) {
        _red20(ctx, x: 40);
        ctx
          ..fillStyle = _black
          ..fillRect(20, 20, 20, 20);
      });
      expect(r.alpha(30, 30), 255);
      expect(r.red(30, 30), 0);
      expect(r.alpha(70, 30), 255);
      expect(r.red(70, 30), 255);
      expect(r.alpha(100, 30), 0);
    });

    test('a blur spreads and fades', () async {
      final r = await renderContext((ctx) {
        _red20(ctx, blur: 20);
        ctx
          ..fillStyle = _black
          ..fillRect(60, 60, 40, 40);
      });
      expect(r.alpha(103, 80), greaterThan(0));
      expect(r.alpha(103, 80), greaterThan(r.alpha(112, 80)));
      expect(r.alpha(150, 80), 0);
    });

    test('the transform changes neither the offset nor the blur', () async {
      Future<Render> draw({required bool scaled}) => renderContext((ctx) {
        _red20(ctx, blur: 12, x: 50);
        ctx.fillStyle = _black;
        if (scaled) ctx.scale(2, 2);
        final path = Path2D();
        final k = scaled ? 1.0 : 2.0;
        path
          ..moveTo(20 * k, 20 * k)
          ..lineTo(35 * k, 20 * k)
          ..lineTo(35 * k, 35 * k)
          ..closePath();
        ctx.fill(path);
      });
      final scaled = await draw(scaled: true);
      final direct = await draw(scaled: false);
      expect(comparePixels(scaled, direct).maxChannel, lessThan(16));
    });

    test('the stroke of a Path2D casts a shadow', () async {
      final r = await renderContext((ctx) {
        _red20(ctx, y: 30);
        final path = Path2D()
          ..moveTo(20, 40)
          ..lineTo(140, 40);
        ctx
          ..strokeStyle = _black
          ..lineWidth = 6
          ..stroke(path);
      });
      expect(r.red(80, 40), 0);
      expect(r.alpha(80, 70), 255);
      expect(r.red(80, 70), 255);
    });

    test('a transparent part of a gradient casts no shadow', () async {
      final r = await renderContext((ctx) {
        _red20(ctx, y: 30);
        const gradient = ChartGradient.linear(
          ui.Offset(20, 0),
          ui.Offset(140, 0),
          [ui.Color(0x00000000), _black],
        );
        ctx
          ..strokeStyle = gradient
          ..lineWidth = 6
          ..beginPath()
          ..moveTo(20, 40)
          ..lineTo(140, 40)
          ..stroke();
      });
      expect(r.alpha(22, 70), lessThan(16));
      expect(r.alpha(136, 70), greaterThan(200));
      expect(r.red(136, 70), greaterThan(200));
    });

    test('a circle casts a shadow although it can batch', () async {
      final r = await renderContext((ctx) {
        _red20(ctx, x: 50);
        ctx
          ..fillStyle = _black
          ..beginPath()
          ..arc(30, 30, 10, 0, 6.283185307179586)
          ..fill();
      });
      expect(r.alpha(80, 30), 255);
      expect(r.red(80, 30), 255);
    });

    test('text casts a shadow', () async {
      Future<Render> draw({required bool shadow}) => renderContext((ctx) {
        if (shadow) _red20(ctx, y: 60);
        ctx
          ..font = const TextStyle(fontFamily: 'Arial', fontSize: 24)
          ..fillStyle = _black
          ..fillText('HHHH', 20, 40);
      });
      final plain = await draw(shadow: false);
      final cast = await draw(shadow: true);
      expect(cast.ink, greaterThan(plain.ink * 1.8));
    });

    test('an image casts a shadow', () async {
      final image = UiCanvasElement(width: 20, height: 20).getContext2d()
        ..fillStyle = _black
        ..fillRect(0, 0, 20, 20);
      final source = image.canvas.toImageSource();
      addTearDown(() {
        source.image.dispose();
        image.dispose();
      });
      final r = await renderContext((ctx) {
        _red20(ctx, x: 50);
        ctx.drawImage(source, 10, 10);
      });
      expect(r.red(20, 20), 0);
      expect(r.alpha(70, 20), 255);
      expect(r.red(70, 20), 255);
    });
  });

  group('the fast paths', () {
    late UiCanvasContext ctx;
    setUp(() => ctx = UiCanvasElement(width: 160, height: 160).getContext2d());
    tearDown(() {
      ctx.dispose();
      UiCanvasContext.debugLineFanWithoutImpeller = false;
    });

    bool bar() => ctx.tryDrawRectBar(
      outerX: 10,
      outerY: 10,
      outerWidth: 20,
      outerHeight: 20,
      innerX: 11,
      innerY: 11,
      innerWidth: 18,
      innerHeight: 18,
      borderColor: _black,
      backgroundColor: _red,
    );

    bool sector() => ctx.tryDrawArcSector(
      x: 50,
      y: 50,
      outerRadius: 30,
      innerRadius: 0,
      startAngle: 0,
      endAngle: 1,
      backgroundColor: _red,
      borderColor: _black,
    );

    bool circles() {
      ctx.fillStyle = _black;
      return ctx.tryStartCircleRun(4, stroke: false);
    }

    bool fan() {
      UiCanvasContext.debugLineFanWithoutImpeller = true;
      ctx.strokeStyle = _black;
      return ctx.tryStrokeLineFan(50, 50, 2, (ends) {
        ends
          ..[0] = 60
          ..[1] = 60
          ..[2] = 70
          ..[3] = 40;
      });
    }

    bool partitioned() {
      ctx.fillStyle = _black;
      return ctx.tryFillPartitionedPath((path) {
        path
          ..moveTo(1, 1)
          ..lineTo(9, 1)
          ..lineTo(9, 9)
          ..closePath();
      });
    }

    test('decline while a shadow is on', () {
      _red20(ctx, blur: 4);
      expect(bar(), isFalse);
      expect(sector(), isFalse);
      expect(circles(), isFalse);
      expect(fan(), isFalse);
      expect(partitioned(), isFalse);
    });

    test('work again when the shadow is off', () {
      _red20(ctx, blur: 4);
      ctx.shadowColor = const ui.Color(0x00000000);
      expect(bar(), isTrue);
      expect(circles(), isTrue);
    });
  });

  testWidgets('a plugin casts the shadow of a line', (tester) async {
    Future<double> ink({required bool shadow}) async {
      final chart = acquireChart(<String, Object?>{
        'type': 'line',
        'data': <String, Object?>{
          'labels': <Object?>['a', 'b', 'c'],
          'datasets': <Object?>[
            <String, Object?>{
              'data': <Object?>[1.0, 3.0, 2.0],
              'borderColor': const ChartPaint.solid(_black),
              'pointRadius': 0.0,
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'display': false},
            'y': <String, Object?>{'display': false},
          },
          'plugins': <String, Object?>{
            'legend': false,
            'title': false,
          },
        },
        'plugins': <Object?>[
          if (shadow)
            <String, Object?>{
              'id': 'lineShadow',
              'beforeDatasetDraw': (Chart c, Object? args, Object? options) {
                c.ctx!
                  ..save()
                  ..shadowColor = _red
                  ..shadowBlur = 8
                  ..shadowOffsetY = 20;
              },
              'afterDatasetDraw': (Chart c, Object? args, Object? options) {
                c.ctx!.restore();
              },
            },
        ],
      });
      final source = (chart.canvas! as UiCanvasElement).toImageSource();
      final data = await tester.runAsync(source.image.toByteData);
      source.image.dispose();
      var sum = 0;
      final bytes = data!.buffer.asUint8List();
      for (var i = 3; i < bytes.length; i += 4) {
        sum += bytes[i];
      }
      return sum / 255;
    }

    final plain = await ink(shadow: false);
    final cast = await ink(shadow: true);
    expect(plain, greaterThan(0));
    expect(cast, greaterThan(plain * 1.5));
  });
}
