// Original code, not ported from Chart.js: tests of the internal chart host.
@TestOn('vm')
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart'
    show ClipRectLayer, RenderRepaintBoundary;
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/platform/index.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_chart.dart';

// Chart.js ADR 0037: the chart host sizes the chart at its first layout,
// throttles later size and device pixel ratio changes, maps Flutter pointer
// events to the DOM events of Chrome and claims nothing in the gesture
// arena. A touch tap gives the compatibility mouse events, and a tap outside
// gives mouseout to the host of the last tap. The FakeChart makes the
// platform calls of core.controller.js.

Widget _box(Widget child, {double width = 400, double height = 300}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(Size(width, height)),
          child: child,
        ),
      ),
    );

RenderChartHost _host(WidgetTester tester) =>
    tester.renderObject<RenderChartHost>(find.byType(ChartHost));

/// The DOM event types of the chart events of [chart].
List<String> _nativeTypes(FakeChart chart) => [
  for (final event in chart.events) event.native!.type,
];

/// Each DOM event type that the host sends.
const List<String> _allTypes = [
  'pointerover',
  'pointerenter',
  'pointerdown',
  'pointermove',
  'pointerup',
  'pointercancel',
  'pointerout',
  'pointerleave',
  'touchstart',
  'touchmove',
  'touchend',
  'touchcancel',
  'mouseover',
  'mouseenter',
  'mousemove',
  'mousedown',
  'mouseup',
  'click',
  'mouseout',
  'mouseleave',
];

/// Adds a listener for each type of [_allTypes] to [canvas]. The listeners
/// add the native events to [log] at once, with no throttle.
void _record(UiCanvasElement canvas, List<NativeEvent> log) {
  for (final type in _allTypes) {
    addCanvasEventListener(canvas, type, log.add);
  }
}

/// The types of [log].
List<String> _types(List<NativeEvent> log) => [
  for (final event in log) event.type,
];

/// The global routes of the pointer router.
int _globalRoutes(WidgetTester tester) =>
    tester.binding.pointerRouter.debugGlobalRouteCount;

/// The owner of the compatibility mouse.
RenderChartHost? get _owner => RenderChartHost.debugCompatibilityMouseOwner;

void main() {
  group('first layout', () {
    testWidgets('sizes a chart that starts before the layout at once', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(
        _box(ChartHost(canvas: canvas)),
        phase: EnginePhase.build,
      );
      final chart = FakeChart(canvas);
      expect(chart.platform, isA<FlutterPlatform>());
      // Not laid out yet: the chart starts detached.
      expect(chart.attached, isFalse);
      expect(chart.attachCalls, ['detached']);

      // flutter_test stopped the frame after the build. Run the rest.
      tester.binding.scheduleFrame();
      await tester.pump();
      // The first layout attached and sized the chart, before the paint.
      expect(chart.attachCalls, ['detached', 'attached']);
      expect(chart.attached, isTrue);
      expect((chart.width, chart.height), (400.0, 200.0));
      expect(chart.updates, ['attach']);
      expect(_host(tester).size, const Size(400, 200));
      expect(canvas.getContext2d().isEmpty, isFalse);

      // The initial ResizeObserver notification comes at the next layout of
      // the host, and resizes to the same size in the frame after it, which
      // changes nothing.
      await tester.pump();
      await tester.pump();
      expect(chart.updates, ['attach']);
      chart.destroy();
    });

    testWidgets('sizes a chart that starts after the layout at once', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(canvas, maintainAspectRatio: false);
      expect(chart.attachCalls, ['attached']);
      expect((chart.width, chart.height), (400.0, 300.0));
      await tester.pump();
      expect(_host(tester).size, const Size(400, 300));
      chart.destroy();
    });
  });

  group('resize', () {
    testWidgets('throttles constraint changes to one resize in a frame', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(canvas, maintainAspectRatio: false);
      await tester.pump();
      final resizes = chart.resizes.length;

      await tester.pumpWidget(_box(ChartHost(canvas: canvas), width: 600));
      // The observer got the new size; the resize waits for the next frame.
      expect(chart.width, 400);
      expect(_host(tester).size, const Size(400, 300));
      expect(_host(tester).contentWidth, 600);

      await tester.pump();
      expect((chart.width, chart.height), (600.0, 300.0));
      expect(chart.resizes.length, resizes + 1);
      expect(_host(tester).size, const Size(600, 300));
      chart.destroy();
    });

    testWidgets('follows a device pixel ratio change', (tester) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 1;
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(canvas);
      await tester.pump();
      expect(chart.currentDevicePixelRatio, 1);
      expect((canvas.width, canvas.height), (400, 200));

      tester.view.devicePixelRatio = 2;
      await tester.pump();
      expect(_host(tester).devicePixelRatio, 2);
      await tester.pump();
      expect(chart.currentDevicePixelRatio, 2);
      expect((canvas.width, canvas.height), (800, 400));
      expect(_host(tester).size, const Size(400, 200));
      chart.destroy();
    });

    testWidgets('shows content drawn before the host at the display size', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      tester.view.devicePixelRatio = 2;
      // A canvas of 400 x 200 bitmap pixels, drawn at the start ratio 1 and
      // shown by a host at the ratio 2: the DOM shows the bitmap at its
      // display size, here its render size of 400 x 200.
      final canvas = UiCanvasElement(width: 400, height: 200);
      canvas.getContext2d()
        ..fillStyle = '#ff0000'
        ..fillRect(0, 0, 200, 100);
      await tester.pumpWidget(
        _box(RepaintBoundary(child: ChartHost(canvas: canvas))),
      );
      expect(_host(tester).size, const Size(400, 200));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
      final image = await tester.runAsync(boundary.toImage);
      final data = (await tester.runAsync(image!.toByteData))!;
      int alphaAt(int x, int y) => data.getUint8((y * image.width + x) * 4 + 3);
      expect(image.width, 400);
      expect(alphaAt(190, 90), 255);
      expect(alphaAt(210, 110), 0);
      image.dispose();
    });

    testWidgets('clips a chart that is larger than the box', (tester) async {
      final canvas = UiCanvasElement(width: 600, height: 300);
      await tester.pumpWidget(_box(ChartHost(canvas: canvas), height: 100));
      final chart = FakeChart(canvas, responsive: false);
      await tester.pump();
      expect((chart.width, chart.height), (600.0, 300.0));
      expect(_host(tester).displaySize, const Size(600, 300));
      expect(_host(tester).size, const Size(400, 100));
      expect(tester.layers.whereType<ClipRectLayer>(), isNotEmpty);
      chart.destroy();
    });

    testWidgets('a later resize with the container height keeps the ratio', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas), height: 100));
      // The attach resize has no maintainHeight: 400 x 200. The first
      // ResizeObserver notification passes the container size, which gives
      // 200 x 100 in the next frame, as upstream.
      final chart = FakeChart(canvas);
      expect((chart.width, chart.height), (400.0, 200.0));
      // Chart.js ADR 0022: the first notification comes at the next layout
      // of the host (frame 1), and its throttled resize in the next frame
      // (frame 2), as the DOM gives the ResizeObserver callback in frame 1
      // and the throttled call in frame 2 (platform.dom.js:197-224).
      await tester.pump();
      expect((chart.width, chart.height), (400.0, 200.0));
      await tester.pump();
      expect((chart.width, chart.height), (200.0, 100.0));
      expect(_host(tester).size, const Size(200, 100));
      chart.destroy();
    });
  });

  group('display size and bitmap stretch', () {
    // canvas-cuts-plan.md 3.5: the host shows the bitmap at the display size
    // of the canvas, as the DOM stretches a canvas bitmap to its CSS size.
    // Work package A2 pinned these rules before cut 2 changed the host.

    /// Sets the device pixel ratio of the test view and keeps its logical
    /// size of 800 x 600.
    void setRatio(WidgetTester tester, double ratio) {
      addTearDown(tester.view.reset);
      tester.view
        ..devicePixelRatio = ratio
        ..physicalSize = const Size(800, 600) * ratio;
    }

    /// Clears the bitmap of [chart] and fills the left half of the chart, in
    /// chart coordinates.
    void fillLeftHalf(FakeChart chart) {
      final canvas = chart.canvas!;
      chart.ctx!
        ..save()
        ..resetTransform()
        ..clearRect(0, 0, canvas.width.toDouble(), canvas.height.toDouble())
        ..restore()
        ..fillStyle = '#0000ff'
        ..fillRect(0, 0, chart.width / 2, chart.height);
    }

    /// The size and the alpha channel of the image of the first
    /// [RepaintBoundary], in logical pixels.
    Future<({int width, int height, int Function(int x, int y) alphaAt})>
    boundaryImage(WidgetTester tester) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first,
      );
      final image = (await tester.runAsync(boundary.toImage))!;
      final data = (await tester.runAsync(image.toByteData))!;
      final (width, height) = (image.width, image.height);
      image.dispose();
      return (
        width: width,
        height: height,
        alphaAt: (int x, int y) => data.getUint8((y * width + x) * 4 + 3),
      );
    }

    /// The `Canvas.scale` calls of the paint of [host], as (x, y). The host
    /// and the context scale the canvas itself and push no transform layer,
    /// so a [TestRecordingCanvas] records the calls.
    List<(double, double)> paintScales(RenderChartHost host) {
      final canvas = TestRecordingCanvas();
      host.paint(TestRecordingPaintingContext(canvas), Offset.zero);
      return [
        for (final call in canvas.invocations)
          if (call.invocation.memberName == #scale)
            switch (call.invocation.positionalArguments) {
              [final double x] || [final double x, null] => (x, x),
              [final double x, final double y] => (x, y),
              final arguments => throw StateError('scale$arguments'),
            },
      ];
    }

    testWidgets('a chart at devicePixelRatio 1 on a view at 2 fills its '
        'display size', (tester) async {
      setRatio(tester, 2);
      final canvas = UiCanvasElement();
      await tester.pumpWidget(
        _box(RepaintBoundary(child: ChartHost(canvas: canvas))),
      );
      final chart = FakeChart(canvas, devicePixelRatio: 1);
      fillLeftHalf(chart);
      await tester.pump();
      expect((chart.width, chart.height), (400.0, 200.0));
      expect((canvas.width, canvas.height), (400, 200));
      expect(_host(tester).size, const Size(400, 200));
      final image = await boundaryImage(tester);
      expect((image.width, image.height), (400, 200));
      // The left half of the chart covers the left half of the image.
      expect(image.alphaAt(5, 5), 255);
      expect(image.alphaAt(190, 100), 255);
      expect(image.alphaAt(210, 100), 0);
      expect(image.alphaAt(395, 195), 0);
      chart.destroy();
    });

    testWidgets('a chart at devicePixelRatio 3 on a view at 1 fills its '
        'display size', (tester) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(
        _box(RepaintBoundary(child: ChartHost(canvas: canvas))),
      );
      final chart = FakeChart(canvas, devicePixelRatio: 3);
      fillLeftHalf(chart);
      await tester.pump();
      expect((chart.width, chart.height), (400.0, 200.0));
      expect((canvas.width, canvas.height), (1200, 600));
      expect(_host(tester).size, const Size(400, 200));
      final image = await boundaryImage(tester);
      expect((image.width, image.height), (400, 200));
      expect(image.alphaAt(5, 5), 255);
      expect(image.alphaAt(190, 100), 255);
      expect(image.alphaAt(210, 100), 0);
      expect(image.alphaAt(395, 195), 0);
      chart.destroy();
    });

    testWidgets('a pointer at the center of a stretched chart gives the '
        'center of the chart', (tester) async {
      setRatio(tester, 2);
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(
        canvas,
        devicePixelRatio: 1,
        events: const ['click'],
      );
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byType(ChartHost)));
      await tester.pump();
      final event = chart.events.single;
      expect((event.x, event.y), (chart.width / 2, chart.height / 2));
      expect((event.x, event.y), (200.0, 100.0));
      chart.destroy();
    });

    testWidgets('a factor within 1e-3 paints at exactly 1 / devicePixelRatio', (
      tester,
    ) async {
      // DPR 1.5 and a width of 101: the bitmap is 151 wide. The factor
      // display / (bitmap / DPR) is 101 * 1.5 / 151 = 1.0033, so the one
      // scale of the paint is display / bitmap on each axis.
      setRatio(tester, 1.5);
      var canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas), width: 101));
      var chart = FakeChart(canvas);
      await tester.pump();
      expect((chart.width, chart.height), (101.0, 50.5));
      expect((canvas.width, canvas.height), (151, 75));
      final (scaleX, scaleY) = paintScales(_host(tester)).single;
      expect(scaleX, 101 / 151);
      expect(scaleY, 50.5 / 75);
      expect(scaleX * 1.5, closeTo(1.0033, 1e-4));
      chart.destroy();
      await tester.pumpWidget(_box(const SizedBox()));

      // DPR 2.625 and a box 387.43 wide (the Stress tab on the Pixel 8a): the
      // chart is 387.4 x 193.7 and the bitmap 1016 x 508. The factor
      // 1016.925 / 1016 is within 1e-3 of 1, so the only scale is exactly
      // 1 / 2.625 and the bitmap pixels stay on the device pixels.
      setRatio(tester, 2.625);
      canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas), width: 387.43));
      chart = FakeChart(canvas);
      await tester.pump();
      expect((chart.width, chart.height), (387.4, 193.7));
      expect((canvas.width, canvas.height), (1016, 508));
      expect(chart.width * 2.625 / canvas.width, closeTo(1, 1e-3));
      expect(paintScales(_host(tester)), [(1 / 2.625, 1 / 2.625)]);
      chart.destroy();
    });

    testWidgets('a non-responsive chart shows its bitmap at the size of its '
        'styles', (tester) async {
      // The upstream case "attributes for the render size and style for the
      // display size": attributes 165 x 85, styles 345 x 125.
      final canvas = UiCanvasElement(width: 165, height: 85);
      canvas.style
        ..setProperty('width', '345px')
        ..setProperty('height', '125px');
      await tester.pumpWidget(
        _box(RepaintBoundary(child: ChartHost(canvas: canvas))),
      );
      final chart = FakeChart(canvas, responsive: false);
      expect((chart.width, chart.height), (165.0, 85.0));
      expect((canvas.width, canvas.height), (165, 85));
      fillLeftHalf(chart);
      await tester.pump();
      expect(_host(tester).size, const Size(345, 125));
      final image = await boundaryImage(tester);
      expect((image.width, image.height), (345, 125));
      // The left 82.5 bitmap pixels show 172.5 pixels wide.
      expect(image.alphaAt(5, 120), 255);
      expect(image.alphaAt(165, 60), 255);
      expect(image.alphaAt(180, 60), 0);
      expect(image.alphaAt(340, 5), 0);
      chart.destroy();
    });

    testWidgets('one style alone shows the render size', (tester) async {
      // The CSS rule of a replaced element (one style keeps the aspect ratio
      // of the render size) is for the harness matcher toBeChartOfSize. The
      // host shows the render size.
      final canvas = UiCanvasElement(width: 200, height: 100);
      canvas.style.setProperty('width', '600px');
      canvas.getContext2d()
        ..fillStyle = '#0000ff'
        ..fillRect(0, 0, 100, 100);
      await tester.pumpWidget(
        _box(RepaintBoundary(child: ChartHost(canvas: canvas)), width: 800),
      );
      expect(_host(tester).size, const Size(200, 100));
      final image = await boundaryImage(tester);
      expect((image.width, image.height), (200, 100));
      expect(image.alphaAt(90, 50), 255);
      expect(image.alphaAt(110, 50), 0);

      final other = UiCanvasElement(width: 200, height: 100);
      other.style.setProperty('height', '50px');
      await tester.pumpWidget(
        _box(RepaintBoundary(child: ChartHost(canvas: other)), width: 800),
      );
      expect(_host(tester).size, const Size(200, 100));
    });

    testWidgets('a non-responsive chart on canvas attributes at '
        'devicePixelRatio 3 keeps its display size', (tester) async {
      // The upstream case "should scale the render size but not the
      // 'implicit' display size" (core.controller.tests.js:1397).
      setRatio(tester, 3);
      final canvas = UiCanvasElement(width: 320, height: 240);
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(canvas, responsive: false);
      await tester.pump();
      expect((chart.width, chart.height), (320.0, 240.0));
      expect((canvas.width, canvas.height), (960, 720));
      expect(canvas.style.getPropertyValue('width'), '320px');
      expect(_host(tester).size, const Size(320, 240));
      expect(paintScales(_host(tester)), [(1 / 3, 1 / 3)]);
      chart.destroy();
    });

    testWidgets('releaseContext gives the host the default 300 x 150', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(canvas);
      await tester.pump();
      expect(_host(tester).size, const Size(400, 200));
      chart.destroy();
      await tester.pump();
      expect((canvas.width, canvas.height), (300, 150));
      expect(canvas.style.getPropertyValue('width'), '');
      expect(canvas.style.getPropertyValue('height'), '');
      expect(_host(tester).size, const Size(300, 150));
    });
  });

  group('unbounded constraints', () {
    Future<FakeChart> pumpChart(
      WidgetTester tester,
      Widget Function(Widget host) wrap, {
      bool maintainAspectRatio = true,
    }) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: wrap(ChartHost(canvas: canvas)),
        ),
      );
      final chart = FakeChart(canvas, maintainAspectRatio: maintainAspectRatio);
      await tester.pump();
      await tester.pump();
      return chart;
    }

    testWidgets('both sides unbounded give the canvas default 300 x 150', (
      tester,
    ) async {
      final chart = await pumpChart(
        tester,
        (host) => UnconstrainedBox(child: host),
      );
      expect((chart.width, chart.height), (300.0, 150.0));
      expect(_host(tester).size, const Size(300, 150));
      chart.destroy();
    });

    testWidgets('a bounded width and the aspect ratio give the height', (
      tester,
    ) async {
      final chart = await pumpChart(
        tester,
        (host) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: ListView(children: [host]),
          ),
        ),
      );
      expect((chart.width, chart.height), (400.0, 200.0));
      chart.destroy();
    });

    testWidgets('an unbounded height without aspect ratio is 150', (
      tester,
    ) async {
      final chart = await pumpChart(
        tester,
        (host) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: ListView(children: [host]),
          ),
        ),
        maintainAspectRatio: false,
      );
      expect((chart.width, chart.height), (400.0, 150.0));
      chart.destroy();
    });

    testWidgets('a bounded height and the aspect ratio give the width', (
      tester,
    ) async {
      final chart = await pumpChart(
        tester,
        (host) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [host],
            ),
          ),
        ),
      );
      expect((chart.width, chart.height), (200.0, 100.0));
      expect(_host(tester).size, const Size(200, 100));
      chart.destroy();
    });
  });

  group('dry layout', () {
    testWidgets('gives the constrained display size', (tester) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(canvas);
      await tester.pump();
      final host = _host(tester);
      expect(
        host.getDryLayout(const BoxConstraints(maxWidth: 100, maxHeight: 50)),
        const Size(100, 50),
      );
      expect(host.getDryLayout(const BoxConstraints()), const Size(400, 200));
      expect(host.getMaxIntrinsicWidth(100), 400);
      expect(host.getMinIntrinsicHeight(100), 200);
      expect(host.isRepaintBoundary, isTrue);
      chart.destroy();
    });
  });

  group('TickerMode', () {
    testWidgets('reports a change of TickerMode.enabled', (tester) async {
      final canvas = UiCanvasElement();
      final changes = <bool>[];
      Widget build({required bool enabled}) => _box(
        TickerMode(
          enabled: enabled,
          child: ChartHost(canvas: canvas, onTickerModeChanged: changes.add),
        ),
      );
      await tester.pumpWidget(build(enabled: true));
      expect(_host(tester).tickerEnabled, isTrue);
      await tester.pumpWidget(build(enabled: false));
      expect(_host(tester).tickerEnabled, isFalse);
      await tester.pumpWidget(build(enabled: false));
      await tester.pumpWidget(build(enabled: true));
      expect(changes, [false, true]);
    });

    testWidgets('starts muted under TickerMode(enabled: false)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _box(
          TickerMode(
            enabled: false,
            child: ChartHost(canvas: UiCanvasElement()),
          ),
        ),
      );
      expect(_host(tester).tickerEnabled, isFalse);
    });
  });

  group('attach and detach', () {
    testWidgets('a GlobalKey move reports no change', (tester) async {
      final canvas = UiCanvasElement();
      final key = GlobalKey();
      Widget build({required bool left}) => _box(
        Row(
          children: [
            SizedBox(
              width: 200,
              child: left ? ChartHost(key: key, canvas: canvas) : null,
            ),
            SizedBox(
              width: 200,
              child: left ? null : ChartHost(key: key, canvas: canvas),
            ),
          ],
        ),
      );
      await tester.pumpWidget(build(left: true));
      final chart = FakeChart(canvas, maintainAspectRatio: false);
      expect(chart.attachCalls, ['attached']);
      await tester.pumpWidget(build(left: false));
      await tester.pump();
      expect(chart.attachCalls, ['attached']);
      expect(chart.attached, isTrue);
      chart.destroy();
    });

    testWidgets('an unmount reports a detach after the frame', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(canvas);
      expect(canvas.parentNode, isA<RenderChartHost>());
      await tester.pumpWidget(_box(const SizedBox()));
      expect(canvas.parentNode, isNull);
      expect(chart.attachCalls, ['attached', 'detached']);
      expect(chart.attached, isFalse);
      expect(FlutterPlatform().isAttached(canvas), isFalse);
      chart.destroy();
    });

    testWidgets('a new host attaches the detached chart again', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(canvas, maintainAspectRatio: false);
      await tester.pumpWidget(_box(const SizedBox()));
      await tester.pumpWidget(_box(ChartHost(canvas: canvas), width: 500));
      expect(chart.attachCalls, ['attached', 'detached', 'attached']);
      expect((chart.width, chart.height), (500.0, 300.0));
      chart.destroy();
    });

    testWidgets('a wrapper toggle keeps the chart attached', (tester) async {
      final canvas = UiCanvasElement();
      Widget build({required bool pad, double width = 400}) => _box(
        pad
            ? Padding(
                padding: EdgeInsets.zero,
                child: ChartHost(canvas: canvas),
              )
            : ChartHost(canvas: canvas),
        width: width,
      );
      await tester.pumpWidget(build(pad: false));
      final chart = FakeChart(canvas, maintainAspectRatio: false);
      await tester.pump();
      // A new host takes over the canvas in the same frame.
      await tester.pumpWidget(build(pad: true));
      await tester.pump();
      expect(chart.attachCalls, ['attached']);
      expect(chart.attached, isTrue);
      expect(canvas.parentNode, same(_host(tester)));
      expect((chart.width, chart.height), (400.0, 300.0));

      // The new host has the ResizeObserver of the chart.
      await tester.pumpWidget(build(pad: true, width: 300));
      await tester.pump();
      expect(chart.attachCalls, ['attached']);
      expect((chart.width, chart.height), (300.0, 300.0));
      expect(_host(tester).size, const Size(300, 300));
      chart.destroy();
    });

    testWidgets('a move to a sibling slot without a GlobalKey keeps the '
        'chart attached', (tester) async {
      final canvas = UiCanvasElement();
      Widget build({required bool left, double width = 300}) => _box(
        Row(
          children: [
            SizedBox(
              width: 200,
              child: left ? ChartHost(canvas: canvas) : null,
            ),
            SizedBox(
              width: width,
              child: left ? null : ChartHost(canvas: canvas),
            ),
          ],
        ),
        width: 800,
      );
      await tester.pumpWidget(build(left: true));
      final chart = FakeChart(canvas, maintainAspectRatio: false);
      expect(chart.attachCalls, ['attached']);
      expect((chart.width, chart.height), (200.0, 300.0));
      await tester.pumpWidget(build(left: false));
      await tester.pump();
      expect(chart.attachCalls, ['attached']);
      expect(chart.attached, isTrue);
      expect((chart.width, chart.height), (300.0, 300.0));

      await tester.pumpWidget(build(left: false, width: 500));
      await tester.pump();
      expect(chart.attachCalls, ['attached']);
      expect((chart.width, chart.height), (500.0, 300.0));
      expect((canvas.width, canvas.height), (500, 300));
      chart.destroy();
    });

    testWidgets('an AnimatedSwitcher cross-fade keeps the chart attached', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      Widget build(int key, {double width = 400}) => _box(
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: ChartHost(key: ValueKey(key), canvas: canvas),
        ),
        width: width,
      );
      await tester.pumpWidget(build(0));
      final chart = FakeChart(canvas, maintainAspectRatio: false);
      await tester.pump();
      await tester.pumpWidget(build(1));
      await tester.pump(const Duration(milliseconds: 50));
      // Both hosts are in the tree; the new one shows the canvas.
      expect(find.byType(ChartHost), findsNWidgets(2));
      expect(chart.attachCalls, ['attached']);
      await tester.pumpAndSettle();
      expect(find.byType(ChartHost), findsOneWidget);
      expect(chart.attachCalls, ['attached']);
      expect(chart.attached, isTrue);
      expect(canvas.parentNode, same(_host(tester)));

      await tester.pumpWidget(build(1, width: 300));
      await tester.pump();
      expect(chart.attachCalls, ['attached']);
      expect((chart.width, chart.height), (300.0, 300.0));
      chart.destroy();
    });
  });

  group('first resize notification at the next layout', () {
    // Chart.js ADR 0022, section 10: a DOM ResizeObserver gives its first
    // notification in the rendering step of the next frame, not at
    // observe().

    /// An observer that records the sizes of its notifications.
    ContainerResizeObserver recorder(List<Size> sizes) =>
        ContainerResizeObserver(
          onResize: (width, height) => sizes.add(Size(width, height)),
          onDevicePixelRatio: (_) {},
        );

    testWidgets('an observer of a laid-out host gets the size at the next '
        'layout', (tester) async {
      await tester.pumpWidget(_box(ChartHost(canvas: UiCanvasElement())));
      final sizes = <Size>[];
      final observer = recorder(sizes)..observe(_host(tester));
      expect(sizes, isEmpty);
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump();
      expect(sizes, [const Size(400, 300)]);
      await tester.pump();
      expect(sizes, [const Size(400, 300)]);
      observer.disconnect();
    });

    testWidgets('a disconnect before the next layout gives no notification', (
      tester,
    ) async {
      await tester.pumpWidget(_box(ChartHost(canvas: UiCanvasElement())));
      final sizes = <Size>[];
      recorder(sizes)
        ..observe(_host(tester))
        ..disconnect();
      await tester.pump();
      expect(sizes, isEmpty);
    });

    testWidgets('a size change gives a pending observer the new size once', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final sizes = <Size>[];
      final observer = recorder(sizes)..observe(_host(tester));
      await tester.pumpWidget(_box(ChartHost(canvas: canvas), width: 500));
      expect(sizes, [const Size(500, 300)]);
      await tester.pump();
      expect(sizes, [const Size(500, 300)]);
      observer.disconnect();
    });

    testWidgets('an observer that starts inside a layout waits for a '
        'relayout after the frame', (tester) async {
      // A chart that starts before the first layout observes the container
      // in its attach, inside the first layout of the host.
      final canvas = UiCanvasElement();
      final sizes = <Size>[];
      late final ContainerResizeObserver observer;
      final mutations = CanvasMutationObserver(({required connected}) {
        if (connected) {
          observer = recorder(sizes)
            ..observe(canvas.parentNode! as RenderChartHost);
        }
      })..observe(canvas);
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      expect(sizes, isEmpty);
      expect(tester.binding.hasScheduledFrame, isTrue);
      await tester.pump();
      expect(sizes, [const Size(400, 300)]);
      observer.disconnect();
      mutations.disconnect();
    });

    testWidgets('a new host gives a pending observer the size at its first '
        'layout', (tester) async {
      final canvas = UiCanvasElement();
      Widget build({required bool pad}) => _box(
        pad
            ? Padding(
                padding: EdgeInsets.zero,
                child: ChartHost(canvas: canvas),
              )
            : ChartHost(canvas: canvas),
        width: 300,
      );
      await tester.pumpWidget(build(pad: false));
      final sizes = <Size>[];
      final observer = recorder(sizes)..observe(_host(tester));
      // The new host takes over the pending observer in the same frame.
      await tester.pumpWidget(build(pad: true));
      expect(sizes, [const Size(300, 300)]);
      await tester.pump();
      expect(sizes, [const Size(300, 300)]);
      observer.disconnect();
    });
  });

  group('flushCanvasMutations', () {
    // Chart.js ADR 0022, section 10: the mutation checkpoint of the harness
    // reports the net attached state of each changed host at once.

    /// Shows [canvas] in a host with [key] while [show] is true.
    Widget build(UiCanvasElement canvas, Key key, ValueNotifier<bool> show) =>
        _box(
          ValueListenableBuilder<bool>(
            valueListenable: show,
            builder: (context, value, _) =>
                value ? ChartHost(key: key, canvas: canvas) : const SizedBox(),
          ),
        );

    /// The build of the dirty elements, without a frame: the forced build of
    /// the harness.
    void forcedBuild(WidgetTester tester) =>
        tester.binding.buildOwner!.buildScope(tester.binding.rootElement!);

    testWidgets('reports a net detach at once', (tester) async {
      final canvas = UiCanvasElement();
      final show = ValueNotifier(true);
      addTearDown(show.dispose);
      await tester.pumpWidget(build(canvas, GlobalKey(), show));
      final calls = <bool>[];
      final observer = CanvasMutationObserver(
        ({required connected}) => calls.add(connected),
      )..observe(canvas);
      show.value = false;
      forcedBuild(tester);
      // The post-frame check has not run.
      expect(calls, isEmpty);
      flushCanvasMutations();
      expect(calls, [false]);
      await tester.pump();
      expect(calls, [false]);
      observer.disconnect();
    });

    testWidgets('reports a detach and a later attach in order', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      final show = ValueNotifier(true);
      addTearDown(show.dispose);
      await tester.pumpWidget(build(canvas, GlobalKey(), show));
      final calls = <bool>[];
      final observer = CanvasMutationObserver(
        ({required connected}) => calls.add(connected),
      )..observe(canvas);
      show.value = false;
      forcedBuild(tester);
      flushCanvasMutations();
      show.value = true;
      forcedBuild(tester);
      flushCanvasMutations();
      expect(calls, [false, true]);
      await tester.pump();
      expect(calls, [false, true]);
      expect(_host(tester).isConnected, isTrue);
      observer.disconnect();
    });

    testWidgets('a detach and an attach before the call cancel each other', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      final show = ValueNotifier(true);
      addTearDown(show.dispose);
      await tester.pumpWidget(build(canvas, GlobalKey(), show));
      final calls = <bool>[];
      final observer = CanvasMutationObserver(
        ({required connected}) => calls.add(connected),
      )..observe(canvas);
      show.value = false;
      forcedBuild(tester);
      show.value = true;
      forcedBuild(tester);
      flushCanvasMutations();
      await tester.pump();
      expect(calls, isEmpty);
      observer.disconnect();
    });

    testWidgets('does nothing without a pending check', (tester) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final calls = <bool>[];
      final observer = CanvasMutationObserver(
        ({required connected}) => calls.add(connected),
      )..observe(canvas);
      flushCanvasMutations();
      expect(calls, isEmpty);
      observer.disconnect();
    });
  });

  group('events', () {
    Future<FakeChart> pumpChart(
      WidgetTester tester, {
      List<String> events = const [
        'mousemove',
        'mouseout',
        'click',
        'touchstart',
        'touchmove',
      ],
    }) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(
        canvas,
        maintainAspectRatio: false,
        events: events,
      );
      await tester.pump();
      return chart;
    }

    testWidgets('mouse hover gives one mousemove in a frame', (tester) async {
      final chart = await pumpChart(tester);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: const Offset(10, 10));
      await gesture.moveTo(const Offset(20.4, 30.6));
      await gesture.moveTo(const Offset(50.2, 60.7));
      expect(chart.events, isEmpty);
      await tester.pump();
      expect(chart.events, hasLength(1));
      final event = chart.events.single;
      expect(event.type, 'mousemove');
      expect((event.x, event.y), (50.0, 61.0));
      expect(event.chart, same(chart));
      expect(event.native!.type, 'mousemove');
      expect(event.native!.source, isA<PointerHoverEvent>());
      expect(event.native!.target, same(chart.canvas));
      chart.destroy();
    });

    testWidgets('mouse exit gives mouseout, enter gives mouseenter', (
      tester,
    ) async {
      final chart = await pumpChart(
        tester,
        events: const ['mouseout', 'mouseenter', 'pointerleave'],
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: const Offset(500, 500));
      await gesture.moveTo(const Offset(100, 100));
      await tester.pump();
      expect(_nativeTypes(chart), ['mouseenter']);
      await gesture.moveTo(const Offset(450, 100));
      await tester.pump();
      // pointerleave maps to the Chart.js type mouseout.
      // The DOM order: pointerout, pointerleave, mouseout, mouseleave.
      expect(_nativeTypes(chart), ['mouseenter', 'pointerleave', 'mouseout']);
      expect(chart.events.last.type, 'mouseout');
      chart.destroy();
    });

    testWidgets('a mouse click gives mousedown, mouseup and click', (
      tester,
    ) async {
      final chart = await pumpChart(
        tester,
        events: const ['mousedown', 'mouseup', 'click', 'pointerdown'],
      );
      await tester.tapAt(const Offset(100, 50), kind: PointerDeviceKind.mouse);
      await tester.pump();
      expect(_nativeTypes(chart), [
        'pointerdown',
        'mousedown',
        'mouseup',
        'click',
      ]);
      // pointerdown maps to mousedown.
      expect(chart.events.map((e) => e.type), [
        'mousedown',
        'mousedown',
        'mouseup',
        'click',
      ]);
      expect((chart.events.last.x, chart.events.last.y), (100.0, 50.0));
      chart.destroy();
    });

    testWidgets('two touches give a sorted touches list', (tester) async {
      final chart = await pumpChart(
        tester,
        events: const ['touchstart', 'touchmove', 'touchend'],
      );
      final first = await tester.startGesture(const Offset(10, 20));
      await tester.pump();
      final second = await tester.startGesture(const Offset(110, 120));
      await tester.pump();
      await second.moveTo(const Offset(130, 140));
      await tester.pump();
      await first.up();
      await tester.pump();
      await second.up();
      await tester.pump();

      expect(chart.events.map((e) => e.type), [
        'mousedown',
        'mousedown',
        'mousemove',
        'mouseup',
        'mouseup',
      ]);
      final natives = [for (final e in chart.events) e.native!];
      expect(natives.map((e) => e.type), [
        'touchstart',
        'touchstart',
        'touchmove',
        'touchend',
        'touchend',
      ]);
      expect(natives[1].touches.map((t) => (t.x, t.y)), [
        (10.0, 20.0),
        (110.0, 120.0),
      ]);
      expect(
        natives[1].touches.first.identifier,
        lessThan(natives[1].touches.last.identifier),
      );
      // The position is the first touch, as upstream reads touches[0].
      expect((chart.events[2].x, chart.events[2].y), (10.0, 20.0));
      expect(natives[3].touches.map((t) => (t.x, t.y)), [(130.0, 140.0)]);
      expect((chart.events[3].x, chart.events[3].y), (130.0, 140.0));
      // The last touchend has no touches: NaN coordinates, as upstream.
      expect(natives[4].touches, isEmpty);
      expect(chart.events[4].x, isNaN);
      expect(chart.events[4].y, isNaN);
      chart.destroy();
    });

    testWidgets('a scroll signal gives wheel', (tester) async {
      final chart = await pumpChart(tester, events: const ['wheel']);
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(const Offset(40, 40)));
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 20)));
      await tester.pump();
      expect(_nativeTypes(chart), ['wheel']);
      expect(chart.events.single.native!.source, isA<PointerScrollEvent>());
      chart.destroy();
    });

    testWidgets('a parent ListView still scrolls from a drag on the host', (
      tester,
    ) async {
      final canvas = UiCanvasElement();
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _box(
          ListView(
            controller: controller,
            children: [
              SizedBox(height: 200, child: ChartHost(canvas: canvas)),
              const SizedBox(height: 1000),
            ],
          ),
        ),
      );
      final chart = FakeChart(
        canvas,
        maintainAspectRatio: false,
        events: const ['click', 'touchmove'],
      );
      await tester.pump();
      await tester.dragFrom(const Offset(100, 150), const Offset(0, -100));
      await tester.pump();
      expect(controller.offset, greaterThan(0));
      expect(_nativeTypes(chart), contains('touchmove'));
      expect(_nativeTypes(chart), isNot(contains('click')));

      chart.events.clear();
      controller.jumpTo(0);
      await tester.pump();
      await tester.tapAt(const Offset(100, 100));
      await tester.pump();
      expect(_nativeTypes(chart), ['click']);
      chart.destroy();
    });

    for (final events in const [
      ['click'],
      ['mousemove'],
    ]) {
      testWidgets('a tappable ancestor and the chart both get the tap, with '
          'the chart events $events', (tester) async {
        // The host claims nothing in the gesture arena (Chart.js ADR 0037,
        // sections 7 and 10). A DOM click also reaches the ancestor by
        // bubbling. The chart gets the click or the compatibility mousemove
        // of the tap.
        final canvas = UiCanvasElement();
        var parentTaps = 0;
        await tester.pumpWidget(
          _box(
            GestureDetector(
              onTap: () => parentTaps++,
              child: ChartHost(canvas: canvas),
            ),
          ),
        );
        final chart = FakeChart(
          canvas,
          maintainAspectRatio: false,
          events: events,
        );
        await tester.pump();
        await tester.tapAt(const Offset(50, 50));
        await tester.pump();
        expect(parentTaps, 1);
        expect(_nativeTypes(chart), events);
        chart.destroy();
      });
    }

    // Chart.js ADR 0037, section 11: the per-type proxies of one frame run
    // in the order of the first event of each type, as the animation frame
    // callbacks of a browser do (D3 and D4 of the input design probes).

    /// A chart at (0, 40) with the events mousemove and mouseout, and a
    /// mouse pointer outside the chart.
    Future<(FakeChart, TestGesture)> pumpMouse(WidgetTester tester) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(
        _box(
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: ChartHost(canvas: canvas),
          ),
        ),
      );
      final chart = FakeChart(
        canvas,
        maintainAspectRatio: false,
        events: const ['mousemove', 'mouseout'],
      );
      await tester.pump();
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: const Offset(100, 20));
      await tester.pump();
      return (chart, gesture);
    }

    testWidgets('a mouse move and an exit in one frame give mousemove, then '
        'mouseout', (tester) async {
      final (chart, gesture) = await pumpMouse(tester);
      await gesture.moveTo(const Offset(100, 50));
      await gesture.moveTo(const Offset(100, 20));
      await tester.pump();
      expect(_nativeTypes(chart), ['mousemove', 'mouseout']);
      expect(
        [for (final event in chart.events) (event.x, event.y)],
        [(100.0, 10.0), (100.0, -20.0)],
      );
      chart.destroy();
    });

    testWidgets('a move, an exit and a move back give mousemove, then '
        'mouseout', (tester) async {
      final (chart, gesture) = await pumpMouse(tester);
      await gesture.moveTo(const Offset(100, 50));
      await gesture.moveTo(const Offset(100, 20));
      await gesture.moveTo(const Offset(120, 70));
      await tester.pump();
      // The mousemove proxy runs first, with the last move.
      expect(_nativeTypes(chart), ['mousemove', 'mouseout']);
      expect(
        [for (final event in chart.events) (event.x, event.y)],
        [(120.0, 30.0), (100.0, -20.0)],
      );
      chart.destroy();
    });

    testWidgets('a mouse up outside the box gives no mouseup', (tester) async {
      final chart = await pumpChart(
        tester,
        events: const ['mousedown', 'mouseup', 'pointerup', 'mousemove'],
      );
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: const Offset(10, 10));
      await gesture.down(const Offset(10, 10));
      await tester.pump();
      await gesture.moveTo(const Offset(700, 500));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(_nativeTypes(chart), ['mousedown']);

      // An up inside the box still gives mouseup.
      await gesture.down(const Offset(20, 20));
      await gesture.up();
      await tester.pump();
      expect(_nativeTypes(chart), [
        'mousedown',
        'mousedown',
        'pointerup',
        'mouseup',
      ]);
      chart.destroy();
    });

    testWidgets('an inverted stylus hover gives mouseover and mouseout', (
      tester,
    ) async {
      final chart = await pumpChart(
        tester,
        events: const ['mousemove', 'mouseout', 'mouseover'],
      );
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.invertedStylus,
      );
      await gesture.addPointer(location: const Offset(10, 10));
      await gesture.moveTo(const Offset(20, 20));
      await tester.pump();
      await gesture.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(_nativeTypes(chart), ['mouseover', 'mousemove', 'mouseout']);
      expect((chart.events.last.x, chart.events.last.y), (700.0, 500.0));

      // The removal of a pointer over the box gives mouseout.
      chart.events.clear();
      await gesture.moveTo(const Offset(30, 30));
      await tester.pump();
      await gesture.removePointer();
      await tester.pump();
      expect(_nativeTypes(chart), ['mouseover', 'mousemove', 'mouseout']);
      chart.destroy();
    });

    testWidgets('a destroyed chart gets no pending event', (tester) async {
      final chart = await pumpChart(tester);
      final canvas = chart.canvas!;
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: const Offset(10, 10));
      await gesture.moveTo(const Offset(20, 20));
      chart.destroy();
      await tester.pump();
      expect(chart.events, isEmpty);
      expect(hasCanvasEventListener(canvas, 'mousemove'), isFalse);
    });

    testWidgets('dispose stops the events of the host', (tester) async {
      final chart = await pumpChart(tester);
      final canvas = chart.canvas! as UiCanvasElement;
      await tester.pumpWidget(_box(const SizedBox()));
      await tester.tapAt(const Offset(100, 100));
      await tester.pump();
      expect(chart.events, isEmpty);
      expect(canvas.parentNode, isNull);
      chart.destroy();
      expect(hasCanvasEventListener(canvas, 'click'), isFalse);
    });
  });

  group('compatibility mouse', () {
    // Chart.js ADR 0037, sections 6 to 10: the touch boundary events, the
    // DOM click rule, the tap rule, the long press, and the compatibility
    // mouse with its global pointer route. The raw listeners of _record see
    // each native event at once. A host without a chart is 300 x 150.

    // The unmount at the end of a test ends the owner: no owner and no route
    // stays for the next test of the file.
    setUp(() => expect(_owner, isNull));

    /// Shows a host at (40, 0) and records its events in [log]. Outside the
    /// host, the global point (20, 50) is (-20, 50) in host coordinates.
    Future<UiCanvasElement> pumpHost(
      WidgetTester tester,
      List<NativeEvent> log, {
      double touchSlop = kTouchSlop,
    }) async {
      final canvas = UiCanvasElement();
      _record(canvas, log);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            gestureSettings: DeviceGestureSettings(touchSlop: touchSlop),
          ),
          child: _box(
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: ChartHost(canvas: canvas),
            ),
          ),
        ),
      );
      expect(_host(tester).size, const Size(300, 150));
      return canvas;
    }

    testWidgets('a touch tap gives the touch, boundary and compatibility '
        'events in DOM order', (tester) async {
      final canvas = UiCanvasElement();
      await tester.pumpWidget(_box(ChartHost(canvas: canvas)));
      final chart = FakeChart(
        canvas,
        maintainAspectRatio: false,
        events: _allTypes,
      );
      await tester.pump();
      final gesture = await tester.startGesture(const Offset(100, 50));
      await tester.pump();
      await gesture.moveTo(const Offset(105, 52));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(_nativeTypes(chart), [
        'pointerover',
        'pointerenter',
        'pointerdown',
        'touchstart',
        'pointermove',
        'touchmove',
        'pointerup',
        'pointerout',
        'pointerleave',
        'touchend',
        'mouseover',
        'mouseenter',
        'mousemove',
        'mousedown',
        'mouseup',
        'click',
      ]);
      // The touch events have no offsets: their position comes from
      // touches. The other events have the position of the touch. The
      // compatibility events and the click have the up position.
      for (final event in chart.events) {
        final native = event.native!;
        if (native.type.startsWith('touch')) {
          expect(native.offsetX, isNaN);
          expect(native.offsetY, isNaN);
        } else if (const [
          'pointerover',
          'pointerenter',
          'pointerdown',
        ].contains(native.type)) {
          expect((native.offsetX, native.offsetY), (100.0, 50.0));
        } else {
          expect((native.offsetX, native.offsetY), (105.0, 52.0));
        }
      }
      expect((chart.events[3].x, chart.events[3].y), (100.0, 50.0));
      expect(chart.events[9].x, isNaN);
      expect(_owner, same(_host(tester)));
      chart.destroy();
    });

    testWidgets('a second tap on the same host gives no mouseover and no '
        'mouseenter', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      await tester.tapAt(const Offset(100, 50));
      expect(_types(log), containsAllInOrder(['mouseover', 'mouseenter']));
      log.clear();
      await tester.tapAt(const Offset(120, 60));
      expect(_types(log), [
        'pointerover',
        'pointerenter',
        'pointerdown',
        'touchstart',
        'pointerup',
        'pointerout',
        'pointerleave',
        'touchend',
        'mousemove',
        'mousedown',
        'mouseup',
        'click',
      ]);
      expect((log.last.offsetX, log.last.offsetY), (80.0, 60.0));
    });

    testWidgets('a tap outside the host gives mouseout and mouseleave once', (
      tester,
    ) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      // flutter_test has a global route of its own.
      final routes = _globalRoutes(tester);
      expect(_owner, isNull);
      await tester.tapAt(const Offset(100, 50));
      expect(_globalRoutes(tester), routes + 1);
      log.clear();
      await tester.tapAt(const Offset(20, 50));
      expect(_types(log), ['mouseout', 'mouseleave']);
      for (final event in log) {
        expect((event.offsetX, event.offsetY), (-20.0, 50.0));
        expect(event.source, isA<PointerUpEvent>());
      }
      expect(_owner, isNull);
      expect(_globalRoutes(tester), routes);
      log.clear();
      await tester.tapAt(const Offset(20, 50));
      expect(log, isEmpty);
      expect(_globalRoutes(tester), routes);
    });

    testWidgets('the route ignores the up of the tap that made the owner', (
      tester,
    ) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final routes = _globalRoutes(tester);
      await tester.tapAt(const Offset(100, 50));
      await tester.pump();
      expect(_types(log), isNot(contains('mouseout')));
      expect(_owner, same(_host(tester)));
      expect(_globalRoutes(tester), routes + 1);
    });

    testWidgets('a drag outside after a tap gives no mouseout', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final routes = _globalRoutes(tester);
      await tester.tapAt(const Offset(100, 50));
      log.clear();
      await tester.dragFrom(const Offset(200, 280), const Offset(0, -100));
      await tester.pump();
      expect(log, isEmpty);
      expect(_owner, same(_host(tester)));
      expect(_globalRoutes(tester), routes + 1);
    });

    testWidgets('a mouse click outside after a tap gives no mouseout', (
      tester,
    ) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      await tester.tapAt(const Offset(100, 50));
      log.clear();
      await tester.tapAt(const Offset(20, 50), kind: PointerDeviceKind.mouse);
      await tester.pump();
      expect(log, isEmpty);
      expect(_owner, same(_host(tester)));
    });

    testWidgets('a touch move past the slop on the host gives no '
        'compatibility event and no click', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final routes = _globalRoutes(tester);
      final gesture = await tester.startGesture(const Offset(100, 50));
      await gesture.moveBy(const Offset(30, 0));
      await gesture.moveBy(const Offset(-30, 0));
      await gesture.up();
      await tester.pump();
      expect(_types(log), [
        'pointerover',
        'pointerenter',
        'pointerdown',
        'touchstart',
        'pointermove',
        'touchmove',
        'pointermove',
        'touchmove',
        'pointerup',
        'pointerout',
        'pointerleave',
        'touchend',
      ]);
      expect(_owner, isNull);
      expect(_globalRoutes(tester), routes);
    });

    testWidgets('a touch held for kLongPressTimeout gives mouseover, '
        'mouseenter and mousemove before the lift', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final gesture = await tester.startGesture(const Offset(100, 50));
      await gesture.moveBy(const Offset(4, 3));
      log.clear();
      await tester.pump(kLongPressTimeout - const Duration(milliseconds: 1));
      expect(log, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(_types(log), ['mouseover', 'mouseenter', 'mousemove']);
      expect((log.last.offsetX, log.last.offsetY), (64.0, 53.0));
      expect(_owner, same(_host(tester)));
      log.clear();
      await gesture.up();
      await tester.pump();
      expect(_types(log), [
        'pointerup',
        'pointerout',
        'pointerleave',
        'touchend',
      ]);
      // The route ignores the lift of the long press.
      expect(_owner, same(_host(tester)));
    });

    testWidgets('a long press outside gives mouseout to the owner at the '
        'long-press time', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final routes = _globalRoutes(tester);
      await tester.tapAt(const Offset(100, 50));
      log.clear();
      final gesture = await tester.startGesture(const Offset(20, 50));
      await tester.pump(const Duration(milliseconds: 400));
      expect(log, isEmpty);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_types(log), ['mouseout', 'mouseleave']);
      expect((log.last.offsetX, log.last.offsetY), (-20.0, 50.0));
      expect(_owner, isNull);
      expect(_globalRoutes(tester), routes);
      log.clear();
      await gesture.up();
      await tester.pump();
      expect(log, isEmpty);
    });

    testWidgets('a second finger gives no tap', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final first = await tester.startGesture(const Offset(100, 50));
      final second = await tester.startGesture(const Offset(150, 60));
      await first.up();
      await second.up();
      await tester.pump();
      expect(_types(log), isNot(contains('mousemove')));
      expect(_types(log), isNot(contains('click')));
      expect(_types(log).where((type) => type == 'touchend'), hasLength(2));
      expect(_owner, isNull);
    });

    testWidgets('a second finger outside gives no mouseout', (tester) async {
      // The tap rule of the route: only the first touch pointer outside can
      // be a tap.
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      await tester.tapAt(const Offset(100, 50));
      log.clear();
      final first = await tester.startGesture(const Offset(20, 50));
      final second = await tester.startGesture(const Offset(20, 200));
      await second.up();
      final third = await tester.startGesture(const Offset(20, 250));
      await third.up();
      await first.up();
      await tester.pump();
      expect(log, isEmpty);
      expect(_owner, same(_host(tester)));
    });

    testWidgets('a second finger on the host gives no mouseout', (
      tester,
    ) async {
      // A touch down on a host ends the candidate of the route too (Chart.js
      // ADR 0037, sections 8 and 9): the finger outside is not a tap.
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final routes = _globalRoutes(tester);
      await tester.tapAt(const Offset(100, 50));
      log.clear();
      final first = await tester.startGesture(const Offset(20, 50));
      final second = await tester.startGesture(const Offset(100, 50));
      await first.up();
      await tester.pump();
      expect(_types(log), [
        'pointerover',
        'pointerenter',
        'pointerdown',
        'touchstart',
      ]);
      expect(_owner, same(_host(tester)));
      expect(_globalRoutes(tester), routes + 1);
      log.clear();
      // The finger on the host is the only touch pointer of the host: it is
      // a tap on the owner (Chart.js ADR 0037, Open 6).
      await second.up();
      await tester.pump();
      expect(_types(log), [
        'pointerup',
        'pointerout',
        'pointerleave',
        'touchend',
        'mousemove',
        'mousedown',
        'mouseup',
        'click',
      ]);
      expect(_owner, same(_host(tester)));
    });

    testWidgets('a touch cancel gives pointercancel, pointerout, pointerleave '
        'and touchcancel only', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final gesture = await tester.startGesture(const Offset(100, 50));
      log.clear();
      await gesture.cancel();
      await tester.pump(kLongPressTimeout);
      expect(_types(log), [
        'pointercancel',
        'pointerout',
        'pointerleave',
        'touchcancel',
      ]);
      expect(_owner, isNull);
    });

    testWidgets('a mouse click with a 30 px move inside the box gives click', (
      tester,
    ) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.down(const Offset(100, 50));
      await gesture.moveBy(const Offset(30, 0));
      await gesture.up();
      await tester.pump();
      expect(
        _types(log)
            .where((type) => type.startsWith('mouse') || type == 'click'),
        [
          'mouseover',
          'mouseenter',
          'mousedown',
          'mousemove',
          'mouseup',
          'click',
        ],
      );
      expect((log.last.offsetX, log.last.offsetY), (90.0, 50.0));
      // A mouse is not the compatibility mouse.
      expect(_owner, isNull);
    });

    testWidgets('a mouse up outside the box gives no click', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.down(const Offset(100, 50));
      await gesture.moveTo(const Offset(20, 50));
      await gesture.up();
      // A later up inside the box after a down outside gives no click.
      await gesture.down(const Offset(20, 60));
      await gesture.moveTo(const Offset(100, 60));
      await gesture.up();
      await tester.pump();
      expect(_types(log), isNot(contains('click')));
    });

    testWidgets('a secondary-button click gives no click', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      addTearDown(gesture.removePointer);
      await gesture.down(const Offset(100, 50));
      await gesture.up();
      await tester.pump();
      expect(_types(log), containsAllInOrder(['mousedown', 'mouseup']));
      expect(_types(log), isNot(contains('click')));
    });

    testWidgets('a tap on host B after a tap on host A moves the '
        'compatibility mouse', (tester) async {
      final a = UiCanvasElement();
      final b = UiCanvasElement();
      final log = <NativeEvent>[];
      _record(a, log);
      _record(b, log);
      await tester.pumpWidget(
        _box(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 200, child: ChartHost(canvas: a)),
              SizedBox(width: 200, child: ChartHost(canvas: b)),
            ],
          ),
        ),
      );
      final routes = _globalRoutes(tester);
      await tester.tapAt(const Offset(50, 50));
      log.clear();
      await tester.tapAt(const Offset(250, 60));
      expect(
        [
          for (final event in log)
            if (!event.type.startsWith('pointer') &&
                !event.type.startsWith('touch'))
              '${identical(event.target, a) ? 'A' : 'B'} ${event.type}',
        ],
        [
          'A mouseout',
          'A mouseleave',
          'B mouseover',
          'B mouseenter',
          'B mousemove',
          'B mousedown',
          'B mouseup',
          'B click',
        ],
      );
      // A gets the position of the tap in its own coordinates.
      final out = log.firstWhere((event) => event.type == 'mouseout');
      expect(out.target, same(a));
      expect((out.offsetX, out.offsetY), (250.0, 60.0));
      expect((log.last.offsetX, log.last.offsetY), (50.0, 60.0));
      expect(_owner, isA<RenderChartHost>());
      expect(_owner!.canvas, same(b));
      expect(_globalRoutes(tester), routes + 1);
    });

    testWidgets('the detach of the owner removes the route and sends '
        'nothing', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final routes = _globalRoutes(tester);
      await tester.tapAt(const Offset(100, 50));
      expect(_owner, isNotNull);
      log.clear();
      await tester.pumpWidget(_box(const SizedBox.shrink()));
      expect(_owner, isNull);
      expect(_globalRoutes(tester), routes);
      await tester.tapAt(const Offset(20, 50));
      expect(log, isEmpty);
    });

    testWidgets('the detach of a host with a finger down cancels the long '
        'press', (tester) async {
      final log = <NativeEvent>[];
      await pumpHost(tester, log);
      final gesture = await tester.startGesture(const Offset(100, 50));
      await tester.pumpWidget(_box(const SizedBox.shrink()));
      log.clear();
      await tester.pump(kLongPressTimeout);
      expect(log, isEmpty);
      expect(_owner, isNull);
      // The up still reaches the old host through the hit path of its down,
      // as a DOM touch keeps its target. It is not a tap.
      await gesture.up();
      expect(_types(log), [
        'pointerup',
        'pointerout',
        'pointerleave',
        'touchend',
      ]);
      expect(_owner, isNull);
    });

    for (final (move, tap) in const [(10.0, false), (7.0, true)]) {
      testWidgets('the touch slop comes from MediaQuery: a move of $move px '
          'gives ${tap ? 'a' : 'no'} tap', (tester) async {
        final log = <NativeEvent>[];
        await pumpHost(tester, log, touchSlop: 8);
        final gesture = await tester.startGesture(const Offset(100, 50));
        await gesture.moveBy(Offset(move, 0));
        await gesture.up();
        expect(_types(log).contains('click'), tap);
        expect(_types(log).contains('mousemove'), tap);
      });
    }
  });

  group('canvas event target', () {
    test('adds a listener once and removes it', () {
      final canvas = UiCanvasElement();
      final received = <String>[];
      void listener(NativeEvent event) => received.add(event.type);
      addCanvasEventListener(canvas, 'click', listener);
      addCanvasEventListener(canvas, 'click', listener);
      dispatchCanvasEvent(
        canvas,
        NativeEvent(type: 'click', offsetX: 1, offsetY: 2),
      );
      expect(received, ['click']);
      removeCanvasEventListener(canvas, 'click', listener);
      expect(hasCanvasEventListener(canvas, 'click'), isFalse);
      dispatchCanvasEvent(
        canvas,
        NativeEvent(type: 'click', offsetX: 1, offsetY: 2),
      );
      expect(received, ['click']);
    });
  });
}
