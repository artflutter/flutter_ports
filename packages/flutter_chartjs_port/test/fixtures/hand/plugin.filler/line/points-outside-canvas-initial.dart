// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/points-outside-canvas-initial.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
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
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off, min: 5),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    disabledPlugins: [PluginOff<LegendPlugin>(), PluginOff<TitlePlugin>()],
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/8699',
);
