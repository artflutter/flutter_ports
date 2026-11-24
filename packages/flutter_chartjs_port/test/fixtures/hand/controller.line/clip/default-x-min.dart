// Ported from Chart.js v4.6.1 test/fixtures/controller.line/clip/default-x-min.json (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      ScatterDataset(
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        data: .points([
          DataPoint(-5.0, 5.0),
          DataPoint(-4.0, 6.0),
          DataPoint(-3.0, 7.0),
          DataPoint(-2.0, 6.0),
          DataPoint(-1.0, 5.0),
          DataPoint(0.0, 4.0),
          DataPoint(1.0, 3.0),
          DataPoint(2.0, 2.0),
          DataPoint(3.0, 5.0),
          DataPoint(4.0, 7.0),
          DataPoint(5.0, 9.0),
        ]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
        showLine: true,
        borderWidth: 20,
        pointRadius: .constant(0),
      ),
    ],
    responsive: false,
    scales: [
      LinearAxis(CartesianAxis.x, min: -2, ticks: AxisTicks(display: false)),
      LinearAxis(CartesianAxis.y, ticks: AxisTicks(display: false)),
    ],
    padding: const EdgeInsets.all(24),
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
