// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/minBarLength/horizontal-stacked-no-overlap.js (MIT, Chart.js Contributors).
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
      BarDataset(
        data: .values(<num?>[1, -1, 1, 20]),
        backgroundColor: .constant(ChartPaint.solid(Color(0x66BB0000))),
        minBarLength: 50,
      ),
      BarDataset(
        data: .values(<num?>[1, -1, -1, -20]),
        backgroundColor: .constant(ChartPaint.solid(Color(0x6600BB00))),
        minBarLength: 50,
      ),
      BarDataset(
        data: .values(<num?>[1, -1, 1, 40]),
        backgroundColor: .constant(ChartPaint.solid(Color(0x660000BB))),
        minBarLength: 50,
      ),
      BarDataset(
        data: .values(<num?>[1, -1, -1, -40]),
        backgroundColor: .constant(ChartPaint.solid(Color(0x66000000))),
        minBarLength: 50,
      ),
    ],
    labels: <Object>[1, 2, 3, 4],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    scales: [
      // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(
        CartesianAxis.x,
        display: ScaleDisplay.off,
        stacked: StackMode.on,
      ),
      LinearAxis(
        CartesianAxis.y,
        position: ChartPosition.left,
        // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
        stacked: StackMode.on,
        ticks: AxisTicks(display: false),
      ),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
);
