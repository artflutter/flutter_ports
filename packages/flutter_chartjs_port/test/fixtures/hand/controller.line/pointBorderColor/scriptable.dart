// Ported from Chart.js v4.6.1 test/fixtures/controller.line/pointBorderColor/scriptable.js (MIT, Chart.js Contributors).
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
        // option in dataset
        data: .values(<num?>[0, 5, 10, null, -10, -5]),
        pointBorderColor: .resolver((ctx) {
          final value = jsOrZero(
            jsGet(jsGet(ctx.dataset, 'data'), ctx.dataIndex),
          );
          return value > 8
              ? ChartPaint.solid(Color(0xFFFF0000))
              : value > 0
              ? ChartPaint.solid(Color(0xFF00FF00))
              : value > -8
              ? ChartPaint.solid(Color(0xFF0000FF))
              : ChartPaint.solid(Color(0xFFFF00FF));
        }),
      ),
      LineDataset(
        // option in element (fallback)
        data: .values(<num?>[4, -5, -10, null, 10, 5]),
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    elements: ChartElements(
      line: LineElementStyle(fill: FillTarget.none),
      point: raw(PointElementStyle(radius: 10), <String, Object?>{
        'borderColor': (ScriptableContext ctx) {
          final value = jsOrZero(
            jsGet(jsGet(ctx.dataset, 'data'), ctx.dataIndex),
          );
          return value > 8
              ? ChartPaint.solid(Color(0xFFFF00FF))
              : value > 0
              ? ChartPaint.solid(Color(0xFF0000FF))
              : value > -8
              ? ChartPaint.solid(Color(0xFFFF0000))
              : ChartPaint.solid(Color(0xFF00FF00));
        },
      }),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off, beginAtZero: true),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
