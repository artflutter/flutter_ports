// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/minBarLength/vertical.js (MIT, Chart.js Contributors).
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
        data: .values(<num?>[0, -0.01, 0.01, 30, -30]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFF000000))),
        borderWidth: 4,
        minBarLength: 20,
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-border-skipped-enum, the enum value.
          'borderSkipped': (ScriptableContext ctx) =>
              ctx.raw == 0 ? false : BorderSkippedEdge.start,
        },
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      LinearAxis(CartesianAxis.y, ticks: AxisTicks(display: false)),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
);
