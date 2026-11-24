// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-offset.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      DoughnutDataset(
        data: <num?>[12.0, 4.0, 6.0],
        backgroundColor: .indexed(<ChartPaint>[
          ChartPaint.solid(Color(0xFFFF0000)),
          ChartPaint.solid(Color(0xFF0000FF)),
          ChartPaint.solid(Color(0xFFFFFF00)),
        ]),
      ),
    ],
    labels: <Object>['Red', 'Blue', 'Yellow'],
    padding: const EdgeInsets.all(50),
    extra: <String, Object?>{'offset': 40.0},
  ),
);
