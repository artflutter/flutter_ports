// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/pointBorderWidth/scriptable.js (MIT, Chart.js Contributors).
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
        pointBorderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        extra: <String, Object?>{
          'pointBorderWidth': (ScriptableContext ctx) {
            final value = jsOrZero(
              jsGet(jsGet(ctx.dataset, 'data'), ctx.dataIndex),
            );
            return value > 4
                ? 10
                : value > -4
                ? 5
                : 2;
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
      line: LineElementStyle(fill: FillTarget.none),
      point: PointElementStyle(
        borderColor: ChartPaint.solid(Color(0xFFFF0000)),
        radius: 10,
        extra: <String, Object?>{
          'borderWidth': (ScriptableContext ctx) {
            final value = jsOrZero(
              jsGet(jsGet(ctx.dataset, 'data'), ctx.dataIndex),
            );
            return value > 4
                ? 2
                : value > -4
                ? 5
                : 10;
          },
        },
      ),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      RadialLinearAxis(display: ScaleDisplay.off, min: -15),
    ],
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
  },
);
