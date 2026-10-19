// Original code, not ported from Chart.js: tests of the Flutter platform.
@TestOn('vm')
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/platform/chart_host.dart';
import 'package:flutter_chartjs/src/platform/native_event.dart';
import 'package:flutter_chartjs/src/platform/platform.flutter.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import 'fake_chart.dart';

// platform.flutter.dart replaces src/platform/platform.dom.js (Chart.js ADR
// 0014). test/specs/platform.dom_test.dart waits for core.controller. These
// tests cover the platform with a FakeChart, which makes the platform calls
// of core.controller.js. chart_host_test.dart covers the input mapping.

/// A canvas whose context belongs to another canvas.
final class _ForeignCanvas implements HTMLCanvasElement {
  @override
  CanvasRenderingContext2D? getContext(String contextId) =>
      UiCanvasElement().getContext2d();

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _box(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: ConstrainedBox(
      constraints: BoxConstraints.loose(const Size(400, 300)),
      child: child,
    ),
  ),
);

void main() {
  group('EVENT_TYPES', () {
    test('maps the DOM types of platform.dom.js:21', () {
      expect(eventTypes, {
        'touchstart': 'mousedown',
        'touchmove': 'mousemove',
        'touchend': 'mouseup',
        'pointerenter': 'mouseenter',
        'pointerdown': 'mousedown',
        'pointermove': 'mousemove',
        'pointerup': 'mouseup',
        'pointerleave': 'mouseout',
        'pointerout': 'mouseout',
      });
    });
  });

  group('fromNativeEvent', () {
    testWidgets('maps the type and rounds the position', (tester) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(canvas);
      final native = NativeEvent(
        type: 'pointermove',
        offsetX: 10.5,
        offsetY: 20.4,
      );
      final event = fromNativeEvent(native, chart);
      expect(event.type, 'mousemove');
      expect(event.chart, same(chart));
      expect(event.native, same(native));
      expect((event.x, event.y), (11.0, 20.0));

      final other = fromNativeEvent(
        NativeEvent(type: 'click', offsetX: 1, offsetY: 2),
        chart,
      );
      expect(other.type, 'click');
      chart.destroy();
    });
  });

  group('initCanvas', () {
    test('takes the render width from the width style', () {
      final canvas = UiCanvasElement();
      canvas.style.setProperty('width', '620px');
      initCanvas(canvas);
      expect((canvas.width, canvas.height), (620, 310));
      expect(canvas.style.getPropertyValue('display'), 'block');
      expect(canvas.style.getPropertyValue('box-sizing'), 'border-box');
    });

    test('applies the aspect ratio with ToUint32', () {
      final canvas = UiCanvasElement();
      canvas.style.setProperty('width', '620px');
      initCanvas(canvas, 3);
      expect((canvas.width, canvas.height), (620, 206));
    });

    test('takes the render height from the height style', () {
      final canvas = UiCanvasElement();
      canvas.style
        ..setProperty('width', '345px')
        ..setProperty('height', '125.42px');
      initCanvas(canvas, 3);
      expect((canvas.width, canvas.height), (345, 125));
    });

    test('keeps the default size without styles', () {
      final canvas = UiCanvasElement();
      initCanvas(canvas);
      expect((canvas.width, canvas.height), (300, 150));
    });

    test('keeps a display style', () {
      final canvas = UiCanvasElement();
      canvas.style.setProperty('display', 'inline');
      initCanvas(canvas);
      expect(canvas.style.getPropertyValue('display'), 'inline');
    });
  });

  group('FlutterPlatform', () {
    test('acquireContext gives null for an item that is not a canvas', () {
      final platform = FlutterPlatform();
      expect(platform.acquireContext('foobar'), isNull);
      expect(platform.acquireContext(null), isNull);
      expect(platform.acquireContext(_ForeignCanvas()), isNull);
    });

    test('acquireContext initializes the canvas', () {
      final canvas = UiCanvasElement();
      canvas.style.setProperty('width', '512px');
      final context = FlutterPlatform().acquireContext(canvas, 2);
      expect(context, same(canvas.getContext2d()));
      expect((canvas.width, canvas.height), (512, 256));
    });

    test('releaseContext restores the canvas', () {
      final canvas = UiCanvasElement();
      canvas.style
        ..setProperty('width', '512px')
        ..setProperty('height', '480px');
      final platform = FlutterPlatform();
      final context = platform.acquireContext(canvas)!;
      canvas
        ..width = 950
        ..height = 900;
      canvas.style
        ..setProperty('width', '475px')
        ..setProperty('height', '450px');
      context.fillStyle = '#ff0000';

      expect(platform.releaseContext(context), isTrue);
      expect((canvas.width, canvas.height), (300, 150));
      expect(canvas.style.getPropertyValue('width'), '512px');
      expect(canvas.style.getPropertyValue('height'), '480px');
      expect(canvas.style.getPropertyValue('display'), '');
      // The context is back at its default state.
      expect(context.fillStyle, '#000000');
      expect(platform.releaseContext(context), isFalse);
    });

    testWidgets('addEventListener keeps one proxy for each type', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(canvas, events: const []);
      final platform = chart.platform;
      final received = <String>[];
      platform
        ..addEventListener(chart, 'click', (types.ChartEvent e) {
          received.add('first');
        })
        ..addEventListener(chart, 'click', (types.ChartEvent e) {
          received.add('second');
        });
      final proxy = chart.platformProxies!['click'];
      expect(proxy, isA<void Function(NativeEvent)>());

      dispatchCanvasEvent(
        canvas,
        NativeEvent(type: 'click', offsetX: 5, offsetY: 5),
      );
      await tester.pump();
      expect(received, ['second']);

      platform.removeEventListener(chart, 'click');
      expect(chart.platformProxies!.containsKey('click'), isTrue);
      expect(chart.platformProxies!['click'], isNull);
      expect(hasCanvasEventListener(canvas, 'click'), isFalse);
      // A type without a proxy does nothing.
      platform.removeEventListener(chart, 'mousemove');
      chart.destroy();
    });

    testWidgets('a chart without a host has no resize observer', (
      tester,
    ) async {
      final chart = FakeChart(UiCanvasElement(), events: const []);
      expect(chart.platform, isNot(isA<FlutterPlatform>()));
      final platform = FlutterPlatform();
      expect(createResizeObserver(chart, 'resize', () {}), isNull);
      expect(platform.isAttached(null), isFalse);
      expect(platform.isAttached(chart.canvas), isFalse);
    });

    testWidgets('isAttached follows the host', (tester) async {
      final canvas = UiCanvasElement();
      final platform = FlutterPlatform();
      expect(platform.isAttached(canvas), isFalse);
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      expect(platform.isAttached(canvas), isTrue);
      await tester.pumpWidget(_box(const SizedBox()));
      expect(platform.isAttached(canvas), isFalse);
    });

    testWidgets('getDevicePixelRatio reads the host', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 3;
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final platform = FlutterPlatform()..acquireContext(canvas);
      expect(platform.getDevicePixelRatio(), 3);
      expect(FlutterPlatform().getDevicePixelRatio(), 3);
    });

    group('getMaximumSize', () {
      final platform = FlutterPlatform();
      final canvas = UiCanvasElement();

      test('passes bounded sizes through', () {
        expect(
          platform.getMaximumSize(canvas, 400, 300),
          (width: 400.0, height: 300.0),
        );
        expect(
          platform.getMaximumSize(canvas, 400, 300, 2),
          (width: 400.0, height: 200.0),
        );
      });

      test('gives 300 x 150 for two unbounded sides', () {
        expect(
          platform.getMaximumSize(canvas, double.infinity, double.infinity),
          (width: 300.0, height: 150.0),
        );
        expect(
          platform.getMaximumSize(canvas, double.infinity, double.infinity, 1),
          (width: 150.0, height: 150.0),
        );
      });

      test('gives the other side from a bounded side and the ratio', () {
        expect(
          platform.getMaximumSize(canvas, 400, double.infinity, 2),
          (width: 400.0, height: 200.0),
        );
        expect(
          platform.getMaximumSize(canvas, double.infinity, 100, 2),
          (width: 200.0, height: 100.0),
        );
      });

      test('gives the default side without a ratio', () {
        expect(
          platform.getMaximumSize(canvas, 400, double.infinity),
          (width: 400.0, height: 150.0),
        );
        expect(
          platform.getMaximumSize(canvas, double.infinity, 100),
          (width: 300.0, height: 100.0),
        );
      });
    });
  });
}
