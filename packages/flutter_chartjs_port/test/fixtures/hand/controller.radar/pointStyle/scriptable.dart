// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/pointStyle/scriptable.js (MIT, Chart.js Contributors).
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
      RadarDataset(
        // option in dataset
        data: <num?>[0, 5, 10, null, -10, -5],
        pointBackgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        pointBorderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        // DIVERGES(chartjs): adapt-point-style-objects, the style classes.
        pointStyle: .resolver((ctx) {
          final value = jsOrZero(
            jsGet(jsGet(ctx.dataset, 'data'), ctx.dataIndex),
          );
          return value > 8
              ? const RectPointStyle()
              : value > 0
              ? const StarPointStyle()
              : value > -8
              ? const CrossPointStyle()
              : const TrianglePointStyle();
        }),
      ),
      RadarDataset(
        // option in element (fallback)
        data: <num?>[4, -5, -10, null, 10, 5],
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    elements: ChartElements(
      line: LineElementStyle(fill: FillTarget.none),
      point: PointElementStyle(
        backgroundColor: ChartPaint.solid(Color(0xFF0000FF)),
        borderColor: ChartPaint.solid(Color(0xFF0000FF)),
        radius: 10,
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-point-style-objects, the style classes.
          'pointStyle': (ScriptableContext ctx) {
            final value = jsOrZero(
              jsGet(jsGet(ctx.dataset, 'data'), ctx.dataIndex),
            );
            return value > 8
                ? const TrianglePointStyle()
                : value > 0
                ? const CrossPointStyle()
                : value > -8
                ? const StarPointStyle()
                : const RectPointStyle();
          },
        },
      ),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      RadialLinearAxis(display: ScaleDisplay.off, min: -15),
    ],
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
  },
);
