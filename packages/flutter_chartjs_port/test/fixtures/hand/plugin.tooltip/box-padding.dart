// Ported from Chart.js v4.6.1 test/fixtures/plugin.tooltip/box-padding.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

import '../../fixture_events.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The inline `afterDraw` gives the chart event of the raw `mousemove` at
/// each point ([fixtureMouseMove]) to `chart._handleEvent` (the `handleEvent`
/// of [Chart]) and to the tooltip, and draws the tooltip. The canvas of the
/// harness is at the origin of its host: `canvas.getBoundingClientRect()`
/// gives the left and the top 0 (row `harness-fixture-sources`). The
/// tooltip is `chart.tooltip` cast to [Tooltip] (Chart.js ADR 0039, section
/// 1).
FixtureConfig fixture() {
  final data = <Object?>[];
  for (var x = 0; x < 3; x++) {
    for (var y = 0; y < 3; y++) {
      data.add(<String, Object?>{'x': x, 'y': y});
    }
  }

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        raw(
          ScatterDataset(
            backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          ),
          <String, Object?>{'data': data, 'radius': 1, 'hoverRadius': 0},
        ),
      ],
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
      pluginOptions: [
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        TooltipOptions(
          // DIVERGES(chartjs): adapt-interaction-mode-objects, the mode.
          mode: const PointInteractionMode(),
          intersect: true,
          // spriteText: use white background to hide any gaps between fonts
          // DIVERGES(chartjs): adapt-direct-colors, the native paint.
          backgroundColor: const ChartPaint.solid(Color(0xFFFFFFFF)),
          // DIVERGES(chartjs): adapt-direct-colors, the native paint.
          borderColor: const ChartPaint.solid(Color(0xFF000000)),
          borderWidth: 1,
          callbacks: TooltipCallbacks(label: (tooltip, arg) => ['label']),
          boxPadding: 30,
        ),
      ],
      disabledPlugins: [
        PluginOff<LegendPlugin>(),
        PluginOff<TitlePlugin>(),
        PluginOff<FillerPlugin>(),
      ],
      plugins: [
        // DIVERGES(chartjs): adapt-typed-plugins, a Plugin; upstream has no id.
        Plugin<Object?>(
          id: 'inline',
          afterDraw: (chart, _, _) {
            // const canvas = chart.canvas;
            // const rect = canvas.getBoundingClientRect();
            final meta = chart.getDatasetMeta(0);

            for (var i = 0; i < data.length; i++) {
              final point = meta.data[i];
              // DIVERGES(chartjs): harness-fixture-sources, the chart event.
              final event = fixtureMouseMove(point);
              (chart as Chart).handleEvent(event);
              (chart.tooltip! as Tooltip)
                ..handleEvent(event)
                ..draw(chart.ctx!);
            }
          },
        ),
      ],
    ),
    options: AcquireOptions(canvas: HarnessCanvas(width: 500, height: 400)),
  );
}
