// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/baseLine/top.js (MIT, Chart.js Contributors).
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
///
/// `context.tick` is a `Tick` of core.scale.dart, a class and not a Map:
/// the color function reads its field `value`.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BarDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFAAFFCC))),
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        borderWidth: 1,
        data: .values(<num?>[-1, -2]),
      ),
    ],
    labels: <Object>['a', 'b'],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      LinearAxis(
        CartesianAxis.y,
        ticks: AxisTicks(display: false),
        grid: AxisGrid(
          lineWidth: 5,
          tickLength: 0,
          extra: <String, Object?>{
            'color': (ScriptableScaleContext context) {
              return context.tick!.value == 0
                  ? ChartPaint.solid(Color(0xFFFF0000))
                  : ChartPaint.solid(Color(0x00000000));
            },
            'borderWidth': 0,
          },
        ),
      ),
    ],
    maintainAspectRatio: false,
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'width': 128, 'height': 128},
  },
);
