// Ported from Chart.js v4.6.1 test/fixtures/element.line/skip/last.js (MIT, Chart.js Contributors).
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

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toOrigin,
        tension: 0,
        extra: <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 10},
            <String, Object?>{'x': 5, 'y': 0},
            <String, Object?>{'x': 15, 'y': -10},
            <String, Object?>{'x': double.nan, 'y': -5},
          ],
        },
      ),
    ],
    scales: [
      LinearAxis(
        CartesianAxis.x,
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        display: ScaleDisplay.off,
        min: 0,
        max: 20,
      ),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off, min: -15, max: 15),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
