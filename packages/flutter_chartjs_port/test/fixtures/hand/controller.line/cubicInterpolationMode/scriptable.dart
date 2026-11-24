// Ported from Chart.js v4.6.1 test/fixtures/controller.line/cubicInterpolationMode/scriptable.js (MIT, Chart.js Contributors).
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

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        // option in dataset
        data: .values(<num?>[0, 4, 2, 6, 4, 8]),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': (ScriptableContext ctx) {
            return ctx.datasetIndex == 0
                ? const MonotoneCubicInterpolationMode()
                : const DefaultCubicInterpolationMode();
          },
        },
      ),
      LineDataset(
        // option in element (fallback)
        data: .values(<num?>[2, 6, 4, 8, 6, 10]),
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    elements: ChartElements(
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0xFF00FF00)),
        borderWidth: 20,
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
        tension: 0.4,
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': (ScriptableContext ctx) {
            return ctx.datasetIndex == 0
                ? const MonotoneCubicInterpolationMode()
                : const DefaultCubicInterpolationMode();
          },
        },
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
