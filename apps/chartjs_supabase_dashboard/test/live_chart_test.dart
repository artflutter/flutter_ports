// Original code, not ported from Chart.js: the tests of the live chart.

import 'package:chartjs_supabase_dashboard/src/live_chart.dart';
import 'package:chartjs_supabase_dashboard/src/live_series.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_metric_source.dart';

/// A live chart of 2000 rows, one a second, in a view of 1000 x 500, after
/// 20 frames. The series has no realtime row: the live edge is the time of
/// the newest row.
Future<(LiveSeries, Chart Function())> showChart(
  WidgetTester tester, {
  MemoryMetricSource? source,
}) async {
  tester.view
    ..physicalSize = const Size(1000, 500)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final series = LiveSeries(source ?? MemoryMetricSource(rows: 2000));
  Chart? chart;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LiveChart(series: series, onChartCreated: (c) => chart = c),
      ),
    ),
  );
  await series.start(pump: false);
  await frames(tester, 20);
  return (series, () => chart!);
}

/// Pumps [count] frames of 16 ms.
Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Unmounts the chart and disposes [series].
Future<void> close(WidgetTester tester, LiveSeries series) async {
  await tester.pumpWidget(const SizedBox());
  series.dispose();
}

double edgeOf(LiveSeries series) =>
    series.newest!.millisecondsSinceEpoch.toDouble();

void main() {
  setUpAll(() => Chart.register(registerables));

  testWidgets('the chart area keeps its size while ticks pass the edges', (
    tester,
  ) async {
    final (series, chart) = await showChart(tester);

    // 7 pixels a frame for 150 frames: about 15 ticks of 10 seconds pass the
    // edges, and the y labels change.
    final center = tester.getCenter(
      find.byKey(const ValueKey('dashboard.chart')),
    );
    final areas = <(double, double, double, double)>{};
    final labels = <String>{};
    for (var i = 0; i < 150; i++) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 7)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final area = chart().chartArea!;
      areas.add((area.left, area.top, area.right, area.bottom));
      labels.add(chart().scales['x']!.ticks!.first.label!.first);
    }

    expect(labels.length, greaterThan(5), reason: 'the ticks moved');
    expect(areas, hasLength(1));

    await close(tester, series);
  });

  testWidgets('Live moves to the live edge on a curve, not in one frame', (
    tester,
  ) async {
    final (series, chart) = await showChart(tester);
    final center = tester.getCenter(
      find.byKey(const ValueKey('dashboard.chart')),
    );
    for (var i = 0; i < 10; i++) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: center,
          scrollDelta: const Offset(0, 1000),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    await frames(tester, 60);
    final width = chart().scales['x']!.max - chart().scales['x']!.min;
    final from = chart().scales['x']!.max;
    final distance = edgeOf(series) - from;
    expect(distance, greaterThan(5 * width), reason: 'far in the history');

    await tester.tap(find.byKey(const ValueKey('dashboard.live')));
    final steps = <double>[];
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      steps.add(chart().scales['x']!.max);
    }

    // Each frame moves forward, and no frame moves more than a small part of
    // the way: on the curve of 1.4 s, the largest step is about 2 %.
    var previous = from;
    for (final step in steps) {
      expect(step, greaterThanOrEqualTo(previous));
      expect(step - previous, lessThan(distance * 0.05));
      previous = step;
    }
    expect(steps.last, closeTo(edgeOf(series), 1));
    expect(
      chart().scales['x']!.max - chart().scales['x']!.min,
      closeTo(width, 1),
      reason: 'the move keeps the width',
    );
    expect(find.byKey(const ValueKey('dashboard.live')), findsNothing);

    await close(tester, series);
  });

  testWidgets('zoom in halves the width and keeps the live edge', (
    tester,
  ) async {
    final (series, chart) = await showChart(tester);
    double width() => chart().scales['x']!.max - chart().scales['x']!.min;
    final before = width();

    await tester.tap(find.byKey(const ValueKey('dashboard.zoom.in')));
    await frames(tester, 3);
    expect(width(), lessThan(before));
    expect(width(), greaterThan(before / 2), reason: 'a move, not a jump');

    await frames(tester, 40);
    expect(width(), closeTo(before / 2, 1));
    expect(chart().scales['x']!.max, closeTo(edgeOf(series), 1));

    await close(tester, series);
  });

  testWidgets('the time labels are at least 5 seconds apart', (tester) async {
    final (series, chart) = await showChart(tester);

    await tester.tap(find.byKey(const ValueKey('dashboard.range.30s')));
    await frames(tester, 40);
    await tester.tap(find.byKey(const ValueKey('dashboard.zoom.in')));
    await frames(tester, 40);

    final x = chart().scales['x']!;
    expect(x.max - x.min, closeTo(15 * 1000, 1));
    final ticks = x.ticks!;
    expect(ticks.length, greaterThanOrEqualTo(2));
    for (var i = 1; i < ticks.length; i++) {
      expect(ticks[i].value - ticks[i - 1].value, greaterThanOrEqualTo(5000));
    }

    await close(tester, series);
  });

  testWidgets('the y labels are whole numbers', (tester) async {
    // A flat line from 50.0 to 50.3: without precision 0, the axis takes
    // steps of 0.2 or 0.5.
    final (series, chart) = await showChart(
      tester,
      source: MemoryMetricSource(
        rows: 2000,
        valueOf: (id) => 50 + (id % 4) * 0.1,
      ),
    );

    final ticks = chart().scales['y']!.ticks!;
    expect(ticks.length, greaterThanOrEqualTo(2));
    for (final tick in ticks) {
      expect(tick.value, tick.value.roundToDouble());
    }

    await close(tester, series);
  });

  testWidgets('a range button sets the width', (tester) async {
    final (series, chart) = await showChart(tester);

    await tester.tap(find.byKey(const ValueKey('dashboard.range.10m')));
    await frames(tester, 40);

    final x = chart().scales['x']!;
    expect(x.max - x.min, closeTo(10 * 60 * 1000, 1));
    expect(x.max, closeTo(edgeOf(series), 1));

    await close(tester, series);
  });
}
