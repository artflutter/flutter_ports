// Ported from Chart.js v4.6.1 test/fixtures/controller.bubble/padding-update.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BubbleDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        data: [DataPoint.bubble(12, 54, 22.4)],
      ),
      BubbleDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        data: [DataPoint.bubble(18, 38, 25)],
      ),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 256)),
  run: (chart) {
    chart.update();
  },
);
