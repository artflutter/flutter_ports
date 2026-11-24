// Ported from Chart.js v4.6.1 test/fixtures/plugin.colors/doughnut.js (MIT, Chart.js Contributors).
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
      DoughnutDataset(data: <num?>[0, 2, 4, null, 6, 8]),
      DoughnutDataset(data: <num?>[5, 1, 6, 2, null, 9]),
    ],
    pluginOptions: [
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const ColorsPluginOptions(enabled: true),
    ],
    disabledPlugins: [PluginOff<LegendPlugin>()],
  ),
);
