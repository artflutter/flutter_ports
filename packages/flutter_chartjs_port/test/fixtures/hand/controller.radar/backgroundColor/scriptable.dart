// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/backgroundColor/scriptable.js (MIT, Chart.js Contributors).
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
        backgroundColor: .resolver((ctx) {
          final index = ctx.index;
          return index == 0
              ? ChartPaint.solid(Color(0xFFFF0000))
              : index == 1
              ? ChartPaint.solid(Color(0xFF00FF00))
              : ChartPaint.solid(Color(0xFFFF00FF));
        }),
      ),
      RadarDataset(
        // option in element (fallback)
        data: <num?>[4, -5, -10, null, 10, 5],
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    elements: ChartElements(
      line: LineElementStyle(
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toOrigin,
        extra: <String, Object?>{
          'backgroundColor': (ScriptableContext ctx) {
            final index = ctx.index;
            return index == 0
                ? ChartPaint.solid(Color(0xFFFF0000))
                : index == 1
                ? ChartPaint.solid(Color(0xFF00FF00))
                : ChartPaint.solid(Color(0xFFFF00FF));
          },
        },
      ),
      point: PointElementStyle(
        backgroundColor: ChartPaint.solid(Color(0xFF0000FF)),
        radius: 10,
      ),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      RadialLinearAxis(display: ScaleDisplay.off, min: -15),
    ],
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    extra: <String, Object?>{
      'plugins': <String, Object?>{'filler': true},
    },
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
  },
);
