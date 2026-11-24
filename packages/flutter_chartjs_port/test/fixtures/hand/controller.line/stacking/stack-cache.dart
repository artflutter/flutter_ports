// Ported from Chart.js v4.6.1 test/fixtures/controller.line/stacking/stack-cache.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() {
  ScatterDataset makeDs(String label, num offset) {
    return ScatterDataset(
      label: label,
      data: .points([
        for (final [x, y] in const [
          [0, 12],
          [1, 19],
          [2, 3],
          [2, 5],
          [3, 2],
          [4, 3],
        ])
          // Upstream: ([x, y]) => ({x, y: y === null ? null : y + offset})
          DataPoint(x, y + offset),
      ]),
      showLine: true,
      spanGaps: false,
      stack: 'stack$label',
      borderColor: .constant(
        ChartPaint.solid(label == 'A' ? Color(0xFFCC0000) : Color(0xFF0000CC)),
      ),
    );
  }

  final dsA = makeDs('A', 0);
  final dsB = makeDs('B', 1);

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [dsA, dsB],
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
      elements: ChartElements(
        point: PointElementStyle(
          backgroundColor: ChartPaint.solid(Color(0xFF444444)),
        ),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24),
    ),
    options: <String, Object?>{
      'canvas': <String, Object?>{'height': 128, 'width': 256},
      'run': (Chart chart) async {
        // `chart.data = {datasets: [dsB, dsA]}`: the dataset scopes of the
        // lowering of dsA and dsB, in the other order.
        final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
        chart
          ..data = (ChartDataScope()
            ..datasets = <Object?>[datasets[1], datasets[0]])
          ..update();
      },
    },
  );
}
