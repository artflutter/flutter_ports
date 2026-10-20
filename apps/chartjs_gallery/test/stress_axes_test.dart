// Original code, not ported from Chart.js: tests of the stress mode axes.

import 'dart:convert';

import 'package:chartjs_gallery/demo/chart_canvas.dart';
import 'package:chartjs_gallery/demo/stress_axes.dart';
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:chartjs_gallery/demo/stress_point_controller.dart';
import 'package:chartjs_gallery/main_stress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/elements/index.dart';
import 'package:flutter_chartjs/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs/src/platform/platform.flutter.dart';
import 'package:flutter_chartjs/src/scales/index.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stress_controls.dart';

/// The point count of these tests: small, so that a frame is fast.
const int _n = 300;

/// Pumps [count] frames of 20 ms. The loop runs, so pumpAndSettle would not
/// return.
Future<void> _frames(WidgetTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Runs [count] windows of the figures. The window is 500 ms of the
/// Stopwatch of the loop, real time: each window pumps 20 frames, and
/// runAsync lets the real time pass. The next frame ends the window and
/// publishes its figures.
Future<void> _runWindows(WidgetTester tester, int count) async {
  for (var k = 0; k < count; k++) {
    await _frames(tester, 20);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 520)),
    );
  }
  await _frames(tester, 3);
}

/// The figures of the ended windows in [stats]: only a window gives a frame
/// rate.
List<StressStats> _windowStats(Iterable<StressStats> stats) => [
  for (final s in stats)
    if (s.fps > 0) s,
];

/// Pumps a stress tab in the mode axes with [_n] points and 10 labels. It
/// gives the list that receives the published figures.
Future<List<StressStats>> _pumpAxes(
  WidgetTester tester, {
  StressChartCall call = StressChartCall.draw,
  StressAxisType scale = StressAxisType.linear,
  StressAxisType yScale = StressAxisType.linear,
  bool autoSkip = true,
  bool autoStart = true,
  StressMode mode = StressMode.axes,
}) async {
  final stats = <StressStats>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StressDemo(
          initialMode: mode,
          initialN: _n,
          initialM: 10,
          initialCall: call,
          initialScale: scale,
          initialYScale: yScale,
          initialAutoSkip: autoSkip,
          autoStart: autoStart,
          onStats: stats.add,
        ),
      ),
    ),
  );
  return stats;
}

/// The state of the stress tab.
StressDemoState _state(WidgetTester tester) =>
    tester.state<StressDemoState>(find.byType(StressDemo));

/// The chart of the stress tab.
Chart _chart(WidgetTester tester) => _state(tester).debugChart!;

/// The scale [id] of the chart.
Scale _scale(WidgetTester tester, String id) => _chart(tester).scales[id]!;

/// The point elements of the chart.
List<PointElement> _points(WidgetTester tester) => [
  for (final element in _chart(tester).getDatasetMeta(0).data)
    element as PointElement,
];

/// Taps the control of [key] (stressTap), then pumps frames.
Future<void> _tap(WidgetTester tester, String key) async {
  await stressTap(tester, key);
  await _frames(tester);
}

/// Whether the menu item of [key] is checked.
Future<bool> _selected(WidgetTester tester, String key) =>
    stressSelected(tester, key);

/// The scale class of each scale type.
final Map<StressAxisType, Matcher> _scaleClass = {
  StressAxisType.linear: isA<LinearScale>(),
  StressAxisType.logarithmic: isA<LogarithmicScale>(),
  StressAxisType.category: isA<CategoryScale>(),
  StressAxisType.time: isA<TimeScale>(),
};

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final scale in StressAxisType.values) {
    for (final call in [StressChartCall.draw, StressChartCall.update]) {
      testWidgets(
        'axes, ${scale.name}, ${call.name}: the points are on the scales',
        (tester) async {
          final stats = await _pumpAxes(tester, call: call, scale: scale);
          await _frames(tester, 10);
          final chart = _chart(tester);
          expect(chart.platform, isA<FlutterPlatform>());
          expect(chart.config.type, StressPointController.id);
          expect(chart.options['animation'], false);
          expect(chart.options['events'], isEmpty);
          final x = _scale(tester, 'x');
          final y = _scale(tester, 'y');
          expect(x, _scaleClass[scale]);
          expect(y, isA<LinearScale>());
          final meta = chart.getDatasetMeta(0);
          expect(identical(meta.iScale, x), isTrue);
          expect(identical(meta.vScale, y), isTrue);
          expect(meta.controller!.enableOptionSharing, isTrue);
          final points = _points(tester);
          expect(points, hasLength(_n));
          expect(
            x.getLabels(),
            hasLength(scale == StressAxisType.category ? _n : 0),
          );
          final first = (x: points.first.x, y: points.first.y);

          await _frames(tester, 10);
          // A draw keeps the points. An update moves them through the data
          // objects and update('none'): the y values. The x values stay
          // sorted, as parsing: false needs (data-structures.md:74).
          expect(points.first.y != first.y, call == StressChartCall.update);
          expect(points.first.x, first.x);
          expect(identical(_points(tester).first, points.first), isTrue);
          final data = _state(tester).debugChartData;
          expect(data, hasLength(_n));
          // The sorted meta gives the x range from the first and the last
          // point (core.datasetController.js:625-655): the x values rise.
          for (var i = 1; i < _n; i++) {
            expect(
              jsToNumber(data[i]['x']),
              greaterThan(jsToNumber(data[i - 1]['x'])),
            );
          }
          expect(chart.getDatasetMeta(0).sorted, isTrue);
          expect(
            _scale(tester, 'x').min,
            lessThanOrEqualTo(jsToNumber(data.first['x'])),
          );
          expect(
            _scale(tester, 'x').max,
            greaterThanOrEqualTo(jsToNumber(data.last['x'])),
          );
          // controller.line.js:97-98: the pixels of the raw parsed values.
          final scaleX = _scale(tester, 'x');
          final scaleY = _scale(tester, 'y');
          expect(points[7].x, scaleX.getPixelForValue(data[7]['x'], 7));
          expect(points[7].y, scaleY.getPixelForValue(data[7]['y'], 7));
          expect(points[7].options!['radius'], 3);

          // Stopping publishes the figures with the x ticks.
          await _tap(tester, 'stress.start');
          expect(stats, isNotEmpty);
          expect(stats.last.mode, StressMode.axes);
          expect(stats.last.points, _n);
          expect(stats.last.labels, 10);
          expect(stats.last.frames, greaterThan(0));
          expect(stats.last.ticks, scaleX.ticks!.length);
          expect(stats.last.ticks, greaterThan(1));
          expect(stats.last.rotation, jsToNumber(scaleX.labelRotation));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('axes: the controls have keys and make a new chart', (
    tester,
  ) async {
    await _pumpAxes(tester, autoStart: false);
    await _frames(tester);
    for (final key in [
      'stress.mode.axes',
      'stress.axes.host',
      'stress.chart.call.draw',
      'stress.chart.call.update',
      for (final type in StressAxisType.values)
        'stress.axes.scale.${type.name}',
      'stress.axes.yScale.linear',
      'stress.axes.yScale.logarithmic',
      'stress.axes.autoSkip',
      'stress.n.1000',
      'stress.m.0',
      'stress.spin',
      'stress.start',
      'stress.stats',
    ]) {
      expect(await stressControlExists(tester, key), isTrue, reason: key);
    }
    expect(await _selected(tester, 'stress.mode.axes'), isTrue);
    expect(await _selected(tester, 'stress.axes.scale.linear'), isTrue);
    expect(await _selected(tester, 'stress.axes.yScale.linear'), isTrue);
    // The mode axes has no animate call, and no chart case controls.
    for (final key in [
      'stress.chart.call.animate',
      'stress.chart.sharing',
      'stress.chart.scriptable',
      'stress.axes.yScale.category',
      'stress.chart.host',
      'stress.host',
    ]) {
      expect(await stressControlExists(tester, key), isFalse, reason: key);
    }
    final first = _chart(tester);

    // The call changes the frames, not the chart.
    await _tap(tester, 'stress.chart.call.update');
    expect(await _selected(tester, 'stress.chart.call.update'), isTrue);
    expect(identical(_chart(tester), first), isTrue);

    // A scale type makes a new chart. The old chart is destroyed.
    await _tap(tester, 'stress.axes.scale.category');
    final second = _chart(tester);
    expect(identical(second, first), isFalse);
    expect(first.canvas, isNull);
    expect(_scale(tester, 'x'), isA<CategoryScale>());
    expect(await _selected(tester, 'stress.axes.scale.category'), isTrue);
    final skipped = _scale(tester, 'x').ticks!.length;
    expect(skipped, lessThan(_n));

    // Without the auto skip, the category axis has a tick for each point.
    await _tap(tester, 'stress.axes.autoSkip');
    final third = _chart(tester);
    expect(identical(third, second), isFalse);
    expect(_scale(tester, 'x').ticks, hasLength(_n));

    // The y scale.
    await _tap(tester, 'stress.axes.yScale.logarithmic');
    expect(_scale(tester, 'y'), isA<LogarithmicScale>());
    expect(identical(_chart(tester), third), isFalse);
    final value = _state(tester).debugChartData.first['y']! as double;
    expect(value, inInclusiveRange(1, 100000));

    // N makes a new chart of N points.
    await _tap(tester, 'stress.n.1000');
    expect(_points(tester), hasLength(1000));
    // A selected chip keeps the chart.
    final fourth = _chart(tester);
    await _tap(tester, 'stress.axes.scale.category');
    expect(identical(_chart(tester), fourth), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: the mode takes the call draw for animate', (
    tester,
  ) async {
    await _pumpAxes(
      tester,
      mode: StressMode.chart,
      call: StressChartCall.animate,
      autoStart: false,
    );
    await _frames(tester);
    expect(await _selected(tester, 'stress.chart.call.animate'), isTrue);
    await _tap(tester, 'stress.mode.axes');
    expect(await _selected(tester, 'stress.chart.call.draw'), isTrue);
    expect(_chart(tester).options['animation'], false);
    expect(_scale(tester, 'x'), isA<LinearScale>());
    // Back in the mode chart, the chart has no scales.
    await _tap(tester, 'stress.mode.chart');
    expect(_chart(tester).scales, isEmpty);
    expect(_chart(tester).getDatasetMeta(0).iScale, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes: an initial call animate runs as draw', (tester) async {
    final stats = await _pumpAxes(tester, call: StressChartCall.animate);
    await _frames(tester, 10);
    expect(await _selected(tester, 'stress.chart.call.draw'), isTrue);
    expect(
      await stressControlExists(tester, 'stress.chart.call.animate'),
      isFalse,
    );
    // The loop does not wait for an animation: each frame draws. A frame
    // of the call draw has no layout and no dataset update, also in the
    // first window (the call update has them in each window).
    await _runWindows(tester, 2);
    final windows = _windowStats(stats);
    expect(windows, isNotEmpty);
    for (final window in windows) {
      expect(window.drawMs, greaterThan(0));
      expect(window.datasetsDrawMs, greaterThan(0));
      expect(window.layoutMs, 0);
      expect(window.datasetsUpdateMs, 0);
    }
    await _tap(tester, 'stress.start');
    expect(tester.takeException(), isNull);
  });

  testWidgets('axes, draw: the parts have only the hooks of the frame call', (
    tester,
  ) async {
    // The update at the construction of a chart and the update of the
    // first resize of its host run outside the frame call. A call draw
    // gives no layout and no dataset update, also in the first window after
    // the start and after a new chart.
    final stats = await _pumpAxes(tester);
    await _runWindows(tester, 2);
    final started = _windowStats(stats);
    final before = stats.length;
    // A new chart while the loop runs.
    await _tap(tester, 'stress.axes.scale.time');
    expect(_scale(tester, 'x'), isA<TimeScale>());
    await _runWindows(tester, 2);
    final switched = _windowStats(stats.skip(before));
    expect(started, isNotEmpty);
    expect(switched, isNotEmpty);
    for (final window in [...started, ...switched]) {
      expect(window.layoutMs, 0);
      expect(window.datasetsUpdateMs, 0);
      expect(window.datasetsDrawMs, greaterThan(0));
      expect(window.datasetsDrawMs, lessThan(window.drawMs));
    }
    await _tap(tester, 'stress.start');
    expect(tester.takeException(), isNull);
  });

  group('the timing split', () {
    /// Runs the mode axes with [call] for 4 windows of real time, and gives
    /// the published figures.
    Future<List<StressStats>> run(
      WidgetTester tester,
      StressChartCall call,
    ) async {
      final stats = await _pumpAxes(
        tester,
        call: call,
        scale: StressAxisType.time,
      );
      await _runWindows(tester, 4);
      return stats.where((s) => s.frames > 20).toList();
    }

    testWidgets('draw: the datasets draw only', (tester) async {
      final stats = await run(tester, StressChartCall.draw);
      expect(stats, isNotEmpty);
      final last = stats.last;
      expect(last.drawMs, greaterThan(0));
      expect(last.datasetsDrawMs, greaterThan(0));
      expect(last.datasetsDrawMs, lessThan(last.drawMs));
      expect(last.layoutMs, 0);
      expect(last.datasetsUpdateMs, 0);
      expect(last.ticks, greaterThan(1));
      await _tap(tester, 'stress.start');
    });

    testWidgets('update: the layout and the datasets update', (tester) async {
      final stats = await run(tester, StressChartCall.update);
      expect(stats, isNotEmpty);
      final last = stats.last;
      expect(last.updateMs, greaterThan(0));
      expect(last.layoutMs, greaterThan(0));
      expect(last.datasetsUpdateMs, greaterThan(0));
      // Both parts are in the update time, without its draw.
      expect(
        last.layoutMs + last.datasetsUpdateMs,
        lessThan(last.updateMs),
      );
      expect(last.datasetsDrawMs, lessThan(last.drawMs));
      await _tap(tester, 'stress.start');
    });
  });

  testWidgets('main_stress gives the keys of the mode axes', (tester) async {
    final lines = <String>[];
    final old = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null && message.startsWith('STRESS {')) {
        lines.add(message);
      }
    };
    try {
      await tester.pumpWidget(
        const StressProfileApp(
          mode: StressMode.axes,
          scenarios: [(300, 0)],
          scale: StressAxisType.category,
          yScale: StressAxisType.logarithmic,
          autoSkip: false,
        ),
      );
      await _frames(tester, 40);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 600)),
      );
      await _frames(tester, 5);
      await tester.pump(const Duration(seconds: stressSeconds));
    } finally {
      // flutter_test checks the debug variables before the tearDown.
      debugPrint = old;
    }
    expect(lines, hasLength(1));
    final line =
        jsonDecode(lines.single.substring('STRESS '.length))
            as Map<String, Object?>;
    expect(line['mode'], 'axes');
    expect(line['n'], 300);
    expect(line['call'], 'draw');
    expect(line['scale'], 'category');
    expect(line['yScale'], 'logarithmic');
    expect(line['autoSkip'], false);
    // Without the auto skip, the category axis has a tick for each point.
    expect(line['ticks'], 300);
    expect(line['rotation'], matches(RegExp(r'^\d+\.\d\d$')));
    for (final key in ['layoutMs', 'datasetsUpdateMs', 'datasetsDrawMs']) {
      expect(line[key], matches(RegExp(r'^\d+\.\d\d$')), reason: key);
    }
    expect(line.keys, isNot(contains('sharing')));
    expect(line.keys, isNot(contains('animatorMs')));
    final host = tester.state<ChartCanvasState>(
      find.byKey(const ValueKey('stress.axes.host')),
    );
    expect(host.chart!.scales['y'], isA<LogarithmicScale>());
    await tester.pumpWidget(const SizedBox());
  });

  test('stressDefaultScenarios of the mode axes', () {
    expect(stressDefaultScenarios(StressMode.axes), [
      (1000, 0),
      (5000, 0),
      (20000, 0),
    ]);
    expect(StressMode.axes.runsChart, isTrue);
    expect(StressMode.chart.runsChart, isTrue);
    expect(StressMode.bars.runsChart, isFalse);
  });
}
