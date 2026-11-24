// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/radar/beforeDraw.js (MIT, Chart.js Contributors).
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
      RadarDataset(
        label: '# of Votes',
        data: <num?>[9.0, 7.0, 3.0, 5.0, 2.0, 3.0],
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toOrigin,
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF008000))),
        pointRadius: .constant(12),
        pointBackgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
      ),
    ],
    labels: <Object>['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
    padding: const EdgeInsets.all(20),
    scales: [
      RadialLinearAxis(
        angleLinesColor: ChartPaint.solid(Color.fromRGBO(0, 0, 0, 0.5)),
        angleLinesLineWidth: 2,
        grid: AxisGrid(
          color: .constant(ChartPaint.solid(Color.fromRGBO(0, 0, 0, 0.5))),
          lineWidth: .constant(2),
        ),
        pointLabelsDisplay: ScaleDisplay.off,
        ticks: AxisTicks(
          display: false,
          extra: <String, Object?>{'beginAtZero': true},
        ),
      ),
    ],
    pluginOptions: [
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const FillerOptions(drawTime: FillerDrawTime.beforeDraw),
    ],
    disabledPlugins: [PluginOff<LegendPlugin>()],
  ),
);
