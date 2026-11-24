// Ported from Chart.js v4.6.1 test/fixtures/plugin.colors/dynamic-datasets-default.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `chart.data.datasets.push({...})` is [List.add], then
/// [notifyArrayListeners], the body of the hooked method (differences.md
/// row platform-array-events). The datasets array has no listeners, so the
/// notification does nothing, as upstream.
FixtureConfig fixture() {
  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        BarDataset(data: .values(<num?>[5, 5, 5, 5, 5, 5])),
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
    options: <String, Object?>{
      'run': (Chart chart) {
        final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
        final item = <String, Object?>{
          'data': <Object?>[5, 5, 5, 5, 5, 5],
        };
        datasets.add(item);
        notifyArrayListeners(datasets, 'push', <Object?>[item]);

        chart.update();
      },
    },
  );
}
