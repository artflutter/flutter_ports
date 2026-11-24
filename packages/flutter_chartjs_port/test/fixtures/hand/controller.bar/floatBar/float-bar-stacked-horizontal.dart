// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/floatBar/float-bar-stacked-horizontal.json (MIT, Chart.js Contributors).
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
      raw(
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF6384))),
        ),
        <String, Object?>{
          'data': <Object?>[
            11,
            <Object?>[6, 2],
            <Object?>[-4, -7],
            -2,
          ],
        },
      ),
      raw(
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF36A2EB))),
        ),
        <String, Object?>{
          'data': <Object?>[
            <Object?>[1, 2],
            <Object?>[3, 4],
            <Object?>[-2, -3],
            <Object?>[1, 4],
          ],
        },
      ),
      raw(
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFFFFCE56))),
        ),
        <String, Object?>{
          'data': <Object?>[
            <Object?>[0, 1],
            <Object?>[1, 2],
            <Object?>[-2, -1],
            <Object?>[1, -7],
          ],
        },
      ),
    ],
    labels: <Object>['2030', '2034', '2038', '2042'],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    scales: [
      // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(
        CartesianAxis.x,
        display: ScaleDisplay.off,
        stacked: StackMode.on,
      ),
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
