// Ported from Chart.js v4.6.1 test/fixtures/scale.time/bar-large-gap-between-data.js (MIT, Chart.js Contributors).
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
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() {
  // var date = moment('May 24 2020', 'MMM DD YYYY');
  // DIVERGES(chartjs): harness-fixture-sources, a moment value.
  final date = DateTime.utc(2020, 5, 24);

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        BarDataset(
          backgroundColor: .constant(
            ChartPaint.solid(Color.fromRGBO(255, 0, 0, 0.5)),
          ),
          extra: <String, Object?>{
            // date.clone().add(n, 'day') for each x except the third.
            // DIVERGES(chartjs): harness-fixture-sources, a moment value.
            'data': <Object?>[
              <String, Object?>{'x': DateTime.utc(2020, 5, 24 - 2), 'y': 20},
              <String, Object?>{'x': DateTime.utc(2020, 5, 24 - 1), 'y': 30},
              <String, Object?>{'x': date, 'y': 40},
              <String, Object?>{'x': DateTime.utc(2020, 5, 24 + 1), 'y': 50},
              <String, Object?>{'x': DateTime.utc(2020, 5, 24 + 7), 'y': 10},
            ],
          },
        ),
      ],
      scales: [
        TimeAxis(
          CartesianAxis.x,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          display: ScaleDisplay.off,
          ticks: AxisTicks(
            // DIVERGES(chartjs): adapt-scale-option-enums, the enum value.
            source: TickSource.auto,
          ),
          extra: <String, Object?>{
            'time': <String, Object?>{
              // DIVERGES(chartjs): adapt-time-unit-enum, the enum value.
              'unit': TimeUnit.day,
            },
          },
        ),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
    ),
  );
}
