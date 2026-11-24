// Ported from Chart.js v4.6.1 test/fixtures/scale.category/invalid-data.js (MIT, Chart.js Contributors).
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
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      raw(
        LineDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          borderWidth: 5,
        ),
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 'a', 'y': 1},
            <String, Object?>{'x': null, 'y': 1},
            <String, Object?>{'x': 2, 'y': 1},
            <String, Object?>{'x': undefined, 'y': 1},
            <String, Object?>{'x': 4, 'y': 1},
            <String, Object?>{'x': double.nan, 'y': 1},
            <String, Object?>{'x': 6, 'y': 1},
          ],
        },
      ),
    ],
    labels: <Object>['a', 'b', 'c', 'd', 'e', 'f', 'g'],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      CategoryAxis(CartesianAxis.x, grid: AxisGrid(display: false)),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 256)),
);
