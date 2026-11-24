// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/rotation/value.js (MIT, Chart.js Contributors).
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
      RadarDataset(
        data: <num?>[0, 5, 10, null, -10, -5],
        pointBorderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        pointRotation: .constant(90),
      ),
      RadarDataset(data: <num?>[4, -5, -10, null, 10, 5]),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5],
    elements: ChartElements(
      line: LineElementStyle(fill: FillTarget.none),
      point: PointElementStyle(
        borderColor: ChartPaint.solid(Color(0xFF00FF00)),
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: const LinePointStyle(),
        radius: 10,
        rotation: 0,
      ),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      RadialLinearAxis(display: ScaleDisplay.off, min: -15),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
);
