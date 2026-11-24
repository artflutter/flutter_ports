// Ported from Chart.js v4.6.1 test/fixtures/controller.line/segments/range.js (MIT, Chart.js Contributors).
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
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() {
  // `ctx[p].parsed[axis]`: `ctx.p0` and `ctx.p1` are point elements, read by
  // name (Chart.js ADR 0017, section 5). The parsed value is a number.
  double parsed(ScriptableLineSegmentContext ctx, String p, String axis) =>
      jsToNumber(
        jsGet(((p == 'p0' ? ctx.p0 : ctx.p1) as Element)['parsed'], axis),
      );

  // A destructuring default applies only when the property is undefined.
  double prop(Object? range, String key, double fallback) {
    final value = jsGet(range, key);
    return identical(value, undefined) ? fallback : jsToNumber(value);
  }

  // Upstream: function x(ctx, {min = -Infinity, max = Infinity}).
  bool x(ScriptableLineSegmentContext ctx, Object? range) {
    final min = prop(range, 'min', double.negativeInfinity);
    final max = prop(range, 'max', double.infinity);
    return (parsed(ctx, 'p0', 'x') >= min || parsed(ctx, 'p1', 'x') >= min) &&
        (parsed(ctx, 'p0', 'x') < max && parsed(ctx, 'p1', 'x') < max);
  }

  // Upstream: function y(ctx, {min = -Infinity, max = Infinity}).
  bool y(ScriptableLineSegmentContext ctx, Object? range) {
    final min = prop(range, 'min', double.negativeInfinity);
    final max = prop(range, 'max', double.infinity);
    return (parsed(ctx, 'p0', 'y') >= min || parsed(ctx, 'p1', 'y') >= min) &&
        (parsed(ctx, 'p0', 'y') < max || parsed(ctx, 'p1', 'y') < max);
  }

  bool xy(ScriptableLineSegmentContext ctx, Object? xr, Object? yr) {
    return x(ctx, xr) && y(ctx, yr);
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
            DataPoint(6, 7),
            DataPoint(7, 8),
          ]),
          borderColor: .constant(ChartPaint.solid(Color(0xFF000000))),
          segment: LineSegmentStyle(
            borderColor: (ctx) => x(ctx, <String, Object?>{'min': 3, 'max': 4})
                ? const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1))
                : y(ctx, <String, Object?>{'min': 5})
                ? const ChartPaint.solid(Color.fromRGBO(0, 128, 0, 1))
                : xy(
                    ctx,
                    <String, Object?>{'min': 0},
                    <String, Object?>{'max': 1},
                  )
                ? const ChartPaint.solid(Color.fromRGBO(0, 0, 255, 1))
                : null,
            borderDash: (ctx) =>
                x(ctx, <String, Object?>{'min': 3, 'max': 4}) ||
                    y(ctx, <String, Object?>{'min': 5})
                ? <double>[5, 5]
                : null,
          ),
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
