// Original code, not ported from Chart.js: tests of the stress mode chart.

import 'package:chartjs_gallery/demo/chart_canvas.dart';
import 'package:chartjs_gallery/demo/demo_chart.dart' show DemoCanvasState;
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:chartjs_gallery/demo/stress_point_controller.dart';
import 'package:chartjs_gallery/main_stress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart';
import 'package:flutter_chartjs/src/elements/index.dart';
import 'package:flutter_chartjs/src/js/js_object.dart' show jsObjectIsFrozen;
import 'package:flutter_chartjs/src/platform/platform.flutter.dart';
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

/// Pumps a stress tab in the mode chart with [_n] points and 10 labels. It
/// gives the list that receives the published figures.
Future<List<StressStats>> _pumpChart(
  WidgetTester tester, {
  StressChartCall call = StressChartCall.draw,
  bool sharing = true,
  bool scriptable = false,
  bool autoStart = true,
}) async {
  final stats = <StressStats>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StressDemo(
          initialMode: StressMode.chart,
          initialN: _n,
          initialM: 10,
          initialCall: call,
          initialSharing: sharing,
          initialScriptable: scriptable,
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

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final call in [StressChartCall.draw, StressChartCall.update]) {
    for (final sharing in [true, false]) {
      testWidgets(
        'chart, ${call.name}, sharing $sharing: the loop runs the chart',
        (tester) async {
          final stats = await _pumpChart(tester, call: call, sharing: sharing);
          await _frames(tester, 10);
          final chart = _chart(tester);
          expect(chart.platform, isA<FlutterPlatform>());
          expect(chart.config.type, StressPointController.id);
          expect(chart.options['animation'], false);
          final meta = chart.getDatasetMeta(0);
          expect(meta.controller, isA<StressPointController>());
          expect(meta.controller!.enableOptionSharing, sharing);
          final points = _points(tester);
          expect(points, hasLength(_n));
          final first = (x: points.first.x, y: points.first.y);
          final canvas = tester
              .state<ChartCanvasState>(
                find.byKey(const ValueKey('stress.chart.host')),
              )
              .canvas;
          expect(canvas.getContext2d().isEmpty, isFalse);

          await _frames(tester, 10);
          // Case (a) draws the same points. Case (b) moves them through the
          // data objects and update('none').
          final moved = points.first.x != first.x || points.first.y != first.y;
          expect(moved, call == StressChartCall.update);
          expect(identical(_points(tester).first, points.first), isTrue);
          final data = _state(tester).debugChartData;
          expect(data, hasLength(_n));
          if (call == StressChartCall.update) {
            final area = chart.chartArea!;
            expect(
              points[7].x,
              area.left + (data[7]['x']! as double) * area.width,
            );
          }

          // The points get typed options. With the sharing, they hold the
          // one copy of getSharedOptions, as in a line chart. Without it,
          // each point holds its own copy of the cache entry, as in a scatter
          // chart (Chart.js ADR 0021, section 8).
          final options = points.first.options;
          expect(options, isA<PointOptions>());
          expect(jsObjectIsFrozen(options), isFalse);
          expect(identical(points[1].options, options), sharing);
          expect(options!['radius'], 3);
          expect(options['backgroundColor'], 'rgba(54, 162, 235, 0.45)');

          // Stopping publishes the figures.
          await _tap(tester, 'stress.start');
          expect(stats, isNotEmpty);
          expect(stats.last.mode, StressMode.chart);
          expect(stats.last.points, _n);
          expect(stats.last.labels, 10);
          expect(stats.last.frames, greaterThan(0));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('chart, update, scriptable: each point resolves its color', (
    tester,
  ) async {
    await _pumpChart(
      tester,
      call: StressChartCall.update,
      scriptable: true,
    );
    await _frames(tester, 10);
    final points = _points(tester);
    final options = points.first.options;
    // A scriptable option needs the context: no sharing (core.config.js:
    // 355-356), and no cache entry.
    expect(options, isA<PointOptions>());
    expect(options![r'$shared'], false);
    expect(identical(points[2].options, options), isFalse);
    expect(options['backgroundColor'], 'rgba(54, 162, 235, 0.45)');
    expect(points[1].options!['backgroundColor'], 'rgba(255, 99, 132, 0.45)');
    final before = points[1].options;
    await _frames(tester, 3);
    // Each update resolves the options again.
    expect(identical(points[1].options, before), isFalse);
    await _tap(tester, 'stress.start');
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart: the controls have keys and make a new chart', (
    tester,
  ) async {
    await _pumpChart(tester, autoStart: false);
    await _frames(tester);
    for (final key in [
      'stress.mode.chart',
      'stress.chart.host',
      'stress.chart.call.draw',
      'stress.chart.call.update',
      'stress.chart.sharing',
      'stress.chart.scriptable',
      'stress.n.1000',
      'stress.m.0',
      'stress.spin',
      'stress.start',
      'stress.stats',
    ]) {
      expect(await stressControlExists(tester, key), isTrue, reason: key);
    }
    expect(await _selected(tester, 'stress.mode.chart'), isTrue);
    expect(await _selected(tester, 'stress.chart.call.draw'), isTrue);
    expect(await stressControlExists(tester, 'stress.layer.points'), isFalse);
    expect(find.byKey(const ValueKey('stress.host')), findsNothing);
    final first = _chart(tester);

    // The call changes the frames, not the chart.
    await _tap(tester, 'stress.chart.call.update');
    expect(await _selected(tester, 'stress.chart.call.update'), isTrue);
    expect(identical(_chart(tester), first), isTrue);

    // The sharing makes a new chart. The old chart is destroyed.
    await _tap(tester, 'stress.chart.sharing');
    final second = _chart(tester);
    expect(identical(second, first), isFalse);
    expect(first.canvas, isNull);
    expect(second.getDatasetMeta(0).controller!.enableOptionSharing, isFalse);

    // N makes a new chart of N points.
    await _tap(tester, 'stress.n.1000');
    expect(_points(tester), hasLength(1000));
    expect(identical(_chart(tester), second), isFalse);

    // The scriptable color makes a new chart.
    final third = _chart(tester);
    await _tap(tester, 'stress.chart.scriptable');
    expect(identical(_chart(tester), third), isFalse);
    expect(
      _points(tester)[1].options!['backgroundColor'],
      'rgba(255, 99, 132, 0.45)',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart: the call animate makes a new chart, and the loop goes '
      'on', (tester) async {
    final stats = await _pumpChart(tester);
    await _frames(tester, 10);
    var chart = _chart(tester);
    expect(chart.options['animation'], false);
    for (final (key, animated) in [
      ('stress.chart.call.animate', true),
      ('stress.chart.call.draw', false),
    ]) {
      // A change to or from animate gives another `animation` option, thus
      // a new chart. The old chart is destroyed.
      await _tap(tester, key);
      expect(await _selected(tester, key), isTrue, reason: key);
      final next = _state(tester).debugChart;
      expect(next, isNotNull, reason: key);
      expect(identical(next, chart), isFalse, reason: key);
      expect(chart.canvas, isNull, reason: key);
      expect(next!.options['animation'] != false, animated, reason: key);
      chart = next;
      // The running loop goes on with the new chart.
      final frames = _state(tester).debugFrames;
      await _frames(tester, 5);
      expect(_state(tester).debugFrames, greaterThan(frames), reason: key);
    }
    await _tap(tester, 'stress.start');
    expect(stats.last.frames, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('chart: a running loop goes on across the modes', (
    tester,
  ) async {
    final stats = await _pumpChart(tester, call: StressChartCall.update);
    await _frames(tester, 10);
    final x = _points(tester).first.x;
    await _frames(tester, 5);
    expect(_points(tester).first.x, isNot(x));

    // The elements mode gets a new host and goes on.
    await _tap(tester, 'stress.mode.elements');
    expect(_state(tester).debugChart, isNull);
    await _frames(tester, 10);
    final host = tester.state<DemoCanvasState>(
      find.byKey(const ValueKey('stress.host')),
    );
    final renders = host.chart!.renders;
    await _frames(tester, 5);
    expect(host.chart!.renders, greaterThan(renders));

    // The modes of the demo chart keep their host.
    await _tap(tester, 'stress.mode.bars');
    final bars = host.chart!.renders;
    await _frames(tester, 5);
    expect(host.chart!.renders, greaterThan(bars));

    // Back in the mode chart, a new chart runs.
    await _tap(tester, 'stress.mode.chart');
    await _frames(tester, 10);
    final again = _points(tester).first.x;
    await _frames(tester, 5);
    expect(_points(tester).first.x, isNot(again));
    await _tap(tester, 'stress.start');
    expect(stats.last.mode, StressMode.chart);
    expect(tester.takeException(), isNull);
  });

  group('the timing split', () {
    /// Runs the mode chart with [call] for 4 windows of real time, and
    /// gives the published figures. The window of the figures is 500 ms of
    /// the Stopwatch, real time: runAsync lets it pass.
    Future<List<StressStats>> run(
      WidgetTester tester,
      StressChartCall call,
    ) async {
      final stats = await _pumpChart(tester, call: call);
      for (var k = 0; k < 4; k++) {
        await _frames(tester, 20);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 520)),
        );
      }
      await _frames(tester, 3);
      return stats.where((s) => s.frames > 20).toList();
    }

    testWidgets('draw: drawMs only', (tester) async {
      final stats = await run(tester, StressChartCall.draw);
      expect(stats, isNotEmpty);
      expect(stats.last.drawMs, greaterThan(0));
      expect(stats.last.updateMs, lessThan(stats.last.drawMs));
      expect(stats.last.animatorMs, 0);
    });

    testWidgets('update: the draw of update counts in drawMs', (tester) async {
      final stats = await run(tester, StressChartCall.update);
      expect(stats, isNotEmpty);
      // update('none') draws: the draw inside it counts in drawMs, and the
      // rest in updateMs.
      expect(stats.last.drawMs, greaterThan(0));
      expect(stats.last.updateMs, greaterThan(0));
      expect(stats.last.animatorMs, 0);
    });

    testWidgets('animate: the animator ticks and draws in each frame', (
      tester,
    ) async {
      final stats = await run(tester, StressChartCall.animate);
      final chart = _chart(tester);
      expect(chart.options['animation'], isNot(false));
      expect(chart.options['events'], isEmpty);
      expect(stats, isNotEmpty);
      expect(stats.last.drawMs, greaterThan(0));
      expect(stats.last.animatorMs, greaterThan(0));
      // The points move without an update: the animator writes x and y.
      final x = _points(tester).first.x;
      await _frames(tester, 5);
      expect(_points(tester).first.x, isNot(x));
      await _tap(tester, 'stress.start');
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('the chart listens to no event', (tester) async {
    // A pointer over the host would replay its last event in each update
    // (core.controller.js:528-534) and add a second draw to a frame.
    await _pumpChart(tester, call: StressChartCall.update);
    await _frames(tester, 3);
    expect(_chart(tester).options['events'], isEmpty);
  });

  testWidgets('main_stress keeps a late publish out of the next scenario', (
    tester,
  ) async {
    // The frame after the timer of scenario 1 runs the old StressDemo once
    // more. When its window closes in that frame, it publishes the figures
    // of scenario 1. Scenario 2 runs fewer than 30 frames and has no window
    // of its own, so its line must give 0 frames per second.
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
          mode: StressMode.primitives,
          scenarios: [(300, 0), (600, 0)],
        ),
      );
      await _frames(tester, 50);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 700)),
      );
      await tester.pump(const Duration(seconds: stressSeconds));
      await _frames(tester, 10);
      await tester.pump(const Duration(seconds: stressSeconds));
    } finally {
      // flutter_test checks the debug variables before the tearDown.
      debugPrint = old;
    }
    expect(lines, hasLength(2));
    expect(lines[0], contains('"n":300'));
    expect(lines[1], contains('"n":600'));
    expect(lines[1], contains('"fps":"0.00"'));
    await tester.pumpWidget(const SizedBox());
  });
}
