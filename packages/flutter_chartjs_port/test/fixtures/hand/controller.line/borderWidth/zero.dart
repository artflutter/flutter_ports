// Ported from Chart.js v4.6.1 test/fixtures/controller.line/borderWidth/zero.js (MIT, Chart.js Contributors).
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

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        data: .values(<num?>[0.0, 5.0, 10.0, null, -10.0, -5.0]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        borderWidth: 0,
      ),
      LineDataset(data: .values(<num?>[4.0, -5.0, -10.0, null, 10.0, 5.0])),
    ],
    labels: <Object>[0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
    elements: ChartElements(
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0xFF00FF00)),
        borderWidth: 3,
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
      ),
      point: PointElementStyle(
        backgroundColor: ChartPaint.solid(Color(0xFF00FF00)),
        radius: 10,
      ),
    ),
    padding: const EdgeInsets.all(32),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
