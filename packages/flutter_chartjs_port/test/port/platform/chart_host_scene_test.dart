// Original code, not ported from Chart.js: the pictures of a host in the scene.
@TestOn('vm')
library;

// Keep canvas state transitions and their observations as separate steps.
// ignore_for_file: cascade_invocations

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CanvasCompositeOperation;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = ui.Color(0xB0DD1100);
const _blue = ui.Color(0xFF0022DD);
const _green = ui.Color(0xFF00AA44);
const double _width = 120;
const double _height = 80;

/// A canvas of the display size [_width] x [_height] at the ratio [dpr].
UiCanvasElement _canvas(double dpr) {
  final canvas = UiCanvasElement(
    width: (_width * dpr).round(),
    height: (_height * dpr).round(),
  );
  canvas.style
    ..setProperty('width', '${_width}px')
    ..setProperty('height', '${_height}px');
  return canvas;
}

/// Draws a little of each kind of draw call, in the bitmap space of [dpr].
void _chart(UiCanvasContext ctx, double dpr) {
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.fillStyle = _red;
  // Past the edges of the bitmap: the clip of the host cuts it.
  ctx.fillRect(-20.25, -10.5, 60, 40);
  ctx.fillRect(_width - 15.5, _height - 12.25, 60, 40);
  ctx.strokeStyle = _blue;
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.moveTo(3, 70);
  ctx.lineTo(110, 3);
  ctx.stroke();
  ctx.fillStyle = _green;
  for (var i = 0; i < 30; i++) {
    ctx.beginPath();
    ctx.arc(10.0 + i * 3.1, 40, 3, 0, 2 * math.pi);
    ctx.closePath();
    ctx.fill();
  }
  ctx.save();
  ctx.beginPath();
  ctx.rect(60, 10, 40, 40);
  ctx.clip();
  ctx.fillStyle = _blue;
  ctx.beginPath();
  ctx.moveTo(70, 30);
  ctx.arc(70, 30, 25, 0, 1.2);
  ctx.closePath();
  ctx.fill();
  ctx.restore();
}

/// Enough separate draws to split the recording into several pictures.
void _manyChunks(UiCanvasContext ctx) {
  ctx.fillStyle = _red;
  for (var i = 0; i < 700; i++) {
    ctx.fillRect(1 + (i % 100) * 1.13, 1 + (i % 40) * 1.77, 1.5, 2.25);
  }
}

/// The old form of the paint: `Canvas.drawPicture` on the recording canvas of
/// the boundary.
final class _CanvasPaint extends CustomPainter {
  _CanvasPaint(this.ctx, this.scale);

  final UiCanvasContext ctx;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    ctx.paint(canvas, Offset.zero, scale, scale);
  }

  @override
  bool shouldRepaint(_CanvasPaint oldDelegate) => true;
}

final GlobalKey _boundary = GlobalKey();

/// The [child] at a logical offset in a boundary of 200 x 150.
Widget _frame(Widget child, Offset offset) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: RepaintBoundary(
      key: _boundary,
      child: SizedBox(
        width: 200,
        height: 150,
        child: Padding(
          padding: EdgeInsets.only(left: offset.dx, top: offset.dy),
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  ),
);

Future<Uint8List> _bytes(WidgetTester tester, double dpr) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: dpr),
  ))!;
  final data = (await tester.runAsync(image.toByteData))!;
  image.dispose();
  return data.buffer.asUint8List();
}

int _worst(Uint8List a, Uint8List b) {
  expect(a.length, b.length);
  var worst = 0;
  for (var i = 0; i < a.length; i++) {
    worst = math.max(worst, (a[i] - b[i]).abs());
  }
  return worst;
}

void _setRatio(WidgetTester tester, double dpr) {
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.resetDevicePixelRatio);
}

Iterable<ChartPicturesLayer> _layers(WidgetTester tester) =>
    tester.layers.whereType<ChartPicturesLayer>();

void main() {
  group('the pixels of the old form', () {
    for (final dpr in const [1.0, 2.0, 2.625, 3.0]) {
      for (final offset in const [
        Offset.zero,
        Offset(10.25, 7.5),
        Offset(0.3, 0.7),
      ]) {
        for (final many in [false, true]) {
          final name = many ? 'several pictures' : 'one picture';
          testWidgets('$name at the ratio $dpr and the offset $offset', (
            tester,
          ) async {
            _setRatio(tester, dpr);

            final scene = _canvas(dpr);
            final sceneContext = scene.getContext2d();
            addTearDown(sceneContext.dispose);
            _chart(sceneContext, dpr);
            if (many) _manyChunks(sceneContext);
            await tester.pumpWidget(_frame(ChartHost(canvas: scene), offset));
            expect(_layers(tester), hasLength(1));
            if (many) expect(sceneContext.debugPictureCount, greaterThan(1));
            final a = await _bytes(tester, dpr);

            final plain = _canvas(dpr);
            final plainContext = plain.getContext2d();
            addTearDown(plainContext.dispose);
            _chart(plainContext, dpr);
            if (many) _manyChunks(plainContext);
            await tester.pumpWidget(
              _frame(
                RepaintBoundary(
                  child: CustomPaint(
                    size: const Size(_width, _height),
                    painter: _CanvasPaint(plainContext, 1 / dpr),
                  ),
                ),
                offset,
              ),
            );
            expect(_layers(tester), isEmpty);
            final b = await _bytes(tester, dpr);

            expect(_worst(a, b), 0);
          });
        }
      }
    }

    testWidgets('a stretched bitmap, each axis on its own', (tester) async {
      final scene = _canvas(1);
      scene.style.setProperty('width', '${_width * 1.5}px');
      final context = scene.getContext2d();
      addTearDown(context.dispose);
      _chart(context, 1);
      await tester.pumpWidget(_frame(ChartHost(canvas: scene), Offset.zero));
      final layer = _layers(tester).single;
      expect(layer.scaleX, 1.5);
      expect(layer.scaleY, 1);
      final a = await _bytes(tester, 1);
      final plain = _canvas(1);
      final plainContext = plain.getContext2d();
      addTearDown(plainContext.dispose);
      _chart(plainContext, 1);
      await tester.pumpWidget(
        _frame(
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(_width * 1.5, _height),
              painter: _StretchPaint(plainContext),
            ),
          ),
          Offset.zero,
        ),
      );
      expect(_worst(a, await _bytes(tester, 1)), 0);
    });
  });

  group('under a shader mask at a fractional offset', () {
    Widget mask(Widget child) => ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
      ).createShader(bounds),
      child: child,
    );

    // A rectangle on whole pixels of the display at this offset. The two forms
    // differ in this case (Chart.js ADR 0097 §1).
    void content(UiCanvasContext ctx) {
      ctx.fillStyle = const Color(0xB0DD1100);
      ctx.fillRect(10.5, 10.5, 100, 60);
    }

    testWidgets('the pixels stay within 1 of 255', (tester) async {
      const offset = Offset(0, 7.5);

      final scene = _canvas(1);
      final sceneContext = scene.getContext2d();
      addTearDown(sceneContext.dispose);
      content(sceneContext);
      await tester.pumpWidget(_frame(mask(ChartHost(canvas: scene)), offset));
      expect(_layers(tester), hasLength(1));
      final a = await _bytes(tester, 1);

      final plain = _canvas(1);
      final plainContext = plain.getContext2d();
      addTearDown(plainContext.dispose);
      content(plainContext);
      await tester.pumpWidget(
        _frame(
          mask(
            RepaintBoundary(
              child: CustomPaint(
                size: const Size(_width, _height),
                painter: _CanvasPaint(plainContext, 1),
              ),
            ),
          ),
          offset,
        ),
      );
      expect(_layers(tester), isEmpty);
      expect(_worst(a, await _bytes(tester, 1)), lessThanOrEqualTo(1));
    });
  });

  group('the choice of the form', () {
    testWidgets('an empty canvas adds no layer', (tester) async {
      final canvas = _canvas(1);
      addTearDown(canvas.getContext2d().dispose);
      await tester.pumpWidget(_frame(ChartHost(canvas: canvas), Offset.zero));
      expect(_layers(tester), isEmpty);
      expect(tester.layers.whereType<PictureLayer>(), isEmpty);
    });

    testWidgets('the boundary of the host has no picture of its own', (
      tester,
    ) async {
      final canvas = _canvas(1);
      final context = canvas.getContext2d();
      addTearDown(context.dispose);
      _chart(context, 1);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: ChartHost(canvas: canvas),
          ),
        ),
      );
      expect(_layers(tester), hasLength(1));
      expect(tester.layers.whereType<PictureLayer>(), isEmpty);
    });

    for (final (name, change) in <(String, void Function(UiCanvasContext))>[
      ('a partial clear', (c) => c.clearRect(10, 10, 30, 30)),
      (
        'a composite operation',
        (c) {
          c.globalCompositeOperation = CanvasCompositeOperation.xor;
          c.fillStyle = _blue;
          c.fillRect(5, 5, 50, 50);
        },
      ),
    ]) {
      testWidgets('$name keeps the isolating layer', (tester) async {
        final canvas = _canvas(1);
        final context = canvas.getContext2d();
        addTearDown(context.dispose);
        _chart(context, 1);
        await tester.pumpWidget(_frame(ChartHost(canvas: canvas), Offset.zero));
        expect(_layers(tester), hasLength(1));

        change(context);
        await tester.pump();
        expect(_layers(tester), isEmpty);
        final a = await _bytes(tester, 1);

        final plain = _canvas(1);
        final plainContext = plain.getContext2d();
        addTearDown(plainContext.dispose);
        _chart(plainContext, 1);
        change(plainContext);
        await tester.pumpWidget(
          _frame(
            RepaintBoundary(
              child: CustomPaint(
                size: const Size(_width, _height),
                painter: _CanvasPaint(plainContext, 1),
              ),
            ),
            Offset.zero,
          ),
        );
        expect(_worst(a, await _bytes(tester, 1)), 0);

        // A full clear ends the need for the layer.
        await tester.pumpWidget(_frame(ChartHost(canvas: canvas), Offset.zero));
        context.setTransform(1, 0, 0, 1, 0, 0);
        context.globalCompositeOperation = CanvasCompositeOperation.sourceOver;
        context.clearRect(0, 0, _width, _height);
        _chart(context, 1);
        await tester.pump();
        expect(_layers(tester), hasLength(1));
      });
    }

    testWidgets('a chart larger than the box stays under its clip', (
      tester,
    ) async {
      final canvas = UiCanvasElement(width: 300, height: 300);
      final context = canvas.getContext2d();
      addTearDown(context.dispose);
      context.fillStyle = _green;
      context.fillRect(0, 0, 300, 300);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: _boundary,
              child: SizedBox(
                width: 200,
                height: 150,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: ChartHost(canvas: canvas),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final layer = _layers(tester).single;
      expect(layer.parent, isA<ClipRectLayer>());
      final bytes = await _bytes(tester, 1);
      int alpha(int x, int y) => bytes[(y * 200 + x) * 4 + 3];
      expect(alpha(50, 50), 255);
      expect(alpha(120, 50), 0);
      expect(alpha(50, 120), 0);
    });
  });

  group('the lifetime of the pictures', () {
    testWidgets('frames of clear and draw replace the pictures', (
      tester,
    ) async {
      final canvas = _canvas(1);
      final context = canvas.getContext2d();
      addTearDown(context.dispose);
      await tester.pumpWidget(_frame(ChartHost(canvas: canvas), Offset.zero));
      for (var frame = 0; frame < 12; frame++) {
        context.clearRect(0, 0, _width, _height);
        context.fillStyle = frame.isEven ? _blue : _green;
        _manyChunks(context);
        context.fillStyle = frame.isEven ? _blue : _green;
        context.fillRect(0, 0, 10, 10);
        await tester.pump();
        final layer = _layers(tester).single;
        expect(layer.attached, isTrue);
        final bytes = await _bytes(tester, 1);
        expect(bytes[(5 * 200 + 5) * 4 + 1], frame.isEven ? 0x22 : 0xAA);
      }
    });

    testWidgets('a moved host keeps its pixels, with no paint of the host', (
      tester,
    ) async {
      final canvas = _canvas(1);
      final context = canvas.getContext2d();
      addTearDown(context.dispose);
      _chart(context, 1);
      await tester.pumpWidget(
        _frame(ChartHost(canvas: canvas), Offset.zero),
      );
      final layer = _layers(tester).single;
      await tester.pumpWidget(
        _frame(ChartHost(canvas: canvas), const Offset(20, 10)),
      );
      expect(_layers(tester).single, same(layer));
      final bytes = await _bytes(tester, 1);
      // A corner of the first rect, now at (20, 10).
      expect(bytes[(12 * 200 + 22) * 4 + 3], greaterThan(100));
      expect(bytes[(5 * 200 + 5) * 4 + 3], 0);
    });

    testWidgets('a clear with no paint: the scene never reads a disposed '
        'picture', (tester) async {
      final canvas = _canvas(1);
      final context = canvas.getContext2d();
      addTearDown(context.dispose);
      _chart(context, 1);
      _manyChunks(context);
      await tester.pumpWidget(
        _frame(RepaintBoundary(child: ChartHost(canvas: canvas)), Offset.zero),
      );
      final before = await _bytes(tester, 1);
      final layer = _layers(tester).single;

      // The host gets no notification, so it does not repaint. The clear
      // disposes each picture of the last paint.
      context.onChanged = null;
      context.clearRect(0, 0, _width, _height);
      expect(context.isEmpty, isTrue);

      // A clean layer is retained: the scene keeps what the paint added.
      final retained = await _bytes(tester, 1);
      expect(_worst(before, retained), 0);

      // A layer that must add itself again reads the pictures of the context:
      // none. flutter_test runs with asserts: `addPicture` asserts on a
      // disposed picture.
      layer.markNeedsAddToScene();
      final added = await _bytes(tester, 1);
      expect(added.every((b) => b == 0), isTrue);
    });

    testWidgets('a disposed context draws nothing at the next paint', (
      tester,
    ) async {
      final canvas = _canvas(1);
      final context = canvas.getContext2d();
      _chart(context, 1);
      await tester.pumpWidget(_frame(ChartHost(canvas: canvas), Offset.zero));
      context.dispose();
      tester
          .renderObject<RenderChartHost>(find.byType(ChartHost))
          .markNeedsPaint();
      await tester.pump();
      expect(_layers(tester), isEmpty);
      final bytes = await _bytes(tester, 1);
      expect(bytes.every((b) => b == 0), isTrue);
    });

    testWidgets('another canvas on the host', (tester) async {
      final first = _canvas(1);
      final second = _canvas(1);
      final firstContext = first.getContext2d();
      final secondContext = second.getContext2d();
      addTearDown(firstContext.dispose);
      addTearDown(secondContext.dispose);
      firstContext.fillStyle = _green;
      firstContext.fillRect(0, 0, 10, 10);
      secondContext.fillStyle = _blue;
      secondContext.fillRect(0, 0, 10, 10);
      await tester.pumpWidget(_frame(ChartHost(canvas: first), Offset.zero));
      expect((await _bytes(tester, 1))[(5 * 200 + 5) * 4 + 1], 0xAA);
      await tester.pumpWidget(_frame(ChartHost(canvas: second), Offset.zero));
      expect(_layers(tester), hasLength(1));
      expect((await _bytes(tester, 1))[(5 * 200 + 5) * 4 + 2], 0xDD);
    });

    testWidgets('the removal of the host disposes the layer', (tester) async {
      final canvas = _canvas(1);
      final context = canvas.getContext2d();
      addTearDown(context.dispose);
      _chart(context, 1);
      await tester.pumpWidget(_frame(ChartHost(canvas: canvas), Offset.zero));
      final layer = _layers(tester).single;
      await tester.pumpWidget(_frame(const SizedBox(), Offset.zero));
      expect(layer.debugDisposed, isTrue);
    });
  });

  group('the context', () {
    test('beginScenePaint ends the recording as paint does', () {
      final canvas = _canvas(1);
      final context = canvas.getContext2d();
      addTearDown(context.dispose);
      expect(context.beginScenePaint(), isTrue);
      expect(context.hasScenePictures, isFalse);
      context.fillStyle = _green;
      context.fillRect(0, 0, 10, 10);
      expect(context.hasScenePictures, isFalse);
      expect(context.beginScenePaint(), isTrue);
      expect(context.hasScenePictures, isTrue);
    });

    test('beginScenePaint re-arms the notification', () {
      final canvas = _canvas(1);
      final context = canvas.getContext2d();
      addTearDown(context.dispose);
      var count = 0;
      context.onChanged = () => count++;
      context.fillStyle = _green;
      context.fillRect(0, 0, 10, 10);
      context.fillRect(0, 0, 10, 10);
      expect(count, 1);
      context.beginScenePaint();
      context.fillRect(0, 0, 10, 10);
      expect(count, 2);
    });

    test('generations flatten at beginScenePaint as at paint', () {
      final canvas = _canvas(1);
      final context = canvas.getContext2d();
      addTearDown(context.dispose);
      TestWidgetsFlutterBinding.ensureInitialized();
      context.fillStyle = _green;
      for (var i = 0; i < 12; i++) {
        context.fillRect(i.toDouble(), 0, 1, 1);
        expect(context.beginScenePaint(), isTrue);
      }
      expect(context.debugPictureCount, lessThanOrEqualTo(9));
    });

    test('a disposed context gives no pictures', () {
      final canvas = _canvas(1);
      final context = canvas.getContext2d();
      context.fillStyle = _green;
      context.fillRect(0, 0, 10, 10);
      context.dispose();
      expect(context.beginScenePaint(), isTrue);
      expect(context.hasScenePictures, isFalse);
    });
  });
}

final class _StretchPaint extends CustomPainter {
  _StretchPaint(this.ctx);

  final UiCanvasContext ctx;

  @override
  void paint(Canvas canvas, Size size) {
    ctx.paint(canvas, Offset.zero, 1.5, 1);
  }

  @override
  bool shouldRepaint(_StretchPaint oldDelegate) => true;
}
