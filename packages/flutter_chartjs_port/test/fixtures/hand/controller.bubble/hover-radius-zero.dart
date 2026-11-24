// Ported from Chart.js v4.6.1 test/fixtures/controller.bubble/hover-radius-zero.js (MIT, Chart.js Contributors).
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
      BubbleDataset(
        extra: <String, Object?>{
          'data': <Object?>[
            <Object?>[1, 1],
            <Object?>[1, 2],
            <Object?>[1, 3, 20],
            <Object?>[1, 4, 20],
          ],
        },
      ),
      BubbleDataset(
        extra: <String, Object?>{
          'data': <Object?>[1, 2, 3, 4],
        },
      ),
      BubbleDataset(
        extra: <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 3, 'y': 1},
            <String, Object?>{'x': 3, 'y': 2},
            <String, Object?>{'x': 3, 'y': 3, 'r': 15},
            <String, Object?>{'x': 3, 'y': 4, 'r': 15},
          ],
        },
      ),
    ],
    labels: <Object>[2, 2, 2, 2],
    events: <String>[],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(
        CartesianAxis.x,
        display: ScaleDisplay.off,
        bounds: ScaleBounds.data,
      ),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    padding: const EdgeInsets.all(24),
    extra: <String, Object?>{
      'radius': 10,
      'hoverRadius': 0,
      'backgroundColor': ChartPaint.solid(Color(0xFF0000FF)),
      'hoverBackgroundColor': ChartPaint.solid(Color(0xFFFF0000)),
    },
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 256)),
  run: (chart) {
    chart
      ..setActiveElements([
        const ActiveElement(datasetIndex: 0, index: 1),
        const ActiveElement(datasetIndex: 0, index: 2),
        const ActiveElement(datasetIndex: 1, index: 1),
        const ActiveElement(datasetIndex: 1, index: 2),
        const ActiveElement(datasetIndex: 2, index: 1),
        const ActiveElement(datasetIndex: 2, index: 2),
      ])
      ..update();
  },
);
