// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/stacking/remove-dataset.js (MIT, Chart.js Contributors).
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

import '../../../../support/list_splice.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `chart.data.datasets.splice(0, 1)` is [spliceList], then
/// [notifyArrayListeners], the body of the hooked method (differences.md
/// row platform-array-events). The datasets array has no listeners, so the
/// notification does nothing, as upstream.
FixtureConfig fixture() {
  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          data: .points([
            // { x: 0, y: 0 },
            DataPoint(1, 5),
            DataPoint(2, 5),
            DataPoint(3, 5),
            DataPoint(4, 5),
            DataPoint(5, 5),
            DataPoint(6, 5),
          ]),
        ),
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
          data: .points([
            DataPoint(0, 5),
            // { x: 1, y: 0 },
            DataPoint(2, 5),
            DataPoint(3, 5),
            DataPoint(4, 5),
            DataPoint(5, 5),
            DataPoint(6, 5),
          ]),
        ),
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF008000))),
          data: .points([
            DataPoint(0, 5),
            DataPoint(1, 5),
            // { x: 2, y: 0 },
            DataPoint(3, 5),
            DataPoint(4, 5),
            DataPoint(5, 5),
            DataPoint(6, 5),
          ]),
        ),
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFFFFFF00))),
          data: .points([
            DataPoint(0, 5),
            DataPoint(1, 5),
            DataPoint(2, 5),
            // {x: 3, y: 0 },
            DataPoint(4, 5),
            DataPoint(5, 5),
            DataPoint(6, 5),
          ]),
        ),
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF800080))),
          data: .points([
            DataPoint(0, 5),
            DataPoint(1, 5),
            DataPoint(2, 5),
            DataPoint(3, 5),
            // { x: 4, y: 0 },
            DataPoint(5, 5),
            DataPoint(6, 5),
          ]),
        ),
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF808080))),
          data: .points([
            DataPoint(0, 5),
            DataPoint(1, 5),
            DataPoint(2, 5),
            DataPoint(3, 5),
            DataPoint(4, 5),
            // { x: 5, y: 0 },
            DataPoint(6, 5),
          ]),
        ),
      ],
      labels: <Object>[0, 1, 2, 3, 4, 5, 6],
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
    run: (chart) {
      final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
      spliceList(datasets, 0, 1);
      notifyArrayListeners(datasets, 'splice', <Object?>[0, 1]);
      chart.update();
    },
  );
}
