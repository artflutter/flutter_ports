// Ported from Chart.js v4.6.1 test/fixtures/core.layouts/no-boxes-all-padding.js (MIT, Chart.js Contributors).
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
        data: .values(<num?>[0.0]),
        borderWidth: 0,
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        extra: <String, Object?>{'radius': 16.0},
      ),
    ],
    labels: <Object>[0.0],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(
        CartesianAxis.x,
        display: ScaleDisplay.off,
        extra: <String, Object?>{'offset': true},
      ),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    padding: const EdgeInsets.all(16),
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TooltipPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<FillerPlugin>(),
    ],
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 32.0, 'width': 32.0},
  },
);
