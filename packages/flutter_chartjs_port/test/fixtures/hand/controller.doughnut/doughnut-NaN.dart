// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-NaN.js (MIT, Chart.js Contributors).
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
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      raw(
        DoughnutDataset(
          backgroundColor: .indexed(<ChartPaint>[
            ChartPaint.solid(Color(0xCCFF6384)),
            ChartPaint.solid(Color(0xCC36A2EB)),
            ChartPaint.solid(Color(0xCCFFCE56)),
            ChartPaint.solid(Color(0xCC4BC0C0)),
            ChartPaint.solid(Color(0xCC9966FF)),
          ]),
          borderColor: .indexed(<ChartPaint>[
            ChartPaint.solid(Color(0xFFFF6384)),
            ChartPaint.solid(Color(0xFF36A2EB)),
            ChartPaint.solid(Color(0xFFFFCE56)),
            ChartPaint.solid(Color(0xFF4BC0C0)),
            ChartPaint.solid(Color(0xFF9966FF)),
          ]),
        ),
        <String, Object?>{
          'data': <Object?>[1, 5, double.nan, 50, 100],
        },
      ),
    ],
    labels: <Object>['A', 'B', 'C', 'D', 'E'],
  ),
);
