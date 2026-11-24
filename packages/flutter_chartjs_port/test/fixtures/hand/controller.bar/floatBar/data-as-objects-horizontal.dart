// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/floatBar/data-as-objects-horizontal.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BarDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        extra: <String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'y': 'b',
              'x': <Object?>[2, 8],
            },
            <String, Object?>{
              'y': 'c',
              'x': <Object?>[2, 5],
            },
          ],
        },
      ),
      BarDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        extra: <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'y': 'a', 'x': 10},
            <String, Object?>{
              'y': 'c',
              'x': <Object?>[6, 10],
            },
          ],
        },
      ),
    ],
    labels: <Object>['a', 'b', 'c'],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off, min: 0),
      // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(
        CartesianAxis.y,
        display: ScaleDisplay.off,
        stacked: StackMode.on,
      ),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
