// Ported from Chart.js v4.6.1 test/fixtures/scale.linear/grace/grace-beginAtZero.js (MIT, Chart.js Contributors).
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
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BarDataset(
        data: .values(<num?>[100, 0]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
      ),
      BarDataset(
        data: .values(<num?>[0, 100]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        extra: <String, Object?>{'xAxisID': 'x2'},
      ),
    ],
    labels: <Object>['a', 'b'],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    extra: <String, Object?>{
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'y': <String, Object?>{'display': ScaleDisplay.off},
        'x': <String, Object?>{
          'position': ChartPosition.top,
          'beginAtZero': true,
          // DIVERGES(chartjs): adapt-length-objects, the length
          // class.
          'grace': const PercentGrace(10),
        },
        'x2': <String, Object?>{
          'position': ChartPosition.bottom,
          'type': 'linear',
          'beginAtZero': false,
          // DIVERGES(chartjs): adapt-length-objects, the length
          // class.
          'grace': const PercentGrace(10),
        },
      },
    },
  ),
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 512, 'height': 128},
  },
);
