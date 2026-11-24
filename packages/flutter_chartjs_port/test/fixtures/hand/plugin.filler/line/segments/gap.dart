// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/segments/gap.js (MIT, Chart.js Contributors).
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

// `ctx.p0` and `ctx.p1` are point elements: `ctx.p0.skip || ctx.p1.skip`.

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      raw(
        LineDataset(
          borderColor: .constant(ChartPaint.solid(Color(0x00000000))),
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF000000))),
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          fill: FillTarget.toOrigin,
          segment: LineSegmentStyle(
            backgroundColor: (ctx) =>
                (ctx.p0.skip ?? false) || (ctx.p1.skip ?? false)
                ? const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1))
                : null,
          ),
          spanGaps: true,
        ),
        <String, Object?>{
          'data': <Object?>[1, 3, double.nan, double.nan, 2, 1],
        },
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
