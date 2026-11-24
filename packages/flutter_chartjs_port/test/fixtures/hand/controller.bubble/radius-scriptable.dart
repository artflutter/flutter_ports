// Ported from Chart.js v4.6.1 test/fixtures/controller.bubble/radius-scriptable.js (MIT, Chart.js Contributors).
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
          <String, Object?>{'x': 0, 'y': 0},
          <String, Object?>{'x': 1, 'y': 0},
          <String, Object?>{'x': 2, 'y': 0},
          <String, Object?>{'x': 3, 'y': 0},
          <String, Object?>{'x': 4, 'y': 0},
          <String, Object?>{'x': 5, 'y': 0},
        ],
        'radius': (ScriptableContext ctx) {
          return jsToNumber(
                jsGet(jsGet(jsGet(ctx.dataset, 'data'), ctx.dataIndex), 'x'),
              ) *
              4;
        },
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
      ),
    ),
    padding: const EdgeInsets.only(left: 24, right: 24),
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 128)),
);
