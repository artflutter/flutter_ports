// Ported from Chart.js v4.6.1 test/fixtures/core.scale/x-axis-position-center.json (MIT, Chart.js Contributors).
// ignore_for_file: file_names
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
      ScatterDataset(
        data: .points([
          DataPoint(-20, -30),
          DataPoint(0, 0),
          DataPoint(20, 15),
        ]),
      ),
    ],
    scales: [
      LinearAxis(
        CartesianAxis.x,
        position: ChartPosition.center,
        min: -100,
        max: 100,
        // DIVERGES(chartjs): adapt-native-scale-border, the border object.
        border: const AxisBorder(color: ChartPaint.solid(Color(0xFFFF0000))),
        grid: AxisGrid(
          color: ChartPaint.solid(Color(0xFFFF0000)),
          drawOnChartArea: false,
        ),
        ticks: AxisTicks(
          display: true,
          color: ChartPaint.solid(Color(0xFFFF0000)),
        ),
      ),
      LinearAxis(
        CartesianAxis.y,
        position: ChartPosition.left,
        min: -100,
        max: 100,
        // DIVERGES(chartjs): adapt-native-scale-border, the border object.
        border: const AxisBorder(color: ChartPaint.solid(Color(0xFFFF0000))),
        grid: AxisGrid(
          color: ChartPaint.solid(Color(0xFFFF0000)),
          drawOnChartArea: false,
        ),
        ticks: AxisTicks(display: true),
      ),
    ],
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
    'spriteText': true,
  },
);
