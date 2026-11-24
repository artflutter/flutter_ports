// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/pointStyle-width/legend-pointStyle-width-default.json (MIT, Chart.js Contributors).
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
        data: .values(<num?>[10, 10, 10]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 1,
        label: '',
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: .constant(const LinePointStyle()),
      ),
      LineDataset(
        data: .values(<num?>[15, 15, 15]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 1,
        label: '',
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: .constant(const TrianglePointStyle()),
      ),
      LineDataset(
        data: .values(<num?>[20, 20, 20]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 1,
        label: '',
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: .constant(const RectRoundedPointStyle()),
      ),
      LineDataset(
        data: .values(<num?>[30, 30, 30]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 1,
        label: '',
      ),
      LineDataset(
        data: .values(<num?>[40, 40, 40]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 1,
        label: '',
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: .constant(const RectPointStyle()),
      ),
      LineDataset(
        data: .values(<num?>[25, 25, 25]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 1,
        label: '',
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: .constant(const RectRotPointStyle()),
      ),
      LineDataset(
        data: .values(<num?>[35, 35, 35]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 1,
        label: '',
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: .constant(const CrossRotPointStyle()),
      ),
      LineDataset(
        data: .values(<num?>[45, 45, 45]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 1,
        label: '',
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: .constant(const CrossPointStyle()),
      ),
      LineDataset(
        data: .values(<num?>[50, 50, 50]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 1,
        label: '',
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: .constant(const StarPointStyle()),
      ),
      LineDataset(
        data: .values(<num?>[55, 55, 55]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        borderWidth: 1,
        label: '',
        // DIVERGES(chartjs): adapt-point-style-objects, the style
        // class.
        pointStyle: .constant(const DashPointStyle()),
      ),
    ],
    labels: <Object>['A', 'B', 'C'],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    pluginOptions: [
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const LegendOptions(
        display: true,
        labels: LegendLabelOptions(usePointStyle: true),
      ),
    ],
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 1024},
  },
);
