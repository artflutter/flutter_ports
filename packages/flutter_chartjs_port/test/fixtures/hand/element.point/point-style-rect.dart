// Ported from Chart.js v4.6.1 test/fixtures/element.point/point-style-rect.json (MIT, Chart.js Contributors).
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
      BubbleDataset(
        data: [
          DataPoint.bubble(0, 3, 0),
          DataPoint.bubble(1, 3, 2),
          DataPoint.bubble(2, 3, 4),
          DataPoint.bubble(3, 3, 8),
          DataPoint.bubble(4, 3, 16),
          DataPoint.bubble(5, 3, 32),
        ],
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0x00000000))),
        borderWidth: 0,
      ),
      BubbleDataset(
        data: [
          DataPoint.bubble(0, 2, 0),
          DataPoint.bubble(1, 2, 2),
          DataPoint.bubble(2, 2, 4),
          DataPoint.bubble(3, 2, 8),
          DataPoint.bubble(4, 2, 16),
          DataPoint.bubble(5, 2, 32),
        ],
        backgroundColor: .constant(ChartPaint.solid(Color(0x00000000))),
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        borderWidth: 1,
      ),
      BubbleDataset(
        data: [
          DataPoint.bubble(0, 1, 0),
          DataPoint.bubble(1, 1, 2),
          DataPoint.bubble(2, 1, 4),
          DataPoint.bubble(3, 1, 8),
          DataPoint.bubble(4, 1, 16),
          DataPoint.bubble(5, 1, 32),
        ],
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        borderWidth: 2,
      ),
    ],
    responsive: false,
    elements: ChartElements(
      point: PointElementStyle(
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: const RectPointStyle(),
      ),
    ),
    padding: const EdgeInsets.all(40),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
