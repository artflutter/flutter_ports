// Ported from Chart.js v4.6.1 test/fixtures/controller.line/fill/scriptable.js (MIT, Chart.js Contributors).
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
///
/// `ctx.datasetIndex === 0 ? true : false` (:12, :26) is the comparison
/// itself: the result is the same boolean.
FixtureConfig fixture() => FixtureConfig.typed(
  raw(
    ChartConfig(
      datasets: [
        raw(
          LineDataset(
            // option in dataset
            data: .values(<num?>[-2, -6, -4, -8, -6, -10]),
            backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          ),
          <String, Object?>{
            // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
            'fill': (ScriptableContext ctx) {
              return ctx.datasetIndex == 0
                  ? FillTarget.toOrigin
                  : FillTarget.none;
            },
          },
        ),
        LineDataset(
          // option in element (fallback)
          data: .values(<num?>[0, 4, 2, 6, 4, 8]),
        ),
      ],
      labels: <Object>[0, 1, 2, 3, 4, 5],
      elements: ChartElements(
        line: raw(
          LineElementStyle(
            backgroundColor: ChartPaint.solid(Color(0xFF00FF00)),
          ),
          <String, Object?>{
            // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
            'fill': (ScriptableContext ctx) {
              return ctx.datasetIndex == 0
                  ? FillTarget.toOrigin
                  : FillTarget.none;
            },
          },
        ),
      ),
      padding: const EdgeInsets.all(32),
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
      disabledPlugins: [
        PluginOff<LegendPlugin>(),
        PluginOff<TitlePlugin>(),
        PluginOff<TooltipPlugin>(),
      ],
    ),
    <String, Object?>{
      'plugins': <String, Object?>{'filler': true},
    },
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
