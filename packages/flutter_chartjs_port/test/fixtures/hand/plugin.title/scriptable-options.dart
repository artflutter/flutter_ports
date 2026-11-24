// Ported from Chart.js v4.6.1 test/fixtures/plugin.title/scriptable-options.js (MIT, Chart.js Contributors).
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
        ScatterDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          extra: <String, Object?>{'data': data, 'radius': 1, 'hoverRadius': 0},
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
        TitleOptions(
          display: true,
          // DIVERGES(chartjs): adapt-title-scripted, the scriptable text in
          // the one function `scripted`.
          // DIVERGES(chartjs): adapt-title-text-lines, the lines of the text.
          scripted: (context, options) =>
              const TitleOptions(text: ['Title Text']),
        ),
      ],
      disabledPlugins: [
        PluginOff<LegendPlugin>(),
        PluginOff<FillerPlugin>(),
        PluginOff<TooltipPlugin>(),
      ],
    ),
    options: <String, Object?>{
      'spriteText': true,
      'canvas': <String, Object?>{'height': 400, 'width': 400},
    },
  );
}
