// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/borderJoinStyle/scriptable.js (MIT, Chart.js Contributors).
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
        RadarDataset(
          // option in dataset
          data: <num?>[3, 3, null, 3],
          borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        ),
        <String, Object?>{
          // DIVERGES(chartjs): adapt-flutter-stroke-enums, the Flutter enum.
          'borderJoinStyle': (ScriptableContext ctx) {
            final index = jsToNumber(ctx.datasetIndex ?? undefined)
                .remainder(3);
            return index == 0
                ? StrokeJoin.round
                : index == 1
                ? StrokeJoin.miter
                : StrokeJoin.bevel;
          },
        },
      ),
      RadarDataset(
        // option in element (fallback)
        data: <num?>[2, 2, null, 2],
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
      ),
      RadarDataset(
        // option in element (fallback)
        data: <num?>[1, 1, null, 1],
      ),
    ],
    labels: <Object>[0, 1, 2, 3],
    elements: ChartElements(
      line: raw(
        LineElementStyle(
          borderColor: ChartPaint.solid(Color(0xFF00FF00)),
          borderWidth: 25,
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          fill: FillTarget.none,
          tension: 0,
        ),
        <String, Object?>{
          'borderJoinStyle': (ScriptableContext ctx) {
            final index = jsToNumber(ctx.datasetIndex ?? undefined)
                .remainder(3);
            return index == 0
                ? StrokeJoin.round
                : index == 1
                ? StrokeJoin.miter
                : StrokeJoin.bevel;
          },
        },
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
