// Ported from Chart.js v4.6.1 test/fixtures/scale.logarithmic/null-values.js (MIT, Chart.js Contributors).
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
        data: .values(<num?>[150, null, 1500, 200, 9000, 3000, 8888]),
        spanGaps: true,
      ),
      LineDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
        data: .values(<num?>[1000, 5500, 800, 7777, null, 6666, 5555]),
        spanGaps: false,
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
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LogarithmicAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
  ),
);
