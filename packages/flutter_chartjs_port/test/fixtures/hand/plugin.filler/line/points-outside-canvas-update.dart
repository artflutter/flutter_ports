// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/points-outside-canvas-update.js (MIT, Chart.js Contributors).
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
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The write `chart.scales.x.options.min = 5` of the `run` hook is the
/// write through `operator []=` of the option resolver, the `set` trap of
/// upstream.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        data: .points([
          DataPoint(0, 3),
          DataPoint(2, -3),
          DataPoint(4, 0),
          DataPoint(6, 5),
          DataPoint(8, -5),
          DataPoint(10, 0),
        ]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toOrigin,
      ),
    ],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    disabledPlugins: [PluginOff<LegendPlugin>(), PluginOff<TitlePlugin>()],
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/8699',
  options: <String, Object?>{
    'run': (Chart chart) {
      chart.scales['x']!.optionsView['min'] = 5;
      chart.update();
    },
  },
);
