// Original code, not ported from Chart.js: the tests of the live chart.

import 'package:chartjs_supabase_dashboard/src/live_chart.dart';
import 'package:chartjs_supabase_dashboard/src/live_series.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_metric_source.dart';

void main() {
  setUpAll(() => Chart.register(registerables));

  testWidgets('the chart area keeps its size while ticks pass the edges', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1000, 500)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final series = LiveSeries(MemoryMetricSource(rows: 2000));
    Chart? chart;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveChart(series: series, onChartCreated: (c) => chart = c),
        ),
      ),
    );
    await series.start(pump: false);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // 7 pixels a frame for 150 frames: about 15 ticks of 10 seconds pass the
    // edges, and the y labels change.
    final center = tester.getCenter(find.byType(LiveChart));
    final areas = <(double, double, double, double)>{};
    final labels = <String>{};
    for (var i = 0; i < 150; i++) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(position: center, scrollDelta: const Offset(0, 7)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final area = chart!.chartArea!;
      areas.add((area.left, area.top, area.right, area.bottom));
      labels.add(chart!.scales['x']!.ticks!.first.label!.first);
    }

    expect(labels.length, greaterThan(5), reason: 'the ticks moved');
    expect(areas, hasLength(1));

    await tester.pumpWidget(const SizedBox());
    series.dispose();
  });
}
