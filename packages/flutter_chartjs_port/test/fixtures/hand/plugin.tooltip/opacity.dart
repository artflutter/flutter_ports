// Ported from Chart.js v4.6.1 test/fixtures/plugin.tooltip/opacity.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native paint inputs.
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

import '../../fixture_events.dart';

/// `module.exports` of the upstream file. Each call runs the module body:
/// the pattern canvas of the module and the gradient variable.
///
/// `createPattern(patternCanvas, 'repeat')` takes the image source of the
/// canvas layer, read at the place of the upstream call (`toImageSource()`
/// of `UiCanvasElement`). The inline `afterDraw` gives the chart event of
/// the raw `mousemove` at each point ([fixtureMouseMove]) to
/// `chart._handleEvent` (the `handleEvent` of [Chart]) and to the tooltip,
/// writes the opacity of the tooltip, and draws the tooltip. The canvas of
/// the harness is at the origin of its host: `canvas.getBoundingClientRect()`
/// gives the left and the top 0 (row `harness-fixture-sources`).
FixtureConfig fixture() {
  final patternCanvas = document.createElement<HTMLCanvasElement>('canvas');
  final patternContext = patternCanvas.getContext('2d')!;

  patternCanvas
    ..width = 6
    ..height = 6;
  patternContext
    ..fillStyle = const native_ui.Color(0xffff0000)
    ..fillRect(0, 0, 6, 6)
    ..fillStyle = const native_ui.Color(0xffffff00)
    ..fillRect(0, 0, 4, 4);

  final pattern = ChartPattern(
    (patternCanvas as UiCanvasElement).toImageSource().image,
  );

  ChartGradient? gradient;

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        LineDataset(
          data: .values(<num?>[8, 8, 8, 8, 8, 8, 7, 8, 8, 8, 8]),
          pointBorderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          pointBackgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
          showLine: false,
        ),
        LineDataset(
          label: '',
          data: .values(<num?>[4, 4, 4, 4, 4, 5, 3, 4, 4, 4, 4]),
          showLine: false,
          extra: <String, Object?>{
            'pointBorderColor': pattern,
            'pointBackgroundColor': pattern,
          },
        ),
        LineDataset(
          label: '',
          data: .values(<num?>[0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0]),
          showLine: false,
        ),
      ],
      labels: <Object>['', '', '', '', '', '', '', '', '', '', ''],
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
      elements: ChartElements(line: LineElementStyle(fill: FillTarget.none)),
      padding: const EdgeInsets.all(15),
      pluginOptions: [
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        TooltipOptions(
          // DIVERGES(chartjs): adapt-interaction-mode-objects, the mode.
          mode: const NearestInteractionMode(),
          intersect: false,
          callbacks: TooltipCallbacks(label: (tooltip, arg) => ['​']),
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
          beforeDatasetsUpdate: (chart, _, _) {
            gradient ??= const ChartGradient.linear(
              native_ui.Offset.zero,
              native_ui.Offset(512, 256),
              [native_ui.Color(0xffff0000), native_ui.Color(0xff0000ff)],
            );
            final datasets = chart.config.data['datasets']! as List<Object?>;
            // The dataset is a typed scope of the lowering: a write by name.
            jsSet(datasets[2], 'pointBorderColor', gradient);
            jsSet(datasets[2], 'pointBackgroundColor', gradient);

            return true;
          },
          afterDraw: (chart, _, _) {
            // var canvas = chart.canvas;
            // var rect = canvas.getBoundingClientRect();
            for (var i = 0; i < 3; ++i) {
              for (var j = 0; j < 11; ++j) {
                final point = chart.getDatasetMeta(i).data[j];
                // DIVERGES(chartjs): harness-fixture-sources, the chart event.
                final event = fixtureMouseMove(point);
                (chart as Chart).handleEvent(event);
                (chart.tooltip! as Tooltip)
                  ..handleEvent(event)
                  ..opacity = j / 10
                  ..draw(chart.ctx!);
              }
            }
          },
        ),
      ],
    ),
    options: <String, Object?>{
      'canvas': <String, Object?>{'height': 256, 'width': 512},
    },
  );
}
