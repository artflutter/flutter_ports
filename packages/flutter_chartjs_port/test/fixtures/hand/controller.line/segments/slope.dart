// Ported from Chart.js v4.6.1 test/fixtures/controller.line/segments/slope.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-line-segment-style, a LineSegmentStyle.
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() {
  // Upstream: function slope({p0, p1}). `p0` and `p1` are point elements:
  // `x` and `y` are their number properties (Chart.js ADR 0017).
  double slope(ScriptableLineSegmentContext ctx) {
    final p0 = ctx.p0;
    final p1 = ctx.p1;
    return (p0.y - p1.y) / (p1.x - p0.x);
  }

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        LineDataset(
          data: .values(<num?>[1, 2, 3, 3, 2, 1]),
          borderColor: .constant(ChartPaint.solid(Color(0xFF000000))),
          segment: LineSegmentStyle(
            borderColor: (ctx) => slope(ctx) > 0
                ? const ChartPaint.solid(Color.fromRGBO(0, 128, 0, 1))
                : slope(ctx) < 0
                ? const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1))
                : null,
            borderDash: (ctx) => slope(ctx) < 0 ? <double>[5, 5] : null,
          ),
        ),
      ],
      labels: <Object>['a', 'b', 'c', 'd', 'e', 'f'],
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
    ),
  );
}
