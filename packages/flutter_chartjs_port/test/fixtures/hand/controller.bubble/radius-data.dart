// Ported from Chart.js v4.6.1 test/fixtures/controller.bubble/radius-data.js (MIT, Chart.js Contributors).
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
      raw(BubbleDataset(), <String, Object?>{
        'data': <Object?>[
          <String, Object?>{'x': 0, 'y': 5, 'r': 1},
          <String, Object?>{'x': 1, 'y': 4, 'r': 2},
          <String, Object?>{'x': 2, 'y': 3, 'r': 6},
          <String, Object?>{'x': 3, 'y': 2},
          <String, Object?>{'x': 4, 'y': 1, 'r': 2},
          <String, Object?>{'x': 5, 'y': 0, 'r': double.nan},
          <String, Object?>{'x': 6, 'y': -1, 'r': undefined},
          <String, Object?>{'x': 7, 'y': -2, 'r': null},
          <String, Object?>{'x': 8, 'y': -3, 'r': '4'},
          <String, Object?>{'x': 9, 'y': -4, 'r': '4px'},
        ],
      }),
    ],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    elements: ChartElements(
      point: PointElementStyle(
        backgroundColor: ChartPaint.solid(Color(0xFF444444)),
        radius: 10,
      ),
    ),
    padding: const EdgeInsets.only(left: 24, right: 24),
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 128)),
);
