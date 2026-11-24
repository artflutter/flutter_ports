// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/borderDashOffset/value.js (MIT, Chart.js Contributors).
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
        data: <num?>[1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        // DIVERGES(chartjs): adapt-dash-lists, a list of doubles.
        borderDash: <double>[20],
        extra: <String, Object?>{'borderDashOffset': 5.0},
      ),
      RadarDataset(data: <num?>[0.0, 0.0, 0.0, 0.0, 0.0, 0.0]),
    ],
    labels: <Object>[0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
    elements: ChartElements(
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0xFF00FF00)),
        // DIVERGES(chartjs): adapt-dash-lists, a list of doubles.
        borderDash: <double>[20],
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
        borderDashOffset: 0,
      ),
      point: PointElementStyle(radius: 10),
    ),
    padding: const EdgeInsets.all(32),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      RadialLinearAxis(display: ScaleDisplay.off, min: -1),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
);
