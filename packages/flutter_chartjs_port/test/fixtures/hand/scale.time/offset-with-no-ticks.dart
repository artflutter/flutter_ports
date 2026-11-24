// Ported from Chart.js v4.6.1 test/fixtures/scale.time/offset-with-no-ticks.js (MIT, Chart.js Contributors).
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
  int day(int day) {
    // moment('<day>/10/2020', 'DD/MM/YYYY').valueOf() in the zone Etc/UTC of
    // test/index.js.
    // DIVERGES(chartjs): harness-fixture-sources, a moment value.
    return DateTime.utc(2020, 10, day).millisecondsSinceEpoch;
  }

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
          extra: <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'x': day(15), 'y': 55},
              <String, Object?>{'x': day(18), 'y': 10},
              <String, Object?>{'x': day(19), 'y': 15},
            ],
          },
        ),
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF008000))),
          extra: <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'x': day(15), 'y': 6},
              <String, Object?>{'x': day(18), 'y': 11},
              <String, Object?>{'x': day(19), 'y': 16},
            ],
          },
        ),
        BarDataset(
          backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          extra: <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'x': day(15), 'y': 7},
              <String, Object?>{'x': day(18), 'y': 12},
              <String, Object?>{'x': day(19), 'y': 17},
            ],
          },
        ),
      ],
      scales: [
        TimeAxis(
          CartesianAxis.x,
          extra: <String, Object?>{
            'time': <String, Object?>{
              // DIVERGES(chartjs): adapt-time-unit-enum, the enum value.
              'unit': TimeUnit.month,
            },
          },
        ),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
    ),
    description: 'https://github.com/chartjs/Chart.js/issues/7991',
    options: <String, Object?>{
      'spriteText': true,
      'canvas': <String, Object?>{'width': 256, 'height': 128},
    },
  );
}
