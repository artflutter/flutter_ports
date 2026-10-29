import 'dart:math' as math;

import 'package:chartjs_gallery/canvas_host_demo.dart';
import 'package:chartjs_gallery/demo/elements_demo.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
// Not public: the typed element options of Chart.js ADR 0018.
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show ArcOptions, BarOptions, LineOptions, PointOptions;
// Not public: ChartHost, the internal host of ChartView (a white-box test).
import 'package:flutter_chartjs_port/src/platform/chart_host.dart'
    show ChartHost;
import 'package:flutter_test/flutter_test.dart';

/// A Pixel 8a: 412 x 915 logical pixels at DPR 2.625, as in
/// canvas_host_demo_test.dart.
const Size _phone = Size(412, 915);
const double _phoneDpr = 2.625;

/// Pumps a few frames: the demo charts start after the first frame, and the
/// throttled platform proxies call back in the next frame. The Canvas tab
/// has a running animation (the line dash), so pumpAndSettle would not
/// return.
Future<void> _frames(WidgetTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Pumps the demo page at [size] logical pixels and [dpr], and opens the
/// Elements tab.
Future<void> _pumpElements(
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
  final tab = find.byKey(const ValueKey('phase3.tab.elements'));
  await tester.ensureVisible(tab);
  await tester.pump();
  await tester.tap(tab);
  await _frames(tester, 25);
}

ElementsDemoState _state(WidgetTester tester) =>
    tester.state<ElementsDemoState>(find.byType(ElementsDemo));

/// The chart host of the Elements tab.
Finder get _host => find.descendant(
  of: find.byKey(const ValueKey('elements.host')),
  matching: find.byType(ChartHost),
);

/// The global position of the chart position [point].
Offset _global(WidgetTester tester, ({double x, double y}) point) =>
    tester.getTopLeft(_host) + Offset(point.x, point.y);

/// The center point of [element], from its `getCenterPoint`.
({double x, double y}) _center(Object element) {
  final point = switch (element) {
    final BarElement bar => bar.getCenterPoint(),
    final PointElement point => point.getCenterPoint(),
    final ArcElement arc => arc.getCenterPoint(),
    _ => throw ArgumentError.value(element),
  };
  return (x: point.x, y: point.y);
}

/// Checks that the readout and the state name [label].
void _expectHit(WidgetTester tester, String label) {
  expect(_state(tester).hitLabel, label);
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('elements.hit')),
      matching: find.textContaining('hit $label'),
    ),
    findsOneWidget,
  );
}

/// The text of the `test` row of the readout.
String _testRow(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('elements.hit')),
        matching: find.byType(Text),
      ),
    )
    .map((text) => text.textSpan?.toPlainText() ?? text.data ?? '')
    .firstWhere((text) => text.startsWith('test '));

/// Scrolls the widget of [key] into view and taps it.
Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _frames(tester);
}

/// Sets the slider of [key] to [value] through its callback.
Future<void> _slide(WidgetTester tester, String key, double value) async {
  tester.widget<Slider>(find.byKey(ValueKey(key))).onChanged!(value);
  await _frames(tester);
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('elements: the tab opens and draws the four element types', (
    tester,
  ) async {
    await _pumpElements(tester);
    final state = _state(tester);
    final chart = state.chart!;
    expect(chart.renders, greaterThan(0));
    expect(state.bars, hasLength(6));
    expect(state.points, hasLength(6));
    expect(state.arcs, hasLength(5));
    final line = state.line!;
    for (var i = 0; i < state.points.length; i++) {
      expect(identical(line.points[i], state.points[i]), isTrue);
    }

    // The options are the class defaults plus the colors and the controls.
    expect(state.bars.first.options!['borderSkipped'], 'start');
    expect(state.bars.first.borderSkipped, {'bottom': true});
    expect(state.points.first.options!['hitRadius'], 1);
    expect(state.points.first.options!['pointStyle'], 'triangle');
    expect(line.options!['capBezierPoints'], isTrue);
    expect(state.arcs.first.options!['borderColor'], '#fff');
    // Each element has typed options (Chart.js ADR 0018).
    expect(state.bars.first.options, isA<BarOptions>());
    expect(state.points.first.options, isA<PointOptions>());
    expect(line.options, isA<LineOptions>());
    expect(state.arcs.first.options, isA<ArcOptions>());

    // The layout fits the phone width: each element is in the chart.
    final size = tester.getSize(_host);
    for (final element in [...state.bars, ...state.points, ...state.arcs]) {
      final center = _center(element);
      expect(center.x, inInclusiveRange(0, size.width));
      expect(center.y, inInclusiveRange(0, size.height));
    }

    // controller.doughnut.js:216-217: the radius leaves room for the border
    // (2), the offset (0) and the spacing (0), but not for the hover offset:
    // the resolved arc options have no hoverOffset key. The doughnut area is
    // below the bars (split 230), inside the pad of 12 and the caption of
    // 18, with a padding of 16 on each side.
    expect(size.height, 460);
    final side = math.min(
      size.width - 2 * 12 - 2 * 16,
      460 - (230 + 12) - 18 - 2 * 16.0,
    );
    expect(state.arcs.first.outerRadius, (side - 2) / 2);
    expect(state.arcs.first.innerRadius, state.arcs.first.outerRadius / 2);
    final canvas = tester.widget<ChartHost>(_host).canvas;
    expect(canvas.width, (size.width * _phoneDpr).truncate());
    expect(canvas.getContext2d().isEmpty, isFalse);
    _expectHit(tester, 'none');

    // No change, no draw.
    final renders = chart.renders;
    await _frames(tester, 5);
    expect(chart.renders, renders);
    expect(tester.takeException(), isNull);
  });

  testWidgets('elements: each control changes the element options', (
    tester,
  ) async {
    await _pumpElements(tester);
    final state = _state(tester);
    final chart = state.chart!;

    Future<void> expectDraw(Future<void> Function() change) async {
      final renders = chart.renders;
      await change();
      expect(chart.renders, greaterThan(renders));
    }

    await expectDraw(() => _slide(tester, 'elements.borderWidth', 5));
    expect(state.bars.first.options!['borderWidth'], 5);
    expect(state.points.first.options!['borderWidth'], 5);
    expect(state.points.first.options!['hoverBorderWidth'], 6);
    expect(state.line!.options!['borderWidth'], 5);
    expect(state.arcs.first.options!['borderWidth'], 5);

    final sliders = <(String, double, Map<String, Object?>? Function())>[
      ('radius', 10, () => state.points.first.options),
      ('hoverRadius', 14, () => state.points.last.options),
      ('rotation', 45, () => state.points.first.options),
      ('tension', 0, () => state.line!.options),
      ('borderRadius', 12, () => state.bars.first.options),
      ('spacing', 8, () => state.arcs.first.options),
      ('offset', 10, () => state.arcs.last.options),
    ];
    for (final (name, value, options) in sliders) {
      await expectDraw(() => _slide(tester, 'elements.$name', value));
      expect(options()![name], value, reason: name);
    }
    expect(state.arcs.first.options!['hoverOffset'], 26);

    final choices = <(String, Object, Map<String, Object?>? Function())>[
      ('pointStyle', 'star', () => state.points.first.options),
      ('stepped', 'middle', () => state.line!.options),
      ('stepped', false, () => state.line!.options),
      ('stepped', 'before', () => state.line!.options),
      ('borderAlign', 'inner', () => state.arcs.first.options),
      ('borderJoinStyle', 'round', () => state.arcs.first.options),
      ('borderJoinStyle', undefined, () => state.arcs.first.options),
    ];
    for (final (name, value, options) in choices) {
      final text = value is Undefined ? 'undefined' : '$value';
      final key = 'elements.$name.$text';
      await expectDraw(() => _tapKey(tester, key));
      expect(options()![name], value, reason: key);
      expect(
        tester.widget<ChoiceChip>(find.byKey(ValueKey(key))).selected,
        isTrue,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('elements: the hit readout names the element under the mouse', (
    tester,
  ) async {
    await _pumpElements(tester);
    final state = _state(tester);
    final chart = state.chart!;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(
      location: tester.getTopLeft(_host) - const Offset(0, 20),
    );

    // A bar: its center is far from the point above it.
    await mouse.moveTo(_global(tester, _center(state.bars[1])));
    await _frames(tester, 3);
    _expectHit(tester, 'bar 1');
    expect(_testRow(tester), startsWith('test BarElement.inRange'));
    final bar = state.bars[1];
    expect(bar.active, isTrue);
    expect(
      bar.options!['borderColor'],
      bar.options!['hoverBorderColor'],
    );
    expect(bar.options!['borderColor'], isNot('#36A2EB'));
    expect(state.bars[0].options!['borderColor'], '#36A2EB');

    // A move inside the same bar does not draw again.
    final renders = chart.renders;
    await mouse.moveTo(_global(tester, _center(bar)) + const Offset(2, 3));
    await _frames(tester, 3);
    _expectHit(tester, 'bar 1');
    expect(chart.renders, renders);

    // A point: it draws with its hover radius and border width.
    await mouse.moveTo(_global(tester, _center(state.points[2])));
    await _frames(tester, 3);
    _expectHit(tester, 'point 2');
    expect(_testRow(tester), startsWith('test PointElement.inRange'));
    expect(chart.renders, greaterThan(renders));
    expect(bar.active, isFalse);
    expect(bar.options!['borderColor'], '#36A2EB');
    final point = state.points[2];
    expect(point.active, isTrue);
    expect(point.options!['radius'], point.options!['hoverRadius']);
    expect(
      point.options!['borderWidth'],
      point.options!['hoverBorderWidth'],
    );
    expect(state.points[1].options!['radius'], 6);

    // An arc: it draws with its hover offset.
    await mouse.moveTo(_global(tester, _center(state.arcs[3])));
    await _frames(tester, 3);
    _expectHit(tester, 'arc 3');
    expect(_testRow(tester), startsWith('test ArcElement.inRange'));
    expect(state.arcs[3].options!['offset'], 16);
    expect(state.arcs[2].options!['offset'], 0);

    // An empty place of the chart: the top right corner.
    final size = tester.getSize(_host);
    await mouse.moveTo(_global(tester, (x: size.width - 4, y: 4)));
    await _frames(tester, 3);
    _expectHit(tester, 'none');
    expect(state.arcs[3].active, isFalse);

    // mouseout: no element is active.
    await mouse.moveTo(_global(tester, _center(state.arcs[0])));
    await _frames(tester, 3);
    _expectHit(tester, 'arc 0');
    await mouse.moveTo(tester.getTopLeft(_host) - const Offset(0, 20));
    await _frames(tester, 3);
    _expectHit(tester, 'none');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('elements.hit')),
        matching: find.textContaining('event mouseout'),
      ),
      findsOneWidget,
    );
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });

  testWidgets('elements: a touch hits an element and a control replays it', (
    tester,
  ) async {
    await _pumpElements(tester);
    final state = _state(tester);

    // touchstart and click.
    await tester.tapAt(_global(tester, _center(state.arcs[1])));
    await _frames(tester, 3);
    _expectHit(tester, 'arc 1');
    // 12 px below the point 4, in the bar 4: the point radius is 6.
    final point = _center(state.points[4]);
    await tester.tapAt(_global(tester, (x: point.x, y: point.y + 12)));
    await _frames(tester, 3);
    _expectHit(tester, 'bar 4');
    expect(state.bars[4].active, isTrue);

    // The hover radius of a point that is not active changes nothing.
    await _slide(tester, 'elements.hoverRadius', 20);
    _expectHit(tester, 'bar 4');

    // A radius of 16 puts the position in the point 4. The control tests the
    // last position again, as chart.update() replays the last event.
    await _slide(tester, 'elements.radius', 16);
    _expectHit(tester, 'point 4');
    expect(state.bars[4].active, isFalse);
    expect(state.points[4].active, isTrue);
    expect(state.points[4].options!['radius'], 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('elements: the wide layout puts the doughnut to the right', (
    tester,
  ) async {
    await _pumpElements(tester, size: const Size(1280, 900), dpr: 1);
    final state = _state(tester);
    final size = tester.getSize(_host);
    expect(size.height, 320);
    final lastBar = _center(state.bars.last);
    for (final arc in state.arcs) {
      expect(_center(arc).x, greaterThan(lastBar.x));
    }
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(
      location: tester.getTopLeft(_host) - const Offset(0, 20),
    );
    await mouse.moveTo(_global(tester, _center(state.points[0])));
    await _frames(tester, 3);
    _expectHit(tester, 'point 0');
    await mouse.moveTo(_global(tester, _center(state.arcs[4])));
    await _frames(tester, 3);
    _expectHit(tester, 'arc 4');

    // The active arc moves out by its hover offset (16). The padding of the
    // doughnut area keeps it in the canvas: the circle of its outer border
    // edge, moved by the offset, is inside the chart.
    final arc = state.arcs[4];
    final options = arc.options!;
    expect(options['offset'], 16);
    final reach =
        arc.outerRadius +
        (options['offset']! as num) +
        (options['borderWidth']! as num) / 2;
    expect(arc.y - reach, greaterThanOrEqualTo(0));
    expect(arc.y + reach, lessThanOrEqualTo(size.height));
    expect(arc.x + reach, lessThanOrEqualTo(size.width));
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });
}
