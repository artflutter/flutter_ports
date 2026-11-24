// Ported from Chart.js v4.6.1 test/fixtures/core.scale/ticks/rotated-multi-line.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native paint inputs.
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  raw(
    ChartConfig(
      datasets: [
        LineDataset(data: .values(<num?>[12, 19, 3, 5, 2, 3])),
      ],
      labels: <Object>[
        <Object?>['Red', 'Red', 'Red', 'Red'],
        <Object?>['Blue', 'Blue', 'Blue', 'Blue'],
        <Object?>['Black', 'Black', 'Black', 'Black'],
        <Object?>['Green', 'Green', 'Green', 'Green'],
        <Object?>['Purple', 'Purple', 'Purple', 'Purple'],
        <Object?>[
          'Orange Orange',
          'Orange',
          'Orange',
          'Orange',
          'Orange Orange',
        ],
      ],
      disabledPlugins: [
        PluginOff<LegendPlugin>(),
        PluginOff<TooltipPlugin>(),
        PluginOff<FillerPlugin>(),
        PluginOff<TitlePlugin>(),
      ],
      plugins: [
        // DIVERGES(chartjs): adapt-typed-plugins, a Plugin; upstream has no id.
        Plugin<Object?>(
          id: 'inline',
          afterDraw: (chart, _, _) {
            // const ctx = chart.ctx; ctx.save(); ...
            chart.ctx!
              ..save()
              ..strokeStyle = const native_ui.Color(0xffff0000)
              ..strokeRect(0, 0, chart.width, chart.height)
              ..restore();
          },
        ),
      ],
    ),
    <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'category',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.bottom,
        },
        'x2': <String, Object?>{
          'type': 'category',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.top,
        },
      },
    },
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 610, height: 512)),
);
