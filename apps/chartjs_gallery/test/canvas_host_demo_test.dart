import 'package:chartjs_gallery/canvas_host_demo.dart';
import 'package:chartjs_gallery/demo/demo_chart.dart';
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:chartjs_gallery/main.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/platform/chart_host.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stress_controls.dart';

/// A Pixel 8a: 412 x 915 logical pixels at DPR 2.625.
const Size _phone = Size(412, 915);
const double _phoneDpr = 2.625;

/// Pumps the demo page at [size] logical pixels and [dpr].
Future<void> _pumpDemo(
  WidgetTester tester, {
  Size size = _phone,
  double dpr = _phoneDpr,
}) async {
  tester.view
    ..physicalSize = size * dpr
    ..devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xFFFF6384)),
      home: const CanvasHostDemoPage(),
    ),
  );
  await _frames(tester);
}

/// Pumps a few frames: the demo charts start after the first frame, and the
/// throttled platform proxies call back in the next frame. The page has a
/// running animation (the line dash), so pumpAndSettle would not return.
Future<void> _frames(WidgetTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _openTab(WidgetTester tester, String key) async {
  await _tapTab(tester, key);
  await _frames(tester, 25);
}

/// The canvas of the chart host inside the widget of [key].
UiCanvasElement _canvasOf(WidgetTester tester, String key) => tester
    .widget<ChartHost>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(ChartHost),
      ),
    )
    .canvas;

/// The vertical scrollable of the open tab.
Finder get _page => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

Future<void> _scrollTo(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(
    find.byKey(ValueKey(key)),
    200,
    scrollable: _page,
  );
  await _frames(tester);
}

/// Scrolls the widget of [key] into view and taps it.
Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _frames(tester);
}

/// Checks that the host of [key] shows a sized, drawn canvas at [dpr].
void _expectDrawn(WidgetTester tester, String key, {double dpr = _phoneDpr}) {
  final canvas = _canvasOf(tester, key);
  final box = tester.getSize(
    find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(ChartHost),
    ),
  );
  expect(canvas.parentNode, isNotNull, reason: key);
  expect(canvas.style.getPropertyValue('width'), isNotEmpty, reason: key);
  expect(canvas.width, (box.width * dpr).truncate(), reason: key);
  expect(canvas.height, (box.height * dpr).truncate(), reason: key);
  expect(canvas.getContext2d().isEmpty, isFalse, reason: key);
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('the gallery opens the phase 3 demo above the phase 2 demo', (
    tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());
    final phase3 = find.byKey(const ValueKey('gallery.canvasHostDemo'));
    final phase2 = find.byKey(const ValueKey('gallery.helpersDemo'));
    expect(
      find.text('Phase 3: canvas layer and chart host — live demo'),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(phase3).dy,
      lessThan(tester.getTopLeft(phase2).dy),
    );
    expect(
      find.textContaining('render through the ported controllers'),
      findsOneWidget,
    );

    await tester.tap(phase3);
    await _frames(tester, 30);
    expect(find.byType(CanvasHostDemoPage), findsOneWidget);
    expect(find.text('Phase 3: canvas and host'), findsOneWidget);
    for (final tab in canvasHostDemoTabs) {
      expect(find.byKey(ValueKey('phase3.tab.${tab.key}')), findsOneWidget);
    }
  });

  testWidgets('canvas: every card draws and a point style switch works', (
    tester,
  ) async {
    await _pumpDemo(tester);
    _expectDrawn(tester, 'canvas.pointStyles');

    // Switch off the star style: one style fewer, the chip is off.
    final star = find.byKey(const ValueKey('canvas.style.star'));
    expect(tester.widget<FilterChip>(star).selected, isTrue);
    await tester.tap(star);
    await _frames(tester);
    expect(tester.widget<FilterChip>(star).selected, isFalse);
    _expectDrawn(tester, 'canvas.pointStyles');

    await _scrollTo(tester, 'canvas.text.rotation');
    await _tapKey(tester, 'canvas.text.multiLine');
    await _tapKey(tester, 'canvas.text.underline');
    await _scrollTo(tester, 'canvas.renderText');
    _expectDrawn(tester, 'canvas.renderText');

    for (final key in [
      'canvas.roundedRect',
      'canvas.lines',
      'canvas.clip',
      'canvas.paint',
    ]) {
      await _scrollTo(tester, key);
      _expectDrawn(tester, key);
    }
    await _tapKey(tester, 'canvas.dash.animate');
    expect(tester.takeException(), isNull);
  });

  testWidgets('events: a pointer move and a tap reach the chart', (
    tester,
  ) async {
    await _pumpDemo(tester);
    await _openTab(tester, 'events');
    _expectDrawn(tester, 'events.host');
    expect(find.textContaining('platform FlutterPlatform'), findsOneWidget);

    final host = find.descendant(
      of: find.byKey(const ValueKey('events.host')),
      matching: find.byType(ChartHost),
    );
    final center = tester.getCenter(host);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: center - const Offset(100, 60));
    await mouse.moveTo(center);
    await mouse.moveTo(center + const Offset(10, 5));
    await _frames(tester, 3);
    final log = find.byKey(const ValueKey('events.log'));
    expect(
      find.descendant(of: log, matching: find.textContaining('mousemove')),
      findsWidgets,
    );
    await mouse.removePointer();

    await tester.tapAt(center);
    await _frames(tester, 3);
    expect(
      // The DOM name and the Chart.js type of the click.
      find.descendant(of: log, matching: find.text('click')),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: log, matching: find.textContaining('touchstart')),
      findsOneWidget,
    );
    expect(find.textContaining('ChartEvents delivered'), findsOneWidget);

    // maintainAspectRatio: the height becomes width / 2.
    await _scrollTo(tester, 'events.maintainAspectRatio');
    await _tapKey(tester, 'events.maintainAspectRatio');
    await _frames(tester, 6);
    final size = tester.getSize(host);
    expect(size.height, closeTo(size.width / 2, 0.1));
    _expectDrawn(tester, 'events.host');
    expect(tester.takeException(), isNull);
  });

  testWidgets('text: the grid, the RTL switch and _longestText', (
    tester,
  ) async {
    await _pumpDemo(tester, size: const Size(1280, 900), dpr: 1);
    await _openTab(tester, 'text');
    _expectDrawn(tester, 'text.grid', dpr: 1);

    String longest() => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('text.longest')),
            matching: find.textContaining('longestText'),
          ),
        )
        .textSpan!
        .toPlainText();
    await _scrollTo(tester, 'text.longest');
    final before = longest();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('text.sample')),
      -200,
      scrollable: _page,
    );
    await tester.enterText(
      find.byKey(const ValueKey('text.sample')),
      'A much longer sample text than every label',
    );
    await _frames(tester);
    await _scrollTo(tester, 'text.longest');
    expect(longest(), isNot(before));

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('text.rtl')),
      -200,
      scrollable: _page,
    );
    await tester.tap(find.byKey(const ValueKey('text.rtl')));
    await _frames(tester);
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('text.rtl')))
          .selected,
      isTrue,
    );
    await _scrollTo(tester, 'text.rtlLegend');
    _expectDrawn(tester, 'text.rtlLegend', dpr: 1);
    await _scrollTo(tester, 'text.longestCanvas');
    _expectDrawn(tester, 'text.longestCanvas', dpr: 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fillText paints with the fill style', (tester) async {
    // The demo labels use fillStyle '#666'; a fill paragraph without its
    // color painted black.
    await tester.runAsync(() async {
      final canvas = UiCanvasElement(width: 40, height: 40);
      final ctx = canvas.getContext2d()
        ..font = '32px sans-serif'
        ..textBaseline = 'top'
        ..fillStyle = '#FF0000'
        ..fillText('X', 4, 4);
      final source = canvas.toImageSource();
      expect(await _pixel(source, 20, 20), 0xFFFF0000);
      source.image.dispose();
      ctx.dispose();
    });
  });

  testWidgets('stress: N and M change, and the loop draws frames', (
    tester,
  ) async {
    await _pumpDemo(tester);
    await _openTab(tester, 'stress');
    _expectDrawn(tester, 'stress.host');

    expect(await stressSelected(tester, 'stress.n.1000'), isTrue);
    await stressTap(tester, 'stress.n.5000');
    await stressTap(tester, 'stress.m.200');
    await _frames(tester);
    expect(await stressSelected(tester, 'stress.n.5000'), isTrue);
    expect(await stressSelected(tester, 'stress.n.1000'), isFalse);
    expect(await stressSelected(tester, 'stress.m.200'), isTrue);

    await stressTap(tester, 'stress.start');
    await _frames(tester, 10);
    final renders = _renders(tester);
    await _frames(tester, 5);
    expect(_renders(tester), greaterThan(renders));
    await stressTap(tester, 'stress.start');
    await _frames(tester);
    final stats = find.byKey(const ValueKey('stress.stats'));
    expect(
      find.descendant(of: stats, matching: find.textContaining('frames 0')),
      findsNothing,
    );
    final stopped = _renders(tester);
    await _frames(tester, 5);
    expect(_renders(tester), stopped);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stress: in each mode, the host is in view at 412 x 915 '
      '(Chart.js ADR 0031, section 10)', (tester) async {
    await _pumpDemo(tester);
    await _openTab(tester, 'stress');
    final view = Offset.zero & _phone;
    void expectInView(String host, String reason) {
      final position = tester.state<ScrollableState>(_page).position;
      expect(position.pixels, 0, reason: reason);
      final rect = tester.getRect(find.byKey(ValueKey(host)));
      expect(rect.height, greaterThan(0), reason: reason);
      expect(view.contains(rect.topLeft), isTrue, reason: '$reason $rect');
      expect(
        view.contains(rect.bottomRight - const Offset(0.01, 0.01)),
        isTrue,
        reason: '$reason $rect',
      );
    }

    for (final mode in StressMode.values) {
      // The mode line is at the top of the tab: a tap needs no scroll.
      await tester.tap(find.byKey(ValueKey('stress.mode.${mode.name}')));
      await _frames(tester, 6);
      final host = switch (mode) {
        StressMode.chart => 'stress.chart.host',
        StressMode.axes => 'stress.axes.host',
        _ => 'stress.host',
      };
      if (mode == StressMode.chart) {
        for (final type in ['line', 'bar']) {
          await tester.tap(find.byKey(ValueKey('stress.chart.type.$type')));
          await _frames(tester, 6);
          expectInView(host, '${mode.name} $type');
        }
      } else {
        expectInView(host, mode.name);
      }
    }
    expect(tester.takeException(), isNull);
  });

  for (final size in [_phone, const Size(360, 640)]) {
    testWidgets('the tab bar does not scroll, and each tab is in view at '
        '${size.width.toInt()} x ${size.height.toInt()} (Chart.js ADR 0031, '
        'section 10)', (tester) async {
      await _pumpDemo(tester, size: size);
      final bar = find.byType(TabBar);
      expect(
        find.descendant(
          of: bar,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Scrollable &&
                axisDirectionToAxis(w.axisDirection) == Axis.horizontal,
          ),
        ),
        findsNothing,
      );
      final view = Offset.zero & size;
      for (final tab in canvasHostDemoTabs) {
        final rect = tester.getRect(
          find.byKey(ValueKey('phase3.tab.${tab.key}')),
        );
        expect(rect.width, greaterThan(0), reason: tab.key);
        expect(view.contains(rect.topLeft), isTrue, reason: '${tab.key} $rect');
        expect(
          view.contains(rect.bottomRight - const Offset(0.01, 0.01)),
          isTrue,
          reason: '${tab.key} $rect',
        );
      }
      await tester.tap(find.byKey(const ValueKey('phase3.tab.axes')));
      await _frames(tester);
      expect(
        DefaultTabController.of(tester.element(bar)).index,
        canvasHostDemoTabs.indexWhere((tab) => tab.key == 'axes'),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('canvas: a card keeps its state when it scrolls out of view', (
    tester,
  ) async {
    await _pumpDemo(tester);
    final star = find.byKey(const ValueKey('canvas.style.star'));
    await tester.tap(star);
    await _frames(tester);
    expect(tester.widget<FilterChip>(star).selected, isFalse);

    await _scrollTo(tester, 'canvas.paint');
    await tester.scrollUntilVisible(star, -400, scrollable: _page);
    await _frames(tester);
    expect(tester.widget<FilterChip>(star).selected, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a hidden tab mutes its tickers and its chart loops', (
    tester,
  ) async {
    await _pumpDemo(tester);

    // The stress loop stops while the Canvas tab shows.
    await _openTab(tester, 'stress');
    await tester.tap(find.byKey(const ValueKey('stress.start')));
    await _frames(tester, 5);
    await _openTab(tester, 'canvas');
    final stress = _renders(tester);
    await _frames(tester, 10);
    expect(_renders(tester), stress);

    // The animated line dash of the Paint card stops while the Stress tab
    // shows.
    await _scrollTo(tester, 'canvas.paint');
    await _frames(tester, 5);
    final paint = tester.state<DemoCanvasState>(
      find.byKey(const ValueKey('canvas.paint'), skipOffstage: false),
    );
    expect(paint.chart!.renders, greaterThan(0));
    await _openTab(tester, 'stress');
    final painted = paint.chart!.renders;
    await _frames(tester, 10);
    expect(paint.chart!.renders, painted);

    // Back on the Stress tab, the loop runs again.
    final resumed = _renders(tester);
    await _frames(tester, 5);
    expect(_renders(tester), greaterThan(resumed));
    await tester.tap(find.byKey(const ValueKey('stress.start')));
    await _frames(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('events: a mouse exit clears the crosshair', (tester) async {
    await _pumpDemo(tester);
    await _openTab(tester, 'events');
    final host = find.descendant(
      of: find.byKey(const ValueKey('events.host')),
      matching: find.byType(ChartHost),
    );
    final center = tester.getCenter(host);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: center);
    await mouse.moveTo(center + const Offset(10, 5));
    await _frames(tester, 3);
    final readout = find.byKey(const ValueKey('events.readout'));
    expect(
      find.descendant(
        of: readout,
        matching: find.textContaining('crosshair ('),
      ),
      findsOneWidget,
    );

    // The host sends mouseout with the finite exit position.
    await mouse.moveTo(tester.getTopLeft(host) - const Offset(0, 20));
    await _frames(tester, 3);
    final log = find.byKey(const ValueKey('events.log'));
    expect(
      find.descendant(of: log, matching: find.textContaining('mouseout')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: readout,
        matching: find.textContaining('crosshair none'),
      ),
      findsOneWidget,
    );
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });

  testWidgets('events: a touch row of the log is one line on a 360 dp phone', (
    tester,
  ) async {
    await _pumpDemo(tester, size: const Size(360, 740));
    await _openTab(tester, 'events');
    final host = find.descendant(
      of: find.byKey(const ValueKey('events.host')),
      matching: find.byType(ChartHost),
    );
    await tester.tapAt(tester.getCenter(host));
    await _frames(tester, 3);
    final row = find.descendant(
      of: find.byKey(const ValueKey('events.log')),
      matching: find.textContaining('touches=1'),
    );
    expect(row, findsWidgets);
    for (final element in row.evaluate()) {
      final paragraph = element.renderObject! as RenderParagraph;
      // One line of text: a second line would be clipped by the 20 px row.
      expect(paragraph.textSize.height, lessThanOrEqualTo(20));
      // The touch count comes first, so that a narrow row keeps it.
      expect(paragraph.text.toPlainText(), startsWith('touches=1'));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('stress: autoStart and onStats drive the tab', (tester) async {
    final stats = <StressStats>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StressDemo(
            initialN: 500,
            initialM: 10,
            autoStart: true,
            onStats: stats.add,
          ),
        ),
      ),
    );
    await _frames(tester, 10);
    expect(_renders(tester), greaterThan(0));
    // Stopping publishes the figures.
    await tester.tap(find.byKey(const ValueKey('stress.start')));
    await _frames(tester);
    expect(stats, isNotEmpty);
    expect(stats.last.points, 500);
    expect(stats.last.labels, 10);
    expect(stats.last.frames, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}

/// The count of draws of the stress chart, also while its tab is hidden.
int _renders(WidgetTester tester) => tester
    .state<DemoCanvasState>(
      find.byKey(const ValueKey('stress.host'), skipOffstage: false),
    )
    .chart!
    .renders;

/// Scrolls the tab of [key] into view and taps it.
///
/// The tab bar does not scroll: each tab is in view on a phone. The scroll
/// into view is a guard for a smaller test view.
Future<void> _tapTab(WidgetTester tester, String key) async {
  final tab = find.byKey(ValueKey('phase3.tab.$key'));
  await tester.ensureVisible(tab);
  await tester.pump();
  await tester.tap(tab);
}

/// The color of the pixel at [x], [y] of [source], as `0xAARRGGBB`.
Future<int> _pixel(UiImageSource source, int x, int y) async {
  final data = (await source.image.toByteData())!;
  final i = (y * source.image.width + x) * 4;
  final rgba = data.buffer.asUint8List(i, 4);
  return rgba[3] << 24 | rgba[0] << 16 | rgba[1] << 8 | rgba[2];
}
