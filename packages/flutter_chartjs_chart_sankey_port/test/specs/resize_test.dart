// Ported from chartjs-chart-sankey v0.19.1 test/specs/resize.spec.js (MIT, Jukka Kurkela).
@TestOn('vm')
library;

import 'dart:ui';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

/// The drawn share of the flows of [chart].
///
/// Upstream counts the painted pixels of the canvas bitmap (`ink`). The
/// port compares no image (Chart.js ADR 0034): the drawn part of a flow is
/// its `progress`, which the clip of `Flow.draw` applies.
// DIVERGES(sankey): harness-resize-ink, the progress of the flows.
double _ink(Chart chart) {
  final flows = chart.getDatasetMeta(0).data.cast<Flow>();
  var drawn = 0.0;
  for (final flow in flows) {
    drawn += flow.progress;
  }
  return drawn / flows.length;
}

List<SankeyDataPoint> _data() => [
  const SankeyDataPoint(flow: 15, from: 'Oil', to: 'Fossil fuels'),
  const SankeyDataPoint(flow: 20, from: 'Natural gas', to: 'Fossil fuels'),
  const SankeyDataPoint(flow: 25, from: 'Coal', to: 'Fossil fuels'),
  const SankeyDataPoint(flow: 60, from: 'Fossil fuels', to: 'Energy'),
  const SankeyDataPoint(flow: 10, from: 'Nuclear', to: 'Energy'),
  const SankeyDataPoint(flow: 30, from: 'Renewables', to: 'Energy'),
  const SankeyDataPoint(flow: 40, from: 'Energy', to: 'Electricity'),
  const SankeyDataPoint(flow: 35, from: 'Energy', to: 'Heat'),
  const SankeyDataPoint(flow: 25, from: 'Energy', to: 'Lost'),
];

void main() {
  group('resize', () {
    testWidgets('should keep painting a frame while the container is being '
        'resized (#70)', (tester) async {
      late Chart chart;
      final early = <double>[];

      // Let the first render's progress animation finish before touching
      // size: this is the animation the fix must leave untouched.
      await waitForDone((done) {
        chart = acquireChartRoot(
          ChartConfigLowering(
            ChartConfig(
              datasets: [
                SankeyDataset(
                  data: _data(),
                  borderWidth: 2,
                  colorFrom: const SankeyColor.constant(
                    ChartPaint.solid(Color(0xFFFF0000)),
                  ),
                  colorTo: const SankeyColor.constant(
                    ChartPaint.solid(Color(0xFF008000)),
                  ),
                ),
              ],
              animation: ChartAnimation(onComplete: (event) => done()),
              maintainAspectRatio: false,
              responsive: true,
            ),
          ).lower(),
          const AcquireOptions(wrapper: HarnessBox(width: 800, height: 400)),
        );
        early.add(_ink(chart));
      });
      // The first render starts with no flow drawn: the animation `progress`
      // runs.
      expect(early.single, lessThan(1));
      final stableInk = _ink(chart);
      expect(stableInk, greaterThan(0));

      chart.canvas!.parentElement!.width = 500;

      final frames = <double>[];
      for (var i = 0; i < 6; i++) {
        await pumpFrame();
        frames.add(_ink(chart));
      }

      expect(chart.width, 500);
      for (final (i, frame) in frames.indexed) {
        expect(frame, greaterThan(stableInk / 2), reason: 'frame $i: $frames');
      }
    });
  });
}
