// Ported from Chart.js v4.6.1 test/fixtures/core.interaction/nearest-partial-bar.js (MIT, Chart.js Contributors).
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
/// `jasmine.triggerMouseEvent` (:39) is [triggerMouseEvent] of the harness.
/// The point is a Map with the upstream keys. `chart.chartArea` is set
/// after the first layout of the chart, before the hook runs.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BarDataset(data: .values(<num?>[220, 250, 225])),
    ],
    labels: <Object>['a', 'b', 'c'],
    events: <String>['click'],
    interaction: ChartInteraction(
      // DIVERGES(chartjs): adapt-interaction-mode-objects, the mode.
      mode: const NearestInteractionMode(),
    ),
    scales: [LinearAxis(CartesianAxis.y, beginAtZero: false)],
    disabledPlugins: [PluginOff<LegendPlugin>()],
    extra: <String, Object?>{
      'plugins': <String, Object?>{'tooltip': true},
    },
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 256)),
  run: (chart) async {
    final chartArea = chart.chartArea!;
    final point = <String, Object?>{
      'x': chartArea.left + chartArea.width / 2,
      'y': chartArea.top + chartArea.height / 2,
    };
    await triggerMouseEvent(chart, 'click', point);
  },
);
