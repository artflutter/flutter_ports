// Ported from Chart.js v4.6.1 test/fixtures/core.scale/label-offset-vertical-axes.json (MIT, Chart.js Contributors).
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
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BarDataset(data: .values(<num?>[12, 19, 3, 5])),
    ],
    labels: <Object>['◀', '■', '◆', '●'],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    scales: [
      LinearAxis(
        CartesianAxis.x,
        ticks: AxisTicks(display: false),
        grid: AxisGrid(display: false),
        // DIVERGES(chartjs): adapt-native-scale-border, the border object.
        border: const AxisBorder(display: false),
      ),
      CategoryAxis(
        CartesianAxis.y,
        ticks: AxisTicks(extra: <String, Object?>{'labelOffset': 25}),
        // DIVERGES(chartjs): adapt-native-scale-border, the border object.
        border: const AxisBorder(display: false),
        grid: AxisGrid(display: false),
      ),
    ],
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
);
