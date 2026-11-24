// Ported from Chart.js v4.6.1 test/fixtures/controller.line/radius/scriptable-to-value.js (MIT, Chart.js Contributors).
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
FixtureConfig fixture() => FixtureConfig.typed(
  raw(
    ChartConfig(
      datasets: [
        LineDataset(data: .values(<num?>[12, 19, 3])),
      ],
      labels: <Object>['A', 'B', 'C'],
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
    ),
    <String, Object?>{
      'animation': <String, Object?>{'duration': 0},
      'backgroundColor': ChartPaint.solid(Color(0xFFFF0000)),
      'radius': () => 20,
    },
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
  run: (chart) {
    chart.options['radius'] = 5;
    chart.update();
  },
);
