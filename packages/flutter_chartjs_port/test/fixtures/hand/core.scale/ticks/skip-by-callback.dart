// Ported from Chart.js v4.6.1 test/fixtures/core.scale/ticks/skip-by-callback.js (MIT, Chart.js Contributors).
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
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(data: .values(<num?>[12, 19, 3, 5, 2, 3])),
      LineDataset(data: .values(<num?>[7, 11, 5, 8, 3, 7])),
    ],
    labels: <Object>['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
    scales: [
      CategoryAxis(
        CartesianAxis.x,
        ticks: AxisTicks(
          // A TickCallback (row adapt-native-tick): the scale is the
          // first parameter, and null stands for `undefined` and `null`.
          callback: (scale, val, index, ticks) {
            if (index == 1) {
              return null;
            }
            if (index == 3) {
              return null;
            }
            return <String>[jsToString(scale.getLabelForValue(val))];
          },
        ),
      ),
      LinearAxis(
        CartesianAxis.y,
        ticks: AxisTicks(
          callback: (scale, val, index, ticks) {
            return index.remainder(2) == 0 ? <String>[jsToString(val)] : null;
          },
        ),
      ),
    ],
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/8892',
);
