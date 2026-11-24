// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/vertical.js (MIT, Chart.js Contributors).
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
  raw(
    ChartConfig(
      datasets: [
        LineDataset(
          data: .points([
            DataPoint(12, 1),
            DataPoint(14, 3),
            DataPoint(20, 4),
            DataPoint(13, 6),
            DataPoint(18, 9),
          ]),
          borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          fill: FillTarget.none,
        ),
        LineDataset(
          data: .points([
            DataPoint(22.5, 1),
            DataPoint(23.5, 3),
            DataPoint(34, 4),
            DataPoint(17, 6),
            DataPoint(22.5, 9),
          ]),
          // DIVERGES(chartjs): adapt-fill-target-objects, the target
          // value.
          fill: FillTarget.toPrevious,
          borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
          backgroundColor: .constant(
            ChartPaint.solid(Color.fromRGBO(255, 200, 0, 0.5)),
          ),
        ),
      ],
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      indexAxis: const YAxis(),
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
      disabledPlugins: [PluginOff<LegendPlugin>()],
    ),
    <String, Object?>{'radius': 0},
  ),
);
