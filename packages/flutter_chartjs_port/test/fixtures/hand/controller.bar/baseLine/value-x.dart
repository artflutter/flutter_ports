// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/baseLine/value-x.js (MIT, Chart.js Contributors).
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
        data: .values(<num?>[1, 3]),
      ),
    ],
    labels: <Object>['a', 'b'],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.y, display: ScaleDisplay.off),
      LinearAxis(
        CartesianAxis.x,
        ticks: AxisTicks(display: false),
        grid: AxisGrid(
          lineWidth: 5,
          tickLength: 0,
          extra: <String, Object?>{
            'color': (ScriptableScaleContext context) {
              return context.tick!.value == 2
                  ? ChartPaint.solid(Color(0xFFFF0000))
                  : ChartPaint.solid(Color(0x00000000));
            },
          },
        ),
      ),
    ],
    maintainAspectRatio: false,
    extra: <String, Object?>{'base': 2},
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'width': 128, 'height': 128},
  },
);
