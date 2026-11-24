// Ported from Chart.js v4.6.1 test/fixtures/plugin.tooltip/point-style.js (MIT, Chart.js Contributors).
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
/// The inline `afterDraw` gives the chart event of the raw `mousemove` at
/// the point `i` of the dataset `i` ([fixtureMouseMove]) to
/// `chart._handleEvent` (the `handleEvent` of [Chart]) and to the tooltip,
/// and draws the tooltip. The canvas of the harness is at the origin of its
/// host: `canvas.getBoundingClientRect()` gives the left and the top 0 (row
/// `harness-fixture-sources`).
FixtureConfig fixture() {
  // DIVERGES(chartjs): adapt-point-style-objects, the style classes.
  const pointStyles = <Object?>[
    CirclePointStyle(),
    CrossPointStyle(),
    CrossRotPointStyle(),
    DashPointStyle(),
    LinePointStyle(),
    RectPointStyle(),
    RectRoundedPointStyle(),
    RectRotPointStyle(),
    StarPointStyle(),
    TrianglePointStyle(),
    false,
  ];

  LineDataset newDataset(Object? pointStyle, int i) => LineDataset(
    label: '',
    data: .values(<num?>[for (final _ in pointStyles) i]),
    // A PointStyle, or `false` (no point style) in extra.
    pointStyle: pointStyle is PointStyle ? .constant(pointStyle) : null,
    pointBackgroundColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
    pointBorderColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
    showLine: false,
    extra: pointStyle is PointStyle
        ? null
        : <String, Object?>{'pointStyle': pointStyle},
  );

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        for (final (i, pointStyle) in pointStyles.indexed)
          newDataset(pointStyle, i),
      ],
      labels: <Object>[for (final _ in pointStyles) ''],
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
          padding: const EdgeInsets.all(5),
          usePointStyle: true,
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
          afterDraw: (chart, _, _) {
            // var canvas = chart.canvas;
            // var rect = canvas.getBoundingClientRect();
            for (var i = 0; i < pointStyles.length; ++i) {
              final point = chart.getDatasetMeta(i).data[i];
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
    options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
  );
}
