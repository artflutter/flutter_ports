// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/boundary/origin-stepped.json (MIT, Chart.js Contributors).
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
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 0, 192, 0.25)),
        ),
        data: .values(<num?>[null, null, 2, 4, 2, 1, -1, 1, 2]),
      ),
      LineDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 192, 0, 0.25)),
        ),
        data: .values(<num?>[4, 2, null, 3, 2.5, null, -2, 1.5, 3]),
      ),
      LineDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(192, 0, 0, 0.25)),
        ),
        data: .values(<num?>[3.5, 2, 1, 2.5, -2, 3, -1, null, null]),
      ),
      LineDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(128, 0, 128, 0.25)),
        ),
        data: .values(<num?>[5, 6, 5, -2, -4, -3, 4, 2, 4.5]),
      ),
    ],
    labels: <Object>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
    responsive: false,
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    elements: ChartElements(
      point: PointElementStyle(radius: 0),
      line: LineElementStyle(
        // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
        // class.
        cubicInterpolationMode: const MonotoneCubicInterpolationMode(),
        borderColor: ChartPaint.solid(Color(0x00000000)),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toOrigin,
        extra: <String, Object?>{'stepped': true},
      ),
    ),
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    extra: <String, Object?>{'spanGaps': false},
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
