// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/horizontal-borders.js (MIT, Chart.js Contributors).
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
        data: .values(<num?>[0, 5, 10, null, -10, -5]),
        borderWidth: 2,
      ),
      BarDataset(
        data: .values(<num?>[0, 5, 10, null, -10, -5]),
        borderSkipped: BorderSkip.none,
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    elements: ChartElements(
      bar: BarElementStyle(
        backgroundColor: ChartPaint.solid(Color(0x80AAAAAA)),
        borderColor: ChartPaint.solid(Color(0x80808080)),
        extra: <String, Object?>{
          'borderWidth': <String, Object?>{
            'bottom': 6,
            'left': 15,
            'top': 6,
            'right': 15,
          },
        },
      ),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
