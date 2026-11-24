// Ported from Chart.js v4.6.1 test/fixtures/scale.radialLinear/pointLabels/scriptable-color-small.js (MIT, Chart.js Contributors).
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
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      RadarDataset(
        label: '# of Votes',
        data: <num?>[
          12,
          19,
          3,
          5,
          1,
          3,
          12,
          19,
          3,
          5,
          1,
          3,
          12,
          19,
          3,
          5,
          1,
          3,
          12,
          19,
          3,
          5,
          1,
          3,
        ],
      ),
    ],
    labels: <Object>[
      'Red',
      'Blue',
      'Yellow',
      'Green',
      'Purple',
      'Orange',
      'Red',
      'Blue',
      'Yellow',
      'Green',
      'Purple',
      'Orange',
      'Red',
      'Blue',
      'Yellow',
      'Green',
      'Purple',
      'Orange',
      'Red',
      'Blue',
      'Yellow',
      'Green',
      'Purple',
      'Orange',
    ],
    scales: [
      RadialLinearAxis(
        ticks: AxisTicks(display: false),
        pointLabelsDisplay: ScaleDisplay.off,
        extra: <String, Object?>{
          'angleLines': <String, Object?>{
            'color': (ScriptableScalePointLabelContext ctx) {
              return jsToNumber(ctx.index).remainder(2) == 0
                  ? ChartPaint.solid(Color(0xFF008000))
                  : ChartPaint.solid(Color(0xFFFF0000));
            },
          },
        },
      ),
    ],
  ),
);
