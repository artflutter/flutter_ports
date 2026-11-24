// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/stacking/replace-data.js (MIT, Chart.js Contributors).
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
  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        BarDataset(
          label: 'Dataset 1',
          backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          data: .values(<num?>[5, 5, 5]),
        ),
        BarDataset(
          label: 'Dataset 2',
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
          data: .values(<num?>[5, 5, 5]),
        ),
        BarDataset(
          label: 'Dataset 3',
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF008000))),
          data: .values(<num?>[5, 5, 5]),
        ),
      ],
      labels: <Object>['January', 'February', 'March'],
      scales: [
        // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        CategoryAxis(
          CartesianAxis.x,
          display: ScaleDisplay.off,
          stacked: StackMode.on,
        ),
        // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(
          CartesianAxis.y,
          display: ScaleDisplay.off,
          stacked: StackMode.on,
        ),
      ],
    ),
    description: 'https://github.com/chartjs/Chart.js/issues/8614',
    options: <String, Object?>{
      'run': (Chart chart) {
        // The dataset is a typed scope of the lowering: a write by name.
        jsSet(jsGet(jsGet(chart.data, 'datasets'), 1), 'data', <Object?>[
          <String, Object?>{'x': 'January', 'y': 5},
          // Februay missing
          <String, Object?>{'x': 'March', 'y': 5},
        ]);
        chart.update();
      },
    },
  );
}
