// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/padding/add-column.js (MIT, Chart.js Contributors).
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
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      PieDataset(
        data: <num?>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
      ),
    ],
    labels: <Object>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'],
    padding: const EdgeInsets.only(left: 30, top: 55, right: 30),
    pluginOptions: [
      // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const LegendOptions(position: ChartPosition.left),
    ],
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/9278',
  options: AcquireOptions(canvas: HarnessCanvas(width: 400, height: 300)),
  run: (chart) {
    // Upstream: chart.data.labels.push('k'). The chart does not listen to
    // the labels array.
    (jsGet(chart.data, 'labels')! as List<Object?>).add('k');
    // Upstream: chart.data.datasets[0].data.push(11). The push, then the
    // body of the hooked method (differences.md row
    // platform-array-events).
    final data =
        jsGet(jsGetIndex(jsGet(chart.data, 'datasets'), 0), 'data')!
              as List<Object?>
          ..add(11);
    notifyArrayListeners(data, 'push', <Object?>[11]);
    chart.update();
  },
);
