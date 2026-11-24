// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/chart-area-clip.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BarDataset(
        data: .values(<num?>[5.0, 20.0, -5.0, -20.0]),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
      ),
    ],
    labels: <Object>[0.0, 1.0, 3.0, 4.0],
    padding: const EdgeInsets.fromLTRB(0, 50, 0, 50),
    elements: ChartElements(
      bar: BarElementStyle(
        backgroundColor: ChartPaint.solid(Color(0xFF00FF00)),
        borderWidth: 8,
      ),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off, min: -10, max: 10),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
