// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-full-to-semi.js (MIT, Chart.js Contributors).
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
  ChartConfig(
    datasets: [
      DoughnutDataset(
        label: 'Set 1',
        data: <num?>[50, 50, 25],
        backgroundColor: .indexed(<ChartPaint>[
          ChartPaint.solid(Color(0xFFBF616A)),
          ChartPaint.solid(Color(0xFFD08770)),
          ChartPaint.solid(Color(0xFFEBCB8B)),
        ]),
        borderWidth: 0,
      ),
      DoughnutDataset(
        label: 'Se1 2',
        data: <num?>[50, 50, 25],
        backgroundColor: .indexed(<ChartPaint>[
          ChartPaint.solid(Color(0xFFBF616A)),
          ChartPaint.solid(Color(0xFFD08770)),
          ChartPaint.solid(Color(0xFFEBCB8B)),
        ]),
        borderWidth: 0,
      ),
    ],
    extra: <String, Object?>{'rotation': -90},
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/9832',
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
  run: (chart) {
    chart.options['circumference'] = 180;
    chart.update();
  },
);
