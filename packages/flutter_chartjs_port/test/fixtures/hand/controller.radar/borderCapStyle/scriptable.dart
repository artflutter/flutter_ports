// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/borderCapStyle/scriptable.js (MIT, Chart.js Contributors).
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
        data: <num?>[null, 3, 3],
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-flutter-stroke-enums, the Flutter enum.
          'borderCapStyle': (ScriptableContext ctx) {
            final index = jsToNumber(ctx.datasetIndex ?? undefined)
                .remainder(2);
            return index == 0
                ? StrokeCap.round
                : index == 1
                ? StrokeCap.square
                : StrokeCap.butt;
          },
        },
      ),
      RadarDataset(
        // option in element (fallback)
        data: <num?>[null, 2, 2],
      ),
      RadarDataset(
        // option in element (fallback)
        data: <num?>[null, 1, 1],
      ),
    ],
    labels: <Object>[0, 1, 2],
    elements: ChartElements(
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0xFFFF0000)),
        borderWidth: 32,
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
        extra: <String, Object?>{
          'borderCapStyle': (ScriptableContext ctx) {
            final index = jsToNumber(ctx.datasetIndex ?? undefined)
                .remainder(3);
            return index == 0
                ? StrokeCap.round
                : index == 1
                ? StrokeCap.square
                : StrokeCap.butt;
          },
        },
      ),
      point: PointElementStyle(radius: 10),
    ),
    padding: const EdgeInsets.all(32),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      RadialLinearAxis(display: ScaleDisplay.off, beginAtZero: true),
    ],
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
  },
);
