// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/backgroundColor/scriptable.js (MIT, Chart.js Contributors).
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
      DoughnutDataset(
        // option in dataset
        data: <num?>[0, 2, 4, null, 6, 8],
        backgroundColor: .resolver((ctx) {
          final value = jsOrZero(
            jsGet(jsGet(ctx.dataset, 'data'), ctx.dataIndex),
          );
          return value > 8
              ? ChartPaint.solid(Color(0xFFFF0000))
              : value > 6
              ? ChartPaint.solid(Color(0xFF00FF00))
              : value > 2
              ? ChartPaint.solid(Color(0xFF0000FF))
              : ChartPaint.solid(Color(0xFFFF00FF));
        }),
      ),
      DoughnutDataset(
        // option in element (fallback)
        data: <num?>[0, 2, 4, null, 6, 8],
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    elements: ChartElements(
      arc: ArcElementStyle(
        extra: <String, Object?>{
          'backgroundColor': (ScriptableContext ctx) {
            final value = jsOrZero(
              jsGet(jsGet(ctx.dataset, 'data'), ctx.dataIndex),
            );
            return value > 8
                ? ChartPaint.solid(Color(0xFFFF0000))
                : value > 6
                ? ChartPaint.solid(Color(0xFF00FF00))
                : value > 2
                ? ChartPaint.solid(Color(0xFF0000FF))
                : ChartPaint.solid(Color(0xFFFF00FF));
          },
        },
      ),
    ),
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
);
