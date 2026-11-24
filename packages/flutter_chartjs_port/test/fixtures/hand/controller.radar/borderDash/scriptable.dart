// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/borderDash/scriptable.js (MIT, Chart.js Contributors).
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
      RadarDataset(
        // option in dataset
        data: <num?>[0, 5, 10, null, -10, -5],
        extra: <String, Object?>{
          'borderDash': (ScriptableContext ctx) {
            return ctx.datasetIndex == 0 ? <Object?>[5] : <Object?>[10];
          },
        },
      ),
      RadarDataset(
        // option in element (fallback)
        data: <num?>[4, -5, -10, null, 10, 5],
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    elements: ChartElements(
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0xFF00FF00)),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toOrigin,
        extra: <String, Object?>{
          'borderDash': (ScriptableContext ctx) {
            return ctx.datasetIndex == 0 ? <Object?>[5] : <Object?>[10];
          },
        },
      ),
      point: PointElementStyle(radius: 10),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      RadialLinearAxis(display: ScaleDisplay.off, min: -15),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
);
