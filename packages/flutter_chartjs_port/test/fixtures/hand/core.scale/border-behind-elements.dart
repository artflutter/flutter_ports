// Ported from Chart.js v4.6.1 test/fixtures/core.scale/border-behind-elements.js (MIT, Chart.js Contributors).
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
      BubbleDataset(
        label: '# of Votes',
        data: [DataPoint.bubble(19, 3, 3), DataPoint.bubble(2, 2, 60)],
        radius: 100,
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFFC0CB))),
      ),
    ],
    scales: [
      LinearAxis(
        CartesianAxis.y,
        ticks: AxisTicks(display: false),
        // DIVERGES(chartjs): adapt-native-scale-border, the border object.
        border: const AxisBorder(
          color: ChartPaint.solid(Color(0xFFFF0000)),
          width: 5,
        ),
      ),
      LinearAxis(
        CartesianAxis.x,
        ticks: AxisTicks(display: false),
        // DIVERGES(chartjs): adapt-native-scale-border, the border object.
        border: const AxisBorder(
          color: ChartPaint.solid(Color(0xFFFF0000)),
          width: 5,
        ),
      ),
    ],
    pluginOptions: [
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const LegendOptions(display: false),
    ],
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
  },
);
