// Ported from Chart.js v4.6.1 test/fixtures/core.scale/crossAlignment/cross-align-right-far-clipped.js (MIT, Chart.js Contributors).
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
      BarDataset(data: .values(<num?>[1, 2, 3])),
    ],
    labels: <Object>[
      'Long long long long label 1',
      'Label 2',
      'Less more longer label 3',
    ],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    scales: [
      CategoryAxis(
        CartesianAxis.y,
        // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
        position: ChartPosition.right,
        ticks: AxisTicks(
          // DIVERGES(chartjs): adapt-scale-option-enums, the enum value.
          crossAlign: TickCrossAlign.far,
        ),
        extra: <String, Object?>{
          'afterFit': (Scale axis) {
            axis.width = 64;
          },
        },
      ),
    ],
  ),
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
);
