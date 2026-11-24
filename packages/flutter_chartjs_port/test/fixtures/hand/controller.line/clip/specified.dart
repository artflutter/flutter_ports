// Ported from Chart.js v4.6.1 test/fixtures/controller.line/clip/specified.json (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The upstream config, with native padding and clip values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
// DIVERGES(chartjs): adapt-chart-clip-option, the clip class.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      ScatterDataset(
        showLine: true,
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        data: .points([DataPoint(-4.0, -4.0), DataPoint(4.0, 4.0)]),
        clip: ChartClip.none,
      ),
      ScatterDataset(
        showLine: true,
        borderColor: .constant(ChartPaint.solid(Color(0xFF008000))),
        data: .points([DataPoint(-4.0, -5.0), DataPoint(4.0, 3.0)]),
        clip: const ChartClip.all(5),
      ),
      ScatterDataset(
        showLine: true,
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        data: .points([DataPoint(-4.0, -3.0), DataPoint(4.0, 5.0)]),
        clip: const ChartClip.all(-5),
      ),
      ScatterDataset(
        showLine: true,
        borderColor: .constant(ChartPaint.solid(Color(0xFFA52A2A))),
        data: .points([
          DataPoint(-3.0, -3.0),
          DataPoint(-1.0, 3.0),
          DataPoint(1.0, -2.0),
          DataPoint(2.0, 3.0),
        ]),
        clip: const ChartClip(top: 8, right: -20, bottom: -20),
      ),
    ],
    responsive: false,
    scales: [
      LinearAxis(
        CartesianAxis.x,
        min: -2,
        max: 2,
        ticks: AxisTicks(display: false),
      ),
      LinearAxis(
        CartesianAxis.y,
        min: -2,
        max: 2,
        ticks: AxisTicks(display: false),
      ),
    ],
    padding: const EdgeInsets.all(24),
    elements: ChartElements(
      line: LineElementStyle(fill: FillTarget.none, borderWidth: 20),
      point: PointElementStyle(radius: 0),
    ),
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
