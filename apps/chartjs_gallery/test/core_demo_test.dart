// Original code, not ported from Chart.js: tests of the gallery Core tab.

import 'package:chartjs_gallery/canvas_host_demo.dart';
import 'package:chartjs_gallery/demo/core_demo.dart';
import 'package:chartjs_gallery/demo/stress_point_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart';
import 'package:flutter_chartjs/src/elements/index.dart';
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs/src/platform/chart_host.dart';
import 'package:flutter_chartjs/src/platform/platform.flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tall desktop window: the whole Core tab is in view.
const Size _desktop = Size(1200, 1600);

/// Pumps [count] frames of 16 ms, the frame interval of a browser. The
/// demo page has a running animation (the line dash of the Canvas tab), so
/// pumpAndSettle would not return.
Future<void> _frames(WidgetTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Pumps the demo page in a desktop window and opens the Core tab.
Future<CoreDemoState> _pumpCore(WidgetTester tester) async {
  tester.view
    ..physicalSize = _desktop
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xFFFF6384)),
      home: const CanvasHostDemoPage(),
    ),
  );
  await _frames(tester);
  final tab = find.byKey(const ValueKey('phase3.tab.core'));
  await tester.ensureVisible(tab);
  await tester.pump();
  await tester.tap(tab);
  await _frames(tester, 25);
  final state = tester.state<CoreDemoState>(find.byType(CoreDemo));
  // The first update animates the points from the bottom of the chart area
  // for 1000 ms (the default `animation.duration`).
  await _settle(tester, state.chart!);
  return state;
}

/// Pumps frames until the animator of [chart] stops.
Future<void> _settle(WidgetTester tester, Chart chart) async {
  for (var i = 0; i < 200 && animator.running(chart); i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(animator.running(chart), isFalse);
}

/// The chart host of the Core tab.
Finder get _host => find.descendant(
  of: find.byKey(const ValueKey('core.host')),
  matching: find.byType(ChartHost),
);

/// The point [index] of the dataset [datasetIndex].
PointElement _point(Chart chart, int datasetIndex, int index) =>
    chart.getDatasetMeta(datasetIndex.toDouble()).data[index] as PointElement;

/// The radius of the resolved options of [point].
double _radius(PointElement point) => point.options!['radius']! as double;

/// A mouse that hovers the chart.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: tester.getTopLeft(_host));
  addTearDown(gesture.removePointer);
  return gesture;
}

/// Moves [gesture] to the chart position ([x], [y]).
Future<void> _moveTo(
  WidgetTester tester,
  TestGesture gesture,
  double x,
  double y,
) => gesture.moveTo(tester.getTopLeft(_host) + Offset(x, y));

/// Moves [gesture] to a place of the chart area far from each point: the
/// data `y` stays below 0.9 of the area height.
Future<void> _moveOff(WidgetTester tester, TestGesture gesture, Chart chart) {
  final area = chart.chartArea!;
  return _moveTo(tester, gesture, area.left + area.width / 2, area.top + 2);
}

/// Scrolls the widget of [key] into view and taps it.
Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _frames(tester);
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('core: the tab shows a real Chart of the gallery controller', (
    tester,
  ) async {
    final state = await _pumpCore(tester);
    final chart = state.chart!;
    expect(chart.platform, isA<FlutterPlatform>());
    expect(chart.attached, isTrue);
    expect(chart.config.type, StressPointController.id);
    expect(chart.width, tester.getSize(_host).width);
    expect(chart.height, 320);
    // The controller is the registered gallery class.
    final meta = chart.getDatasetMeta(0);
    expect(meta.controller, isA<StressPointController>());
    expect(meta.dataset, isNull);
    for (var d = 0; d < 2; d++) {
      final data = chart.getDatasetMeta(d.toDouble()).data;
      expect(data, hasLength(12));
      // The points of one dataset share one typed options object, the copy
      // of getSharedOptions (Chart.js ADR 0021).
      final options = (data.first as PointElement).options;
      expect(options, isA<PointOptions>());
      for (final point in data) {
        expect(identical((point as PointElement).options, options), isTrue);
      }
      // controller: x and y are fractions of the chart area.
      final area = chart.chartArea!;
      final item = state.dataOf(d)[2];
      final point = data[2] as PointElement;
      expect(point.x, area.left + (item['x']! as double) * area.width);
      expect(point.y, area.bottom - (item['y']! as double) * area.height);
    }
    expect(_radius(_point(chart, 0, 0)), 6);
    expect(
      tester.widget<ChartHost>(_host).canvas.getContext2d().isEmpty,
      isFalse,
    );
    expect(state.activeLabel, 'none');
    expect(tester.takeException(), isNull);
  });

  testWidgets('core: each control has its key', (tester) async {
    await _pumpCore(tester);
    final keys = [
      'core.host',
      'core.readout',
      for (final mode in coreDemoModes) 'core.mode.$mode',
      for (final axis in coreDemoAxes) 'core.axis.$axis',
      'core.intersect',
      'core.hover.duration',
      'core.animation.duration',
      'core.animation',
      'core.dataset.0',
      'core.dataset.1',
      'core.data.randomize',
      'core.data.add',
      'core.data.remove',
    ];
    for (final key in keys) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
    expect(coreDemoModes, ['index', 'dataset', 'point', 'nearest', 'x', 'y']);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('core.mode.nearest')))
          .selected,
      isTrue,
    );
  });

  testWidgets('core: a hover animates the hover options for 400 ms', (
    tester,
  ) async {
    final state = await _pumpCore(tester);
    final chart = state.chart!;
    final point = _point(chart, 0, 3);
    final shared = _point(chart, 0, 4).options;
    final base = point.options!['backgroundColor'];
    final mouse = await _mouse(tester);

    await _moveTo(tester, mouse, point.x, point.y);
    // The throttled event reaches the chart in the next frame. The animator
    // ticks from the frame after.
    await _frames(tester, 2);
    expect(state.activeLabel, 'd0#3');
    expect(point.active, isTrue);
    await _frames(tester, 10);
    // In the transition: core.animations writes into a copy of the options.
    expect(_radius(point), inExclusiveRange(6, 12));
    expect(point.options, isA<PointOptions>());
    expect(identical(point.options, shared), isFalse);
    expect(animator.running(chart), isTrue);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('core.readout')),
        matching: find.textContaining('running'),
      ),
      findsOneWidget,
    );
    await _frames(tester, 20);
    // The end of the transition: the hover options.
    expect(_radius(point), 12);
    expect(point.options!['backgroundColor'], isNot(base));
    expect(point.options!['borderWidth'], 3);
    expect(animator.running(chart), isFalse);
    // The hover options are not shared (the hover colors are scriptable).
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('core.readout')),
        matching: find.textContaining(r'PointOptions, $shared false'),
      ),
      findsOneWidget,
    );

    // The un-hover animates back. At its end, the point holds the shared
    // options again (core.animations.js:51-60).
    await _moveOff(tester, mouse, chart);
    await _frames(tester, 2);
    expect(state.activeLabel, 'none');
    expect(point.active, isFalse);
    await _frames(tester, 30);
    expect(_radius(point), 6);
    expect(identical(point.options, shared), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('core: the hover duration 0 gives the hover options at once', (
    tester,
  ) async {
    final state = await _pumpCore(tester);
    final chart = state.chart!;
    await tester.drag(
      find.byKey(const ValueKey('core.hover.duration')),
      const Offset(-2000, 0),
    );
    await _frames(tester);
    expect(
      jsGet(
        jsGet(
          jsGet(chart.config.options['transitions'], 'active'),
          'animation',
        ),
        'duration',
      ),
      0,
    );
    final point = _point(chart, 1, 5);
    final mouse = await _mouse(tester);
    await _moveTo(tester, mouse, point.x, point.y);
    await _frames(tester, 2);
    expect(state.activeLabel, 'd1#5');
    expect(_radius(point), 12);
    expect(tester.takeException(), isNull);
  });

  testWidgets('core: the mode index finds the point of each dataset', (
    tester,
  ) async {
    final state = await _pumpCore(tester);
    final chart = state.chart!;
    await _tap(tester, 'core.mode.index');
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('core.mode.index')))
          .selected,
      isTrue,
    );
    expect(jsGet(chart.options['interaction'], 'mode'), 'index');
    final point = _point(chart, 0, 7);
    final mouse = await _mouse(tester);
    await _moveTo(tester, mouse, point.x, point.y);
    await _frames(tester, 3);
    expect(state.activeLabel, 'd0#7 d1#7');
    expect(_point(chart, 1, 7).active, isTrue);

    // Without intersect, a place far from each point finds the nearest
    // index.
    await _tap(tester, 'core.intersect');
    expect(jsGet(chart.options['interaction'], 'intersect'), false);
    await _moveOff(tester, mouse, chart);
    await _frames(tester, 3);
    expect(state.activeLabel, isNot('none'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('core: the axis chips set the axis of the interaction', (
    tester,
  ) async {
    final state = await _pumpCore(tester);
    final chart = state.chart!;
    bool selected(String axis) => tester
        .widget<ChoiceChip>(find.byKey(ValueKey('core.axis.$axis')))
        .selected;
    expect(selected('xy'), isTrue);
    expect(jsGet(chart.options['interaction'], 'axis'), 'xy');

    // Without intersect, the mode nearest with the axis x finds the points
    // at the smallest x distance: the two points of index 3 have the same x.
    await _tap(tester, 'core.intersect');
    await _tap(tester, 'core.axis.x');
    expect(selected('x'), isTrue);
    expect(selected('xy'), isFalse);
    expect(jsGet(chart.options['interaction'], 'axis'), 'x');
    // The chart reads the hover options (hover falls back to interaction).
    expect(jsGet(chart.options['hover'], 'axis'), 'x');
    final point = _point(chart, 0, 3);
    final area = chart.chartArea!;
    final mouse = await _mouse(tester);
    await _moveTo(tester, mouse, point.x, area.top + 2);
    await _frames(tester, 3);
    expect(state.activeLabel, 'd0#3 d1#3');

    // With the axis y, only the y distance counts.
    await _tap(tester, 'core.axis.y');
    expect(selected('y'), isTrue);
    expect(jsGet(chart.options['interaction'], 'axis'), 'y');
    expect(jsGet(chart.options['hover'], 'axis'), 'y');
    await _moveTo(tester, mouse, area.left + 2, point.y);
    await _frames(tester, 3);
    expect(state.activeLabel, 'd0#3');
    expect(tester.takeException(), isNull);
  });

  testWidgets('core: the update duration sets the length of an update', (
    tester,
  ) async {
    final state = await _pumpCore(tester);
    final chart = state.chart!;
    final slider = find.byKey(const ValueKey('core.animation.duration'));
    await tester.ensureVisible(slider);
    await tester.pump();
    await tester.drag(slider, const Offset(3000, 0));
    await _frames(tester);
    expect(jsGet(chart.config.options['animation'], 'duration'), 3000);
    expect(jsGet(chart.options['animation'], 'duration'), 3000);
    await _settle(tester, chart);

    // A randomize animates for 3000 ms, not for the 1000 ms of the default.
    final point = _point(chart, 0, 0);
    final y = point.y;
    await _tap(tester, 'core.data.randomize');
    // The tap pumps 4 frames: 180 frames of 16 ms are 2880 ms.
    await _frames(tester, 176);
    expect(animator.running(chart), isTrue);
    final area = chart.chartArea!;
    final target =
        area.bottom - (state.dataOf(0).first['y']! as double) * area.height;
    expect((point.y - y).abs(), lessThan((target - y).abs()));
    // 200 frames of 16 ms are 3200 ms.
    await _frames(tester, 20);
    expect(animator.running(chart), isFalse);
    expect(point.y, closeTo(target, 1e-9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('core: randomize, add and remove animate the data change', (
    tester,
  ) async {
    final state = await _pumpCore(tester);
    final chart = state.chart!;
    final point = _point(chart, 0, 0);
    final y = point.y;

    await _tap(tester, 'core.data.randomize');
    expect(animator.running(chart), isTrue);
    await _frames(tester, 70);
    expect(animator.running(chart), isFalse);
    final area = chart.chartArea!;
    final item = state.dataOf(0).first;
    expect(
      point.y,
      closeTo(area.bottom - (item['y']! as double) * area.height, 1e-9),
    );
    expect(point.y, isNot(y));

    await _tap(tester, 'core.data.add');
    await _frames(tester, 70);
    for (var d = 0; d < 2; d++) {
      final data = chart.getDatasetMeta(d.toDouble()).data;
      expect(data, hasLength(13));
      final last = data.last as PointElement;
      expect(last.x, closeTo(area.left + 12.5 / 13 * area.width, 1e-9));
      expect(last.options, isA<PointOptions>());
    }
    await _tap(tester, 'core.data.remove');
    await _tap(tester, 'core.data.remove');
    await _frames(tester, 70);
    expect(chart.getDatasetMeta(0).data, hasLength(11));
    expect(chart.getDatasetMeta(1).data, hasLength(11));
    expect(tester.takeException(), isNull);
  });

  testWidgets('core: the dataset chips hide and show a dataset', (
    tester,
  ) async {
    final state = await _pumpCore(tester);
    final chart = state.chart!;
    FilterChip chip() =>
        tester.widget<FilterChip>(find.byKey(const ValueKey('core.dataset.1')));
    expect(chip().selected, isTrue);

    await _tap(tester, 'core.dataset.1');
    expect(chart.isDatasetVisible(1), isFalse);
    expect(chip().selected, isFalse);
    // The hide transition animates.
    expect(animator.running(chart), isTrue);
    await _frames(tester, 70);
    expect(animator.running(chart), isFalse);
    expect(chart.getSortedVisibleDatasetMetas(), hasLength(1));

    await _tap(tester, 'core.dataset.1');
    expect(chart.isDatasetVisible(1), isTrue);
    expect(chip().selected, isTrue);
    await _frames(tester, 70);
    expect(chart.getSortedVisibleDatasetMetas(), hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('core: without animation, a hover sets the options at once', (
    tester,
  ) async {
    final state = await _pumpCore(tester);
    final chart = state.chart!;
    await _tap(tester, 'core.animation');
    expect(chart.options['animation'], false);
    final point = _point(chart, 0, 2);
    final mouse = await _mouse(tester);
    await _moveTo(tester, mouse, point.x, point.y);
    await _frames(tester, 2);
    expect(state.activeLabel, 'd0#2');
    expect(_radius(point), 12);
    expect(animator.running(chart), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('core: a hidden tab mutes the animator of the chart', (
    tester,
  ) async {
    final state = await _pumpCore(tester);
    final chart = state.chart!;
    await _tap(tester, 'core.data.randomize');
    expect(animator.running(chart), isTrue);
    final y = _point(chart, 0, 0).y;

    // The Stress tab shows: the muted animator gives the chart no frames.
    final tab = find.byKey(const ValueKey('phase3.tab.stress'));
    await tester.ensureVisible(tab);
    await tester.pump();
    await tester.tap(tab);
    await _frames(tester, 30);
    final hidden = _point(chart, 0, 0).y;
    await _frames(tester, 10);
    expect(_point(chart, 0, 0).y, hidden);
    expect(hidden, isNot(y));

    // Back on the Core tab, the animation goes on to its end.
    final core = find.byKey(const ValueKey('phase3.tab.core'));
    await tester.ensureVisible(core);
    await tester.pump();
    await tester.tap(core);
    await _frames(tester, 70);
    expect(animator.running(chart), isFalse);
    final area = chart.chartArea!;
    final item = state.dataOf(0).first;
    expect(
      _point(chart, 0, 0).y,
      closeTo(area.bottom - (item['y']! as double) * area.height, 1e-9),
    );
    expect(tester.takeException(), isNull);
  });
}
