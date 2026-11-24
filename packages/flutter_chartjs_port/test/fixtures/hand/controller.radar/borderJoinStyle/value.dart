// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/borderJoinStyle/value.js (MIT, Chart.js Contributors).
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

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      RadarDataset(
        data: <num?>[3.0, 3.0, null, 3.0],
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderJoinStyle: StrokeJoin.round,
      ),
      RadarDataset(
        data: <num?>[2.0, 2.0, null, 2.0],
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        borderJoinStyle: StrokeJoin.bevel,
      ),
      RadarDataset(data: <num?>[1.0, 1.0, null, 1.0]),
    ],
    labels: <Object>[0.0, 1.0, 2.0, 3.0],
    elements: ChartElements(
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0xFF00FF00)),
        borderJoinStyle: StrokeJoin.miter,
        borderWidth: 25,
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
        tension: 0,
      ),
    ),
    padding: const EdgeInsets.all(32),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      RadialLinearAxis(display: ScaleDisplay.off, beginAtZero: true),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
);
