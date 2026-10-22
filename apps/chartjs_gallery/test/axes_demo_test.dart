// Original code, not ported from Chart.js: tests of the gallery Axes tab.

import 'package:chartjs_gallery/canvas_host_demo.dart';
import 'package:chartjs_gallery/demo/axes_demo.dart';
import 'package:chartjs_gallery/demo/demo_common.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/elements/index.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/platform/platform.flutter.dart';
import 'package:flutter_chartjs_port/src/scales/index.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tall desktop window.
const Size _desktop = Size(1200, 1600);

/// A Pixel 8a: 412 x 915 logical pixels at DPR 2.625.
const Size _phone = Size(412, 915);
const double _phoneDpr = 2.625;

/// Pumps [count] frames of 16 ms. The demo page has a running animation
/// (the line dash of the Canvas tab), so pumpAndSettle would not return.
Future<void> _frames(WidgetTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Pumps the demo page in a desktop window (or at [size] and [dpr]) and
/// opens the Axes tab.
Future<AxesDemoState> _pumpAxes(
  WidgetTester tester, {
  Size size = _desktop,
  double dpr = 1,
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
  final tab = find.byKey(const ValueKey('phase3.tab.axes'));
  await tester.ensureVisible(tab);
  await tester.pump();
  await tester.tap(tab);
  await _frames(tester, 25);
  return tester.state<AxesDemoState>(find.byType(AxesDemo));
}

/// The chart host of the Axes tab.
Finder get _host => find.descendant(
  of: find.byKey(const ValueKey('axes.host')),
  matching: find.byType(ChartHost),
);

/// Scrolls the widget of [key] into view and taps it.
Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _frames(tester);
}

/// The scale [id] of [chart].
Scale _scale(Chart chart, String id) => chart.scales[id]!;

/// The point [index] of the dataset [datasetIndex].
PointElement _point(Chart chart, int datasetIndex, int index) =>
    chart.getDatasetMeta(datasetIndex.toDouble()).data[index] as PointElement;

/// The value of the readout row [name].
String _row(AxesDemoState state, String name) =>
    state.readoutRows.firstWhere((row) => row.$1 == name).$2;

/// The option [key] of the ticks of the scale [id].
Object? _tickOption(Chart chart, String id, String key) =>
    jsGet(_scale(chart, id).options['ticks'], key);

/// Whether the segment of [key] is on: the selected segment of a
/// [SegmentChoice], or an option of a [SegmentToggles] that is on.
bool _selected(WidgetTester tester, String key) {
  final control = tester.widget(
    find.ancestor(
      of: find.byKey(ValueKey(key)),
      matching: find.byWidgetPredicate(
        (w) => w is SegmentChoice || w is SegmentToggles,
      ),
    ),
  );
  return switch (control) {
    final SegmentToggles toggles => toggles.isSelected(key),
    final SegmentChoice<Object?> choice => choice.isSelected(key),
    _ => throw StateError('No segmented control holds $key.'),
  };
}

/// The widgets of the Axes tab that Chart.js ADR 0031 section 10.2 does
/// not allow: chips, sliders, menus and horizontal scrollables.
Finder get _forbidden => find.descendant(
  of: find.byType(AxesDemo),
  matching: find.byWidgetPredicate(
    (w) =>
        w is ChoiceChip ||
        w is FilterChip ||
        w is ToggleChips ||
        w is SliderControl ||
        w is Slider ||
        w is PopupMenuButton ||
        w is DropdownButton ||
        (w is Scrollable &&
            axisDirectionToAxis(w.axisDirection) == Axis.horizontal),
  ),
);

/// Expects each point of [chart] at the pixels of the raw parsed values on
/// the scales x and y.
void _expectOnScales(Chart chart) {
  final x = _scale(chart, 'x');
  final y = _scale(chart, 'y');
  for (var d = 0; d < 2; d++) {
    final meta = chart.getDatasetMeta(d.toDouble());
    expect(identical(meta.iScale, x), isTrue);
    expect(identical(meta.vScale, y), isTrue);
    for (var i = 0; i < meta.data.length; i++) {
      final point = meta.data[i] as PointElement;
      final parsed = meta.controller!.getParsed(i.toDouble());
      expect(point.x, x.getPixelForValue(jsGet(parsed, 'x'), i.toDouble()));
      expect(point.y, y.getPixelForValue(jsGet(parsed, 'y'), i.toDouble()));
    }
  }
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('axes: the tab shows a real Chart on linear scales', (
    tester,
  ) async {
    final state = await _pumpAxes(tester);
    final chart = state.chart!;
    expect(chart.platform, isA<FlutterPlatform>());
    expect(chart.attached, isTrue);
    expect(chart.config.type, 'line');
    expect(chart.width, tester.getSize(_host).width);
    expect(chart.height, 360);
    expect(_scale(chart, 'x'), isA<LinearScale>());
    expect(_scale(chart, 'y'), isA<LinearScale>());
    expect(_scale(chart, 'x').options['position'], 'bottom');
    expect(_scale(chart, 'y').options['position'], 'left');
    for (var d = 0; d < 2; d++) {
      expect(chart.getDatasetMeta(d.toDouble()).data, hasLength(12));
    }
    // parsing: true gives the parsed items of the scales.
    final parsed = chart.getDatasetMeta(0).controller!.getParsed(3);
    expect(jsGet(parsed, 'x'), 4);
    expect(jsGet(parsed, 'y'), state.dataOf(0)[3]['y']);
    _expectOnScales(chart);
    expect(
      tester.widget<ChartHost>(_host).canvas.getContext2d().isEmpty,
      isFalse,
    );

    // The readout.
    final x = _scale(chart, 'x');
    final area = chart.chartArea!;
    expect(
      _row(state, 'x'),
      'linear · 0 to 12 · ${x.ticks!.length} ticks · rotation 0.0',
    );
    expect(_row(state, 'y'), startsWith('linear · '));
    expect(
      _row(state, 'chartArea'),
      'left ${area.left.toStringAsFixed(1)} · '
      'top ${area.top.toStringAsFixed(1)} · '
      'right ${area.right.toStringAsFixed(1)} · '
      'bottom ${area.bottom.toStringAsFixed(1)}',
    );
    expect(_row(state, 'pointer x'), '-');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('axes.readout')),
        matching: find.textContaining('linear · 0 to 12'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: each control has its key', (tester) async {
    await _pumpAxes(tester);
    final keys = [
      'axes.host',
      'axes.readout',
      for (final type in axesDemoXTypes) 'axes.x.type.$type',
      for (final type in axesDemoYTypes) 'axes.y.type.$type',
      for (final count in axesDemoCounts) 'axes.count.$count',
      'axes.x.position.bottom',
      'axes.x.position.top',
      'axes.y.position.left',
      'axes.y.position.right',
      'axes.help',
      'axes.ticks.autoSkip',
      for (final v in ['0', '30', '50', '90']) 'axes.ticks.maxRotation.$v',
      for (final v in ['0', '30', '45', '90']) 'axes.ticks.minRotation.$v',
      for (final v in ['0', '5', '10', '20']) 'axes.ticks.maxTicksLimit.$v',
      for (final v in ['8', '12', '16', '24']) 'axes.ticks.font.size.$v',
      for (final align in axesDemoAligns) 'axes.ticks.align.$align',
      'axes.grid.display',
      'axes.grid.offset',
      'axes.border.display',
      'axes.title.display',
      'axes.reverse',
      'axes.beginAtZero',
      for (final bounds in axesDemoBounds) 'axes.bounds.$bounds',
      for (final unit in axesDemoTimeUnits) 'axes.time.unit.$unit',
      for (final locale in axesDemoLocales) 'axes.locale.$locale',
      'axes.data.randomize',
      'axes.data.add',
      'axes.data.remove',
    ];
    for (final key in keys) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    // The texts of the time unit segments: `mon` fits in the 34.4 px of a
    // unit segment at 360 x 640 in Roboto. The tooltip gives the name.
    for (final (unit, text) in [
      ('auto', 'auto'),
      ('day', 'day'),
      ('week', 'week'),
      ('month', 'mon'),
      ('year', 'year'),
    ]) {
      final key = ValueKey('axes.time.unit.$unit');
      expect(tester.widget<Text>(find.byKey(key)).data, text, reason: unit);
    }
    for (final key in [
      'axes.x.type.linear',
      'axes.y.type.linear',
      'axes.count.12',
      'axes.ticks.align.center',
      'axes.bounds.auto',
      'axes.time.unit.auto',
      'axes.locale.en-US',
      'axes.x.position.bottom',
      'axes.y.position.left',
      'axes.ticks.maxRotation.50',
      'axes.ticks.minRotation.0',
      'axes.ticks.maxTicksLimit.0',
      'axes.ticks.font.size.12',
      'axes.ticks.autoSkip',
      'axes.grid.display',
      'axes.border.display',
    ]) {
      expect(_selected(tester, key), isTrue, reason: key);
    }
    for (final key in [
      'axes.reverse',
      'axes.beginAtZero',
      'axes.grid.offset',
      'axes.title.display',
      'axes.data.randomize',
      'axes.data.add',
      'axes.data.remove',
    ]) {
      expect(_selected(tester, key), isFalse, reason: key);
    }
  });

  testWidgets('axes: x, y and N are above the chart, the other parameters '
      'after the readout (Chart.js ADR 0031, section 10.7)', (tester) async {
    await _pumpAxes(tester);
    expect(_forbidden, findsNothing);
    expect(
      find.descendant(
        of: find.byType(AxesDemo),
        matching: find.byType(DemoCard),
      ),
      findsOneWidget,
    );
    double top(String key) => tester.getRect(find.byKey(ValueKey(key))).top;
    double bottom(String key) =>
        tester.getRect(find.byKey(ValueKey(key))).bottom;
    // One line each, from the top.
    final above = ['axes.x.type.linear', 'axes.y.type.linear', 'axes.count.12'];
    final after = [
      'axes.x.position.bottom',
      'axes.y.position.left',
      'axes.bounds.auto',
      'axes.time.unit.auto',
      'axes.locale.en-US',
      'axes.ticks.align.center',
      'axes.reverse',
      'axes.ticks.maxRotation.50',
      'axes.ticks.minRotation.0',
      'axes.ticks.maxTicksLimit.0',
      'axes.ticks.font.size.12',
    ];
    var last = 0.0;
    for (final key in above) {
      expect(top(key), greaterThan(last), reason: key);
      last = bottom(key);
    }
    expect(top('axes.host'), greaterThan(last));
    expect(top('axes.readout'), greaterThanOrEqualTo(bottom('axes.host')));
    last = bottom('axes.readout');
    for (final key in after) {
      expect(top(key), greaterThan(last), reason: key);
      last = bottom(key);
    }
    expect(top('axes.help'), greaterThan(last));
    // The toggles and the commands are on one line.
    for (final key in [
      'axes.beginAtZero',
      'axes.ticks.autoSkip',
      'axes.grid.display',
      'axes.grid.offset',
      'axes.border.display',
      'axes.title.display',
      'axes.data.randomize',
      'axes.data.add',
      'axes.data.remove',
    ]) {
      expect(
        tester.getCenter(find.byKey(ValueKey(key))).dy,
        tester.getCenter(find.byKey(const ValueKey('axes.reverse'))).dy,
        reason: key,
      );
    }
    for (final button in tester.widgetList<SegmentedButton<Object?>>(
      find.descendant(
        of: find.byType(AxesDemo),
        matching: find.byWidgetPredicate((w) => w is SegmentedButton),
      ),
    )) {
      expect(button.expandedInsets, EdgeInsets.zero);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: the chart is in view at 412 x 915 '
      '(Chart.js ADR 0031, section 10.4)', (tester) async {
    final state = await _pumpAxes(tester, size: _phone, dpr: _phoneDpr);
    final page = find
        .descendant(
          of: find.byType(AxesDemo),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        )
        .first;
    expect(tester.state<ScrollableState>(page).position.pixels, 0);
    final view = Offset.zero & _phone;
    final host = tester.getRect(find.byKey(const ValueKey('axes.host')));
    expect(host.height, 300);
    expect(view.contains(host.topLeft), isTrue, reason: '$host');
    expect(
      view.contains(host.bottomRight - const Offset(0.01, 0.01)),
      isTrue,
      reason: '$host',
    );
    expect(state.chart!.height, 300);
    expect(_forbidden, findsNothing);
    // A tap on a command after the readout needs a scroll. The segment
    // runs the command and does not stay on.
    await _tap(tester, 'axes.data.add');
    expect(state.dataOf(0), hasLength(13));
    expect(_selected(tester, 'axes.data.add'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: the type segments give new scales', (tester) async {
    final state = await _pumpAxes(tester);
    final chart = state.chart!;
    final linear = _scale(chart, 'x');

    await _tap(tester, 'axes.x.type.category');
    expect(_selected(tester, 'axes.x.type.category'), isTrue);
    final category = _scale(chart, 'x');
    expect(category, isA<CategoryScale>());
    expect(identical(category, linear), isFalse);
    expect(category.getLabels(), [for (var i = 1; i <= 12; i++) 'P$i']);
    // The category parse gives the index of the label.
    expect(state.dataOf(0)[3]['x'], 'P4');
    expect(jsGet(chart.getDatasetMeta(0).controller!.getParsed(3), 'x'), 3);
    expect(category.ticks, hasLength(12));
    expect(_row(state, 'x'), startsWith('category · P1 to P12 · 12 ticks'));
    _expectOnScales(chart);

    await _tap(tester, 'axes.x.type.time');
    final time = _scale(chart, 'x');
    expect(time, isA<TimeScale>());
    // The default date adapter parses the ISO dates (Chart.js ADR 0024).
    expect(state.dataOf(0)[3]['x'], '2024-01-04');
    expect(
      jsGet(chart.getDatasetMeta(0).controller!.getParsed(3), 'x'),
      DateTime(2024, 1, 4).millisecondsSinceEpoch,
    );
    expect(time.getLabels(), isEmpty);
    expect(_row(state, 'x'), startsWith('time · Jan 1, 2024'));
    _expectOnScales(chart);

    await _tap(tester, 'axes.x.type.logarithmic');
    expect(_scale(chart, 'x'), isA<LogarithmicScale>());
    expect(_scale(chart, 'x').min, 1);
    _expectOnScales(chart);

    await _tap(tester, 'axes.y.type.logarithmic');
    final y = _scale(chart, 'y');
    expect(y, isA<LogarithmicScale>());
    for (final item in state.dataOf(1)) {
      expect(item['y'], inInclusiveRange(1, 10000));
    }
    expect(_row(state, 'y'), startsWith('logarithmic · '));
    _expectOnScales(chart);
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: the position, reverse, beginAtZero and bounds', (
    tester,
  ) async {
    final state = await _pumpAxes(tester);
    final chart = state.chart!;
    final area = chart.chartArea!;
    final top = area.top;
    final left = area.left;

    await _tap(tester, 'axes.x.position.top');
    expect(_scale(chart, 'x').options['position'], 'top');
    expect(_scale(chart, 'x').bottom, lessThanOrEqualTo(chart.chartArea!.top));
    expect(chart.chartArea!.top, greaterThan(top));
    await _tap(tester, 'axes.y.position.right');
    expect(_scale(chart, 'y').options['position'], 'right');
    expect(chart.chartArea!.left, lessThan(left));
    expect(
      _scale(chart, 'y').left,
      greaterThanOrEqualTo(chart.chartArea!.right),
    );

    final x = _scale(chart, 'x');
    expect(x.getPixelForValue(1.0), lessThan(x.getPixelForValue(12.0)));
    await _tap(tester, 'axes.reverse');
    expect(x.options['reverse'], true);
    expect(x.getPixelForValue(1.0), greaterThan(x.getPixelForValue(12.0)));
    _expectOnScales(chart);
    await _tap(tester, 'axes.reverse');

    // The y values are 10 to 100: beginAtZero gives a min of 0.
    final y = _scale(chart, 'y');
    expect(y.min, greaterThan(0));
    await _tap(tester, 'axes.beginAtZero');
    expect(y.options['beginAtZero'], true);
    expect(y.min, 0);
    await _tap(tester, 'axes.beginAtZero');
    expect(y.min, greaterThan(0));

    // A linear scale has the bounds ticks by default: 0 to 12 for the x
    // values 1 to 12. The bounds data give 1 to 12.
    expect(x.min, 0);
    await _tap(tester, 'axes.bounds.data');
    expect(x.options['bounds'], 'data');
    expect(x.min, 1);
    expect(x.max, 12);
    await _tap(tester, 'axes.bounds.auto');
    expect(x.options['bounds'], 'ticks');
    expect(x.min, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: the tick controls', (tester) async {
    final state = await _pumpAxes(tester);
    final chart = state.chart!;
    await _tap(tester, 'axes.x.type.category');
    await _tap(tester, 'axes.count.1000');
    expect(chart.getDatasetMeta(0).data, hasLength(1000));
    final x = _scale(chart, 'x');
    final skipped = x.ticks!.length;
    expect(skipped, lessThan(1000));
    expect(jsToNumber(x.labelRotation), greaterThan(0));

    // Without the auto skip, the axis has a tick for each label.
    await _tap(tester, 'axes.ticks.autoSkip');
    expect(_tickOption(chart, 'x', 'autoSkip'), false);
    expect(x.ticks, hasLength(1000));
    await _tap(tester, 'axes.ticks.autoSkip');
    expect(x.ticks, hasLength(skipped));

    // maxRotation 0 keeps the labels flat.
    await _tap(tester, 'axes.ticks.maxRotation.0');
    expect(_selected(tester, 'axes.ticks.maxRotation.0'), isTrue);
    expect(_selected(tester, 'axes.ticks.maxRotation.50'), isFalse);
    expect(_tickOption(chart, 'x', 'maxRotation'), 0);
    expect(jsToNumber(x.labelRotation), 0);
    // minRotation 90 turns them up.
    await _tap(tester, 'axes.ticks.minRotation.90');
    expect(_tickOption(chart, 'x', 'minRotation'), 90);
    expect(jsToNumber(x.labelRotation), 90);
    expect(_row(state, 'x'), endsWith('rotation 90.0'));
    // minRotation 45 with maxRotation 0: minRotation >= maxRotation gives
    // the rotation minRotation (core.scale.js:595-596).
    await _tap(tester, 'axes.ticks.minRotation.45');
    expect(_tickOption(chart, 'x', 'minRotation'), 45);
    expect(jsToNumber(x.labelRotation), 45);
    await _tap(tester, 'axes.ticks.minRotation.90');

    // maxTicksLimit 20 limits the auto skip. The value 0 writes no option.
    await _tap(tester, 'axes.ticks.maxTicksLimit.20');
    expect(_tickOption(chart, 'x', 'maxTicksLimit'), 20);
    expect(x.ticks!.length, lessThanOrEqualTo(20));
    await _tap(tester, 'axes.ticks.maxTicksLimit.5');
    expect(_tickOption(chart, 'x', 'maxTicksLimit'), 5);
    expect(x.ticks!.length, lessThanOrEqualTo(5));
    await _tap(tester, 'axes.ticks.maxTicksLimit.0');
    expect(_tickOption(chart, 'x', 'maxTicksLimit'), same(undefined));
    // The flat labels of 90 degrees leave space for more ticks.
    expect(x.ticks!.length, greaterThan(30));

    await _tap(tester, 'axes.ticks.font.size.24');
    expect(jsGet(_tickOption(chart, 'y', 'font'), 'size'), 24);

    await _tap(tester, 'axes.ticks.align.start');
    expect(_selected(tester, 'axes.ticks.align.start'), isTrue);
    expect(_tickOption(chart, 'x', 'align'), 'start');
    expect(_tickOption(chart, 'y', 'align'), 'start');
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: the grid, border and title toggles', (tester) async {
    final state = await _pumpAxes(tester);
    final chart = state.chart!;
    final x = _scale(chart, 'x');
    final height = chart.chartArea!.height;

    await _tap(tester, 'axes.grid.display');
    expect(jsGet(x.options['grid'], 'display'), false);
    await _tap(tester, 'axes.grid.offset');
    expect(jsGet(x.options['grid'], 'offset'), true);
    await _tap(tester, 'axes.border.display');
    expect(jsGet(x.options['border'], 'display'), false);

    // A title takes space from the chart area.
    await _tap(tester, 'axes.title.display');
    expect(jsGet(x.options['title'], 'display'), true);
    expect(jsGet(x.options['title'], 'text'), 'x: linear');
    expect(jsGet(_scale(chart, 'y').options['title'], 'text'), 'y: linear');
    expect(chart.chartArea!.height, lessThan(height));
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: the time unit and the locale', (tester) async {
    final state = await _pumpAxes(tester);
    final chart = state.chart!;

    // The locale formats the numbers of the linear ticks.
    await _tap(tester, 'axes.count.1000');
    final labels = [for (final tick in _scale(chart, 'x').ticks!) tick.label];
    expect(labels, contains('1,000'));
    await _tap(tester, 'axes.locale.de-DE');
    expect(chart.options['locale'], 'de-DE');
    expect(
      [for (final tick in _scale(chart, 'x').ticks!) tick.label],
      contains('1.000'),
    );

    // 1000 days from 2024-01-01. The default date adapter formats the
    // ticks with the display format of the unit.
    await _tap(tester, 'axes.x.type.time');
    await _tap(tester, 'axes.time.unit.day');
    final time = _scale(chart, 'x');
    expect(jsGet(time.options['time'], 'unit'), 'day');
    expect(time.ticks!.first.label, 'Jan 1');
    await _tap(tester, 'axes.time.unit.month');
    expect(jsGet(time.options['time'], 'unit'), 'month');
    expect(time.ticks!.first.label, 'Jan 2024');
    await _tap(tester, 'axes.time.unit.year');
    expect(
      [for (final tick in _scale(chart, 'x').ticks!) tick.label],
      ['2024', '2025', '2026'],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: randomize, add and remove change the data', (
    tester,
  ) async {
    final state = await _pumpAxes(tester);
    final chart = state.chart!;
    await _tap(tester, 'axes.x.type.category');
    final y = state.dataOf(0).first['y'];
    await _tap(tester, 'axes.data.randomize');
    expect(state.dataOf(0).first['y'], isNot(y));
    _expectOnScales(chart);

    await _tap(tester, 'axes.data.add');
    expect(chart.getDatasetMeta(0).data, hasLength(13));
    expect(chart.getDatasetMeta(1).data, hasLength(13));
    expect(_scale(chart, 'x').getLabels(), hasLength(13));
    expect(_scale(chart, 'x').getLabels().last, 'P13');
    expect(_selected(tester, 'axes.count.12'), isFalse);
    _expectOnScales(chart);

    await _tap(tester, 'axes.data.remove');
    await _tap(tester, 'axes.data.remove');
    expect(chart.getDatasetMeta(0).data, hasLength(11));
    expect(_scale(chart, 'x').getLabels(), hasLength(11));
    _expectOnScales(chart);

    await _tap(tester, 'axes.count.100');
    expect(chart.getDatasetMeta(1).data, hasLength(100));
    expect(_scale(chart, 'x').getLabels(), hasLength(100));
    _expectOnScales(chart);
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: the readout maps the pointer through the scales', (
    tester,
  ) async {
    final state = await _pumpAxes(tester);
    final chart = state.chart!;
    await _tap(tester, 'axes.x.type.category');
    // The tap scrolls the page: the host shows again.
    await tester.ensureVisible(find.byKey(const ValueKey('axes.host')));
    await _frames(tester);
    final point = _point(chart, 0, 5);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getTopLeft(_host));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getTopLeft(_host) + Offset(point.x, point.y));
    await _frames(tester, 3);

    // The event position is in whole pixels (helpers.dom.ts:173-174).
    final px = point.x.roundToDouble();
    final py = point.y.roundToDouble();
    // The point P6 at the index 5: its pixel gives the value 5 and the
    // label P6, and the value gives the pixel of the label.
    final x = _scale(chart, 'x');
    expect(x.getValueForPixel(px), 5);
    final back = (x.getPixelForValue(5.0) - px).toStringAsFixed(2);
    expect(
      _row(state, 'pointer x'),
      '${px.toStringAsFixed(1)} px → 5.00 → P6 (round trip $back px)',
    );
    // The value of the y pixel is near the y of the point.
    final y = _scale(chart, 'y');
    final value = y.getValueForPixel(py)!;
    final perPixel = (y.max - y.min) / chart.chartArea!.height;
    expect(value, closeTo(state.dataOf(0)[5]['y']! as double, perPixel));
    expect(
      _row(state, 'pointer y'),
      '${py.toStringAsFixed(1)} px → ${value.toStringAsFixed(2)} → '
      '${y.getLabelForValue(value)} '
      '(round trip ${(y.getPixelForValue(value) - py).toStringAsFixed(2)} px)',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('axes.readout')),
        matching: find.textContaining('P6 (round trip'),
      ),
      findsOneWidget,
    );

    // The pointer leaves the chart.
    await mouse.moveTo(tester.getTopLeft(_host) - const Offset(5, 5));
    await _frames(tester, 3);
    expect(_row(state, 'pointer x'), '-');
    expect(tester.takeException(), isNull);
  });
}
