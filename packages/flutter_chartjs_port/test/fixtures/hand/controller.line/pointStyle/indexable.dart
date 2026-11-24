// Ported from Chart.js v4.6.1 test/fixtures/controller.line/pointStyle/indexable.js (MIT, Chart.js Contributors).
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
      raw(
        LineDataset(
          data: .values(<num?>[0, 5, 10, null, -10, -5, 0]),
          pointBackgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          pointBorderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        ),
        <String, Object?>{
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': <Object?>[
            const CirclePointStyle(),
            const CrossPointStyle(),
            const CrossRotPointStyle(),
            const DashPointStyle(),
            const LinePointStyle(),
            const RectPointStyle(),
            false,
          ],
        },
      ),
      LineDataset(data: .values(<num?>[4, -5, -10, null, 10, 5, -4])),
    ],
    labels: <Object>[0, 1, 2, 3, 4, 5, 6],
    elements: ChartElements(
      line: LineElementStyle(fill: FillTarget.none),
      point: raw(
        PointElementStyle(
          backgroundColor: ChartPaint.solid(Color(0xFF00FF00)),
          borderColor: ChartPaint.solid(Color(0xFF00FF00)),
          radius: 10,
        ),
        <String, Object?>{
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': <Object?>[
            const LinePointStyle(),
            const RectPointStyle(),
            const RectRoundedPointStyle(),
            const RectRotPointStyle(),
            const StarPointStyle(),
            const TrianglePointStyle(),
          ],
        },
      ),
    ),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
