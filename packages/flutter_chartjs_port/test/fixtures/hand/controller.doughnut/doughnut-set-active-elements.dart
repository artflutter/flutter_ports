// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-set-active-elements.js (MIT, Chart.js Contributors).
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
        data: <num?>[34, 33, 17, 16],
        backgroundColor: .indexed(<ChartPaint>[
          ChartPaint.solid(Color(0xFFD92323)),
          ChartPaint.solid(Color(0xFFE45757)),
          ChartPaint.solid(Color(0xFFED8D8D)),
          ChartPaint.solid(Color(0xFFF5C4C4)),
        ]),
      ),
    ],
    events: <String>[],
    extra: <String, Object?>{
      // for easier saving of the fixture only
      'borderWidth': 0,
      'hoverBorderWidth': 4,
      'hoverBorderColor': ChartPaint.solid(Color(0xFF000000)),
      // DIVERGES(chartjs): adapt-length-objects, the length class.
      'cutout': const PercentRadius(80),
    },
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/9248',
  options: <String, Object?>{
    'run': (Chart chart) {
      chart
        ..setActiveElements([const ActiveElement(datasetIndex: 0, index: 1)])
        ..update();
    },
  },
);
