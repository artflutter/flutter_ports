// Ported from Chart.js v4.6.1 test/fixtures/controller.line/issue-8902.js (MIT, Chart.js Contributors).
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
      LineDataset(
        borderColor: .constant(ChartPaint.solid(Color(0xFF4BC0C0))),
        extra: <String, Object?>{
          'data': <Object?>[65, 59, double.nan, 48, 56, 57, 40],
        },
      ),
    ],
    labels: <Object>[1, 2, 3, 4, 5, 6, 7, 8],
    scales: [LinearAxis(CartesianAxis.x, min: 1, max: 3)],
    extra: <String, Object?>{'plugins': false},
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/8902',
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
);
