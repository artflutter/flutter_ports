// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/before-dataset-draw.js (MIT, Chart.js Contributors).
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
  raw(
    ChartConfig(
      datasets: [
        LineDataset(
          borderColor: .constant(ChartPaint.solid(Color(0x8000ADEE))),
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF00ADEE))),
          data: .values(<num?>[0, 1, 1, 2, 2, 0]),
        ),
        LineDataset(
          borderColor: .constant(ChartPaint.solid(Color(0x80BD2628))),
          backgroundColor: .constant(ChartPaint.solid(Color(0xFFBD2628))),
          data: .values(<num?>[0, 2, 2, 1, 1, 1]),
        ),
      ],
      labels: <Object>['15:00', '16:00', '17:00', '18:00', '19:00', '20:00'],
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
      pluginOptions: [
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        const FillerOptions(drawTime: FillerDrawTime.beforeDatasetDraw),
      ],
      disabledPlugins: [PluginOff<LegendPlugin>()],
      datasetDefaults: [
        LineDataset(
          borderWidth: 4,
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          fill: FillTarget.toOrigin,
          pointBackgroundColor: .constant(ChartPaint.solid(Color(0xFFFFFFFF))),
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          cubicInterpolationMode: const MonotoneCubicInterpolationMode(),
        ),
      ],
    ),
    <String, Object?>{'radius': 20},
  ),
);
