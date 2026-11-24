// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/stacking/issue-9105.js (MIT, Chart.js Contributors).
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
  final yAxis = LinearAxis(CartesianAxis.y, display: ScaleDisplay.off);
  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xCCFF6384))),
          label: 'Dataset 1',
          data: .values(<num?>[12, 19, 3, 5, 2, 3]),
          stack: '0',
          yAxis: yAxis,
        ),
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xCC36A2EB))),
          label: 'Dataset 2',
          data: .values(<num?>[13, 19, 3, 5, 8, 3]),
          stack: '0',
          yAxis: yAxis,
        ),
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xCC4BC0C0))),
          label: 'Dataset 3',
          data: .values(<num?>[13, 19, 3, 5, 8, 3]),
          stack: '0',
          yAxis: yAxis,
        ),
      ],
      labels: <Object>['January', 'February', 'March', 'April', 'May', 'June'],
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        yAxis,
      ],
      extra: <String, Object?>{'plugins': false},
    ),
    description: 'https://github.com/chartjs/Chart.js/issues/9105',
    run: (chart) {
      // The dataset is a typed scope of the lowering: a write by name.
      jsSet(jsGet(jsGet(chart.data, 'datasets'), 1), 'stack', '1');
      chart.update();
    },
  );
}
