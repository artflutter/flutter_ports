// Ported from Chart.js v4.6.1 test/fixtures/controller.line/segments/gradient.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-line-segment-style, a LineSegmentStyle.
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
FixtureConfig fixture() {
  ChartPaint getGradient(ScriptableLineSegmentContext context) {
    // Upstream: const {chart, p0, p1} = context;
    final p0 = context.p0 as Element;
    final p1 = context.p1 as Element;
    // Upstream: const {x: x0} = p0.getProps(['x'], true);
    final x0 = p0.getProps(const ['x'], true)['x'];
    // Upstream: const {x: x1} = p1.getProps(['x'], true);
    final x1 = p1.getProps(const ['x'], true)['x'];
    return ChartGradient.linear(
      Offset(jsToNumber(x0), 0),
      Offset(jsToNumber(x1), 0),
      [
        (jsGet(p0.options, 'backgroundColor')! as SolidChartPaint).color,
        (jsGet(p1.options, 'backgroundColor')! as SolidChartPaint).color,
      ],
    );
  }

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        LineDataset(
          data: .points([
            DataPoint(0, 0),
            DataPoint(1, 1),
            DataPoint(2, 2),
            DataPoint(3, 3),
            DataPoint(4, 4),
            DataPoint(5, 5),
            DataPoint(6, 6),
          ]),
          pointBackgroundColor: .indexed(<ChartPaint>[
            ChartPaint.solid(Color(0xFFFF0000)),
            ChartPaint.solid(Color(0xFFFFFF00)),
            ChartPaint.solid(Color(0xFF008000)),
            ChartPaint.solid(Color(0xFF008000)),
            ChartPaint.solid(Color(0xFF0000FF)),
            ChartPaint.solid(Color(0xFFFFC0CB)),
            ChartPaint.solid(Color(0xFF0000FF)),
          ]),
          pointBorderWidth: 0,
          pointRadius: .constant(10),
          borderWidth: 5,
          segment: LineSegmentStyle(borderColor: getGradient),
        ),
      ],
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
    ),
  );
}
