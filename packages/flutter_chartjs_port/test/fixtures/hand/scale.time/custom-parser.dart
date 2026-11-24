// Ported from Chart.js v4.6.1 test/fixtures/scale.time/custom-parser.js (MIT, Chart.js Contributors).
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
      LineDataset(
        data: .values(<num?>[0, 1]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
      ),
    ],
    labels: <Object>['foo', 'bar'],
    scales: [
      TimeAxis(
        CartesianAxis.x,
        // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
        position: ChartPosition.bottom,
        ticks: AxisTicks(
          // DIVERGES(chartjs): adapt-scale-option-enums, the enum value.
          source: TickSource.labels,
        ),
        extra: <String, Object?>{
          'time': <String, Object?>{
            // DIVERGES(chartjs): adapt-time-unit-enum, the enum value.
            'unit': TimeUnit.day,
            'round': true,
            'parser': (Object? label) {
              // moment('2000/01/02', 'YYYY/MM/DD') and
              // moment('2016/05/08', 'YYYY/MM/DD').
              // DIVERGES(chartjs): harness-fixture-sources, a moment value.
              return label == 'foo'
                  ? DateTime.utc(2000, 1, 2)
                  : DateTime.utc(2016, 5, 8);
            },
          },
        },
      ),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
  ),
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 256, 'height': 128},
  },
);
