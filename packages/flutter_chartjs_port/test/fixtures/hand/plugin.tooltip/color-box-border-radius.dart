// Ported from Chart.js v4.6.1 test/fixtures/plugin.tooltip/color-box-border-radius.js (MIT, Chart.js Contributors).
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

import '../../fixture_events.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The callback `labelColor` reads `tooltipItem.chart` through
/// `types.Chart`, and the style of the element with `jsGet`. The inline
/// `afterDraw` gives the chart event of the raw `mousemove` at the point
/// ([fixtureMouseMove]) to `chart._handleEvent` (the `handleEvent` of
/// [Chart]) and to the tooltip, and draws the tooltip. The canvas of the
/// harness is at the origin of its host: `canvas.getBoundingClientRect()`
/// gives the left and the top 0 (row `harness-fixture-sources`).
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        data: .values(<num?>[8, 7, 6, 5]),
        pointBorderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        pointBackgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        showLine: false,
      ),
    ],
    labels: <Object>['', '', '', ''],
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
        callbacks: TooltipCallbacks(
          label: (tooltip, arg) => ['​'],
          labelColor: (tooltip, tooltipItem) {
            final meta = tooltipItem.chart.getDatasetMeta(
              tooltipItem.datasetIndex,
            );
            final options = meta.controller!.getStyle(tooltipItem.dataIndex);
            return TooltipLabelStyle(
              borderColor: jsGet(options, 'borderColor')! as ChartPaint,
              backgroundColor: jsGet(options, 'backgroundColor')! as ChartPaint,
              borderWidth: 2,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
            );
          },
        ),
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
          final point = chart.getDatasetMeta(0).data[1];
          // DIVERGES(chartjs): harness-fixture-sources, the chart event.
          final event = fixtureMouseMove(point);
          (chart as Chart).handleEvent(event);
          (chart.tooltip! as Tooltip)
            ..handleEvent(event)
            ..draw(chart.ctx!);
        },
      ),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
