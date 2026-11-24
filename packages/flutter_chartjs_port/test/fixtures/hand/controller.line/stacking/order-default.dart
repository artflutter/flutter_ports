// Ported from Chart.js v4.6.1 test/fixtures/controller.line/stacking/order-default.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        data: .values(<num?>[3.0, 1.0, 2.0, 0.0, 8.0, 1.0]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
      ),
      LineDataset(
        data: .values(<num?>[0.0, 4.0, 2.0, 6.0, 4.0, 8.0]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
      ),
    ],
    labels: <Object>[0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
    elements: ChartElements(
      line: LineElementStyle(fill: FillTarget.toOrigin),
      point: PointElementStyle(radius: 0),
    ),
    padding: const EdgeInsets.all(32),
    scales: [
      // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(
        CartesianAxis.x,
        stacked: StackMode.on,
        display: ScaleDisplay.off,
      ),
      // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(
        CartesianAxis.y,
        stacked: StackMode.on,
        display: ScaleDisplay.off,
      ),
    ],
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    extra: <String, Object?>{
      'plugins': <String, Object?>{'filler': true},
    },
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 256.0, 'width': 512.0},
  },
);
