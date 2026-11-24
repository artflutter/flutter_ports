// Ported from Chart.js v4.6.1 test/fixtures/core.interaction/drawActiveElementsOnTop-false.js (MIT, Chart.js Contributors).
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

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `jasmine.triggerMouseEvent` (:38) is [triggerMouseEvent] of the harness.
/// The point is a Map with the upstream keys.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BubbleDataset(
        data: [DataPoint.bubble(1, 1, 80), DataPoint.bubble(1, 1, 20)],
        backgroundColor: .resolver(
          (ctx) => ctx.dataIndex == 1
              ? ChartPaint.solid(Color(0xFFFF0000))
              : ChartPaint.solid(Color(0xFF0000FF)),
        ),
        hoverBackgroundColor: .constant(ChartPaint.solid(Color(0xFFFFFF00))),
        hoverRadius: 0,
        extra: <String, Object?>{'drawActiveElementsOnTop': false},
      ),
    ],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    disabledPlugins: [PluginOff<TooltipPlugin>(), PluginOff<LegendPlugin>()],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 256)),
  run: (chart) async {
    final point = chart.getDatasetMeta(0).data[0];
    await triggerMouseEvent(chart, 'click', <String, Object?>{
      'y': point.y,
      'x': point.x + 25,
    });
  },
);
