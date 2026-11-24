// Ported from Chart.js v4.6.1 test/fixtures/scale.time/data-ty.js (MIT, Chart.js Contributors).
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
FixtureConfig fixture() {
  DateTime newDateFromRef(int days) {
    // moment('01/01/2015 12:00', 'DD/MM/YYYY HH:mm').add(days, 'd').toDate()
    // DIVERGES(chartjs): harness-fixture-sources, a moment value.
    return DateTime.utc(2015, 1, 1 + days, 12);
  }

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        raw(
          LineDataset(
            // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
            fill: FillTarget.none,
          ),
          <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'t': newDateFromRef(0), 'y': 1},
              <String, Object?>{'t': newDateFromRef(1), 'y': 10},
              <String, Object?>{'t': newDateFromRef(2), 'y': 0},
              <String, Object?>{'t': newDateFromRef(4), 'y': 5},
              <String, Object?>{'t': newDateFromRef(6), 'y': 77},
              <String, Object?>{'t': newDateFromRef(7), 'y': 9},
              <String, Object?>{'t': newDateFromRef(9), 'y': 5},
            ],
            'parsing': <String, Object?>{'xAxisKey': 't'},
          },
        ),
      ],
      scales: [
        TimeAxis(
          CartesianAxis.x,
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          position: ChartPosition.bottom,
          ticks: AxisTicks(maxRotation: 0),
        ),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
    ),
    options: AcquireOptions(canvas: HarnessCanvas(width: 800, height: 200)),
  );
}
