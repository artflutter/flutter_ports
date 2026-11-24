// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/drawTimeFillFalse/beforeDraw.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        data: .values(<num?>[3, -3, 0, 5, -5, 0]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
      ),
    ],
    labels: <Object>['0', '1', '2', '3', '4', '5'],
    pluginOptions: [
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const FillerOptions(drawTime: FillerDrawTime.beforeDraw),
    ],
    disabledPlugins: [PluginOff<LegendPlugin>(), PluginOff<TitlePlugin>()],
  ),
);
