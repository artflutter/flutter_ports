// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/segments/alignToPixels.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-line-segment-style, a LineSegmentStyle.
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

// `ctx.p0` is a point element. `ctx.p0.parsed` is the access by name of the
// element (Chart.js ADR 0017, section 5): `jsGet` gives `undefined` for an
// element.

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        data: .points([
          DataPoint(0, 0),
          DataPoint(1, 20),
          DataPoint(1.00001, 30),
          DataPoint(2, 100),
          DataPoint(2.00001, 100),
        ]),
        backgroundColor: .constant(ChartPaint.solid(Color(0x70FF0000))),
        borderColor: .constant(ChartPaint.solid(Color(0xFF000000))),
        segment: LineSegmentStyle(
          borderDash: (ctx) =>
              jsToNumber(jsGet((ctx.p0 as Element)['parsed'], 'x')) > 1
              ? <double>[10, 5]
              : null,
        ),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toOrigin,
        extra: <String, Object?>{'radius': 0},
      ),
    ],
    scales: [
      LinearAxis(
        CartesianAxis.x,
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        display: ScaleDisplay.off,
        extra: <String, Object?>{'alignToPixels': true},
      ),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    disabledPlugins: [PluginOff<LegendPlugin>()],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 300, height: 240)),
);
