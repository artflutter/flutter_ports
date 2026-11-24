// Ported from Chart.js v4.6.1 test/fixtures/plugin.colors/bubble.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BubbleDataset(data: [DataPoint.bubble(12, 54, 22.4)]),
      BubbleDataset(data: [DataPoint.bubble(18, 38, 25)]),
    ],
    scales: [
      LinearAxis(CartesianAxis.x, ticks: AxisTicks(display: false)),
      LinearAxis(CartesianAxis.y, ticks: AxisTicks(display: false)),
    ],
    disabledPlugins: [PluginOff<LegendPlugin>()],
    extra: <String, Object?>{
      'plugins': <String, Object?>{
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'colors': const ColorsPluginOptions(enabled: true),
      },
    },
  ),
);
