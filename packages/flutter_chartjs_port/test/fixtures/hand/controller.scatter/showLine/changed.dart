// Ported from Chart.js v4.6.1 test/fixtures/controller.scatter/showLine/changed.js (MIT, Chart.js Contributors).
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
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      ScatterDataset(
        data: .points([DataPoint(10, 15), DataPoint(15, 10)]),
        pointRadius: .constant(10),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        label: 'dataset1',
      ),
    ],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
  ),
  description: 'showLine option should draw a line if true',
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 256)),
  run: (chart) {
    chart.options['showLine'] = true;
    chart.update();
  },
);
