// Ported from Chart.js v4.6.1 test/fixtures/core.layouts/scriptable.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  raw(
    ChartConfig(
      datasets: [
        LineDataset(data: .values(<num?>[10, 5, 0, 25, 78, -10])),
      ],
      labels: <Object>['tick1', 'tick2', 'tick3', 'tick4', 'tick5', 'tick6'],
      scales: [
        CategoryAxis(
          CartesianAxis.x,
          ticks: AxisTicks(maxRotation: 0, autoSkip: false),
        ),
        LinearAxis(
          CartesianAxis.y,
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          position: ChartPosition.right,
        ),
      ],
      disabledPlugins: [PluginOff<LegendPlugin>()],
    ),
    <String, Object?>{
      'layout': <String, Object?>{
        'padding': (ContextObject ctx) {
          // 10% padding
          final horizontalPadding = (ctx.chart as Chart).width * 0.1;
          final verticalPadding = (ctx.chart as Chart).height * 0.1;
          return EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          );
        },
      },
    },
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 150)),
);
