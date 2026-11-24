// Ported from Chart.js v4.6.1 test/fixtures/controller.line/segments/spanGaps.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-line-segment-style, a LineSegmentStyle.
// ignore_for_file: file_names
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
import 'package:flutter_chartjs_port/chartjs.dart';

// `ctx.p1` is a point element. `ctx.p1.parsed` is the access by name of the
// element (Chart.js ADR 0017, section 5): `jsGet` gives `undefined` for an
// element.
double _p1x(ScriptableLineSegmentContext ctx) =>
    jsToNumber(jsGet((ctx.p1 as Element)['parsed'], 'x'));

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  raw(
    ChartConfig(
      datasets: [
        LineDataset(
          data: .values(<num?>[1, 3, null, null, 2, 1]),
          segment: LineSegmentStyle(
            borderColor: (ctx) => _p1x(ctx) > 2
                ? const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1))
                : null,
            borderDash: (ctx) => _p1x(ctx) > 3 ? <double>[6, 6] : null,
          ),
          spanGaps: true,
        ),
        LineDataset(
          data: .values(<num?>[0, 2, null, null, 1, 0]),
          segment: LineSegmentStyle(
            borderColor: (ctx) => _p1x(ctx) > 2
                ? const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1))
                : null,
            borderDash: (ctx) => _p1x(ctx) > 3 ? <double>[6, 6] : null,
          ),
          spanGaps: false,
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
    <String, Object?>{
      'borderColor': ChartPaint.solid(Color(0xFF000000)),
      'radius': 0,
    },
  ),
);
