// Ported from Chart.js v4.6.1 test/fixtures/controller.line/cubicInterpolationMode/value.js (MIT, Chart.js Contributors).
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
        data: .values(<num?>[0, 4, 2, 6, 4, 8]),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
        // class.
        cubicInterpolationMode: const MonotoneCubicInterpolationMode(),
      ),
      LineDataset(data: .values(<num?>[2, 6, 4, 8, 6, 10])),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    elements: ChartElements(
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0xFF00FF00)),
        borderWidth: 20,
        // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
        // class.
        cubicInterpolationMode: const DefaultCubicInterpolationMode(),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
        tension: 0.4,
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
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
);
