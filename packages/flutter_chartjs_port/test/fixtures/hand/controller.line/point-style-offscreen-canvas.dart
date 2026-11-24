// Ported from Chart.js v4.6.1 test/fixtures/controller.line/point-style-offscreen-canvas.json (MIT, Chart.js Contributors).
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
      LineDataset(
        borderColor: .constant(ChartPaint.solid(Color(0x00000000))),
        data: .values(<num?>[3, 3, 3, 3, 3, 3, 3, 3, 3, 3]),
        pointBackgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        pointBorderColor: .constant(ChartPaint.solid(Color(0x00000000))),
        pointBorderWidth: 0,
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': <Object?>[
            const CirclePointStyle(),
            const CrossPointStyle(),
            const CrossRotPointStyle(),
            const DashPointStyle(),
            const LinePointStyle(),
            const RectPointStyle(),
            const RectRoundedPointStyle(),
            const RectRotPointStyle(),
            const StarPointStyle(),
            const TrianglePointStyle(),
          ],
        },
      ),
      LineDataset(
        borderColor: .constant(ChartPaint.solid(Color(0x00000000))),
        data: .values(<num?>[2, 2, 2, 2, 2, 2, 2, 2, 2, 2]),
        pointBackgroundColor: .constant(ChartPaint.solid(Color(0x00000000))),
        pointBorderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        pointBorderWidth: 1,
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': <Object?>[
            const CirclePointStyle(),
            const CrossPointStyle(),
            const CrossRotPointStyle(),
            const DashPointStyle(),
            const LinePointStyle(),
            const RectPointStyle(),
            const RectRoundedPointStyle(),
            const RectRotPointStyle(),
            const StarPointStyle(),
            const TrianglePointStyle(),
          ],
        },
      ),
      LineDataset(
        borderColor: .constant(ChartPaint.solid(Color(0x00000000))),
        data: .values(<num?>[1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
        pointBackgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        pointBorderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        pointBorderWidth: 1,
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': <Object?>[
            const CirclePointStyle(),
            const CrossPointStyle(),
            const CrossRotPointStyle(),
            const DashPointStyle(),
            const LinePointStyle(),
            const RectPointStyle(),
            const RectRoundedPointStyle(),
            const RectRotPointStyle(),
            const StarPointStyle(),
            const TrianglePointStyle(),
          ],
        },
      ),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    responsive: false,
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off, min: 0, max: 4),
    ],
    elements: ChartElements(
      line: LineElementStyle(fill: FillTarget.none),
      point: PointElementStyle(radius: 16),
    ),
    padding: const EdgeInsets.only(left: 24, right: 24),
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
    'useOffscreenCanvas': true,
  },
);
