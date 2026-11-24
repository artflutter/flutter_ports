// Ported from Chart.js v4.6.1 test/fixtures/controller.line/segments/single.js (MIT, Chart.js Contributors).
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
        data: .values(<num?>[1, 2, 3, 3, 2, 1]),
        borderColor: .constant(ChartPaint.solid(Color(0xFF000000))),
        // DIVERGES(chartjs): adapt-native-line-segment-style, the constant
        // borderColor 'red' is a function that gives it for each part.
        segment: LineSegmentStyle(
          borderColor: (_) =>
              const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1)),
        ),
      ),
    ],
    labels: <Object>['a', 'b', 'c', 'd', 'e', 'f'],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 256)),
);
