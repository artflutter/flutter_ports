// Ported from Chart.js v4.6.1 test/fixtures/core.scale/grid/colors.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'dart:ui' show Color;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        label: '# of Votes',
        data: .values(<num?>[12, 19, 3, 5, 2, 3]),
      ),
    ],
    labels: <Object>['1', '2', '3', '4', '5', '6'],
    scales: [
      CategoryAxis(
        CartesianAxis.x,
        ticks: AxisTicks(display: false),
        // DIVERGES(chartjs): adapt-native-scale-border, the border object.
        border: const AxisBorder(
          color: ChartPaint.solid(Color(0xFF0000FF)),
          width: 2,
        ),
        grid: AxisGrid(
          color: ChartPaint.solid(Color(0xFF008000)),
          drawTicks: false,
        ),
      ),
      LinearAxis(
        CartesianAxis.y,
        ticks: AxisTicks(display: false),
        // DIVERGES(chartjs): adapt-native-scale-border, the border object.
        border: const AxisBorder(
          color: ChartPaint.solid(Color(0xFF000000)),
          width: 2,
        ),
        grid: AxisGrid(
          color: ChartPaint.solid(Color(0xFFFF0000)),
          drawTicks: false,
        ),
      ),
    ],
  ),
);
