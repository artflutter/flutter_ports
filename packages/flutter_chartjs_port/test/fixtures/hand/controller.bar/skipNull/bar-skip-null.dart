// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/skipNull/bar-skip-null.js (MIT, Chart.js Contributors).
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
      BarDataset(
        data: .values(<num?>[5, 20, 1, 10]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
      ),
      BarDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        extra: <String, Object?>{
          'data': <Object?>[10, null, 1, undefined],
        },
      ),
    ],
    labels: <Object>[0, 1, 3, 4],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    datasetDefaults: [BarDataset(skipNull: true)],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
