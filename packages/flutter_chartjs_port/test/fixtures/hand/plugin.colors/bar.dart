// Ported from Chart.js v4.6.1 test/fixtures/plugin.colors/bar.js (MIT, Chart.js Contributors).
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
      BarDataset(data: .values(<num?>[0, 5, 10, null, -10, -5])),
      BarDataset(data: .values(<num?>[10, 2, 3, null, 10, 5])),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    scales: [
      CategoryAxis(CartesianAxis.x, ticks: AxisTicks(display: false)),
      LinearAxis(CartesianAxis.y, ticks: AxisTicks(display: false)),
    ],
    pluginOptions: [
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const ColorsPluginOptions(enabled: true),
    ],
    disabledPlugins: [PluginOff<LegendPlugin>()],
  ),
);
