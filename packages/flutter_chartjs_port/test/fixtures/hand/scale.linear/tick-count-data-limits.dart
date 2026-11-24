// Ported from Chart.js v4.6.1 test/fixtures/scale.linear/tick-count-data-limits.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(data: .values(<num?>[0, 2, 45, 30])),
    ],
    labels: <Object>['A', 'B', 'C', 'D'],
    scales: [
      LinearAxis(
        CartesianAxis.y,
        ticks: AxisTicks(
          // (v) => v.toString(): a tick value is a number, thus
          // Number.prototype.toString.
          // A TickCallback (row adapt-native-tick).
          callback: (scale, v, index, ticks) => <String>[jsToString(v)],
          extra: <String, Object?>{'count': 21},
        ),
      ),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
    ],
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/4234',
);
