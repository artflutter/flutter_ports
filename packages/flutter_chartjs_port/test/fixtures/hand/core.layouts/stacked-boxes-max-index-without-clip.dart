// Ported from Chart.js v4.6.1 test/fixtures/core.layouts/stacked-boxes-max-index-without-clip.js (MIT, Chart.js Contributors).
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
FixtureConfig fixture() {
  final y1Axis = LinearAxis(
    CartesianAxis.y,
    position: ChartPosition.left,
    // DIVERGES(chartjs): adapt-native-scale-border, the border object.
    border: const AxisBorder(color: ChartPaint.solid(Color(0xFF008000))),
    ticks: AxisTicks(extra: <String, Object?>{'precision': 0}),
    extra: <String, Object?>{'stack': '1', 'offset': true, 'clip': false},
  );
  final x1Axis = LinearAxis(
    CartesianAxis.x,
    position: ChartPosition.bottom,
    bounds: ScaleBounds.data,
    // DIVERGES(chartjs): adapt-native-scale-border, the border object.
    border: const AxisBorder(color: ChartPaint.solid(Color(0xFF008000))),
    ticks: AxisTicks(
      autoSkip: false,
      maxRotation: 0,
      extra: <String, Object?>{'count': 3},
    ),
    max: 7,
    extra: <String, Object?>{'stack': '1', 'offset': true, 'clip': false},
  );
  final y2Axis = LinearAxis(
    CartesianAxis.y,
    position: ChartPosition.left,
    // DIVERGES(chartjs): adapt-native-scale-border, the border object.
    border: const AxisBorder(color: ChartPaint.solid(Color(0xFF0000FF))),
    ticks: AxisTicks(extra: <String, Object?>{'precision': 0}),
    extra: <String, Object?>{'stack': '1', 'offset': true, 'clip': false},
  );
  final x2Axis = LinearAxis(
    CartesianAxis.x,
    position: ChartPosition.bottom,
    bounds: ScaleBounds.data,
    // DIVERGES(chartjs): adapt-native-scale-border, the border object.
    border: const AxisBorder(color: ChartPaint.solid(Color(0xFF0000FF))),
    ticks: AxisTicks(
      autoSkip: false,
      maxRotation: 0,
      extra: <String, Object?>{'count': 3},
    ),
    max: 7,
    extra: <String, Object?>{'stack': '1', 'offset': true, 'clip': false},
  );
  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        LineDataset(
          data: .points([DataPoint(5, 1), DataPoint(10, 2), DataPoint(5, 3)]),
          borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        ),
        LineDataset(
          data: .points([DataPoint(5, 1), DataPoint(10, 2), DataPoint(5, 3)]),
          yAxis: y1Axis,
          xAxis: x1Axis,
          borderColor: .constant(ChartPaint.solid(Color(0xFF008000))),
        ),
        LineDataset(
          data: .points([DataPoint(5, 1), DataPoint(10, 2), DataPoint(5, 3)]),
          yAxis: y2Axis,
          xAxis: x2Axis,
          borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        ),
      ],
      labels: <Object>['tick1', 'tick2', 'tick3'],
      scales: [
        LinearAxis(
          CartesianAxis.x,
          position: ChartPosition.bottom,
          bounds: ScaleBounds.data,
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          border: const AxisBorder(color: ChartPaint.solid(Color(0xFFFF0000))),
          ticks: AxisTicks(
            autoSkip: false,
            maxRotation: 0,
            extra: <String, Object?>{'count': 3},
          ),
          max: 7,
          extra: <String, Object?>{'stack': '1', 'offset': true, 'clip': false},
        ),
        x1Axis,
        x2Axis,
        LinearAxis(
          CartesianAxis.y,
          position: ChartPosition.left,
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          border: const AxisBorder(color: ChartPaint.solid(Color(0xFFFF0000))),
          ticks: AxisTicks(extra: <String, Object?>{'precision': 0}),
          extra: <String, Object?>{'stack': '1', 'offset': true, 'clip': false},
        ),
        y1Axis,
        y2Axis,
      ],
      extra: <String, Object?>{'plugins': false},
    ),
    options: AcquireOptions(canvas: HarnessCanvas(width: 384, height: 384)),
  );
}
