// Ported from Chart.js v4.6.1 test/fixtures/controller.bubble/point-style.json (MIT, Chart.js Contributors).
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
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0x00000000))),
        borderWidth: 0,
        extra: <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 3},
            <String, Object?>{'x': 1, 'y': 3},
            <String, Object?>{'x': 2, 'y': 3},
            <String, Object?>{'x': 3, 'y': 3},
            <String, Object?>{'x': 4, 'y': 3},
            <String, Object?>{'x': 5, 'y': 3},
            <String, Object?>{'x': 6, 'y': 3},
            <String, Object?>{'x': 7, 'y': 3},
            <String, Object?>{'x': 8, 'y': 3},
            <String, Object?>{'x': 9, 'y': 3},
          ],
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
      BubbleDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0x00000000))),
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        borderWidth: 1,
        extra: <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 2},
            <String, Object?>{'x': 1, 'y': 2},
            <String, Object?>{'x': 2, 'y': 2},
            <String, Object?>{'x': 3, 'y': 2},
            <String, Object?>{'x': 4, 'y': 2},
            <String, Object?>{'x': 5, 'y': 2},
            <String, Object?>{'x': 6, 'y': 2},
            <String, Object?>{'x': 7, 'y': 2},
            <String, Object?>{'x': 8, 'y': 2},
            <String, Object?>{'x': 9, 'y': 2},
          ],
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
      BubbleDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        borderWidth: 1,
        extra: <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 1},
            <String, Object?>{'x': 1, 'y': 1},
            <String, Object?>{'x': 2, 'y': 1},
            <String, Object?>{'x': 3, 'y': 1},
            <String, Object?>{'x': 4, 'y': 1},
            <String, Object?>{'x': 5, 'y': 1},
            <String, Object?>{'x': 6, 'y': 1},
            <String, Object?>{'x': 7, 'y': 1},
            <String, Object?>{'x': 8, 'y': 1},
            <String, Object?>{'x': 9, 'y': 1},
          ],
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
    responsive: false,
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off, min: 0, max: 4),
    ],
    elements: ChartElements(
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0x00000000)),
        borderWidth: 1,
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
      ),
      point: PointElementStyle(radius: 16),
    ),
    padding: const EdgeInsets.only(left: 24, right: 24),
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
