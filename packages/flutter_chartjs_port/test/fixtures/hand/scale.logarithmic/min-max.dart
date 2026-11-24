// Ported from Chart.js v4.6.1 test/fixtures/scale.logarithmic/min-max.js (MIT, Chart.js Contributors).
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
      LineDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
        data: .values(<num?>[250, 240, 270, 320, 450, 300, 280]),
      ),
    ],
    labels: <Object>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
    ],
    responsive: true,
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      LogarithmicAxis(
        CartesianAxis.y,
        min: 233,
        max: 471,
        ticks: AxisTicks(autoSkip: false),
      ),
    ],
  ),
  options: <String, Object?>{'spriteText': true},
);
