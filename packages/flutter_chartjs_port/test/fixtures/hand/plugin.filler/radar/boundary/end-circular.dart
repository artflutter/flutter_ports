// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/radar/boundary/end-circular.json (MIT, Chart.js Contributors).
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
      RadarDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 0, 192, 0.25)),
        ),
        data: <num?>[null, null, 2, 3, 4, -4, -2, 1, 0],
      ),
      RadarDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 192, 0, 0.25)),
        ),
        data: <num?>[5.5, 2, null, 4, 5, null, null, 2, 1],
      ),
      RadarDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(192, 0, 0, 0.25)),
        ),
        data: <num?>[7, 3, 4, 5, 6, 1, 4, null, null],
      ),
      RadarDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 0, 192, 0.25)),
        ),
        data: <num?>[8, 7, 6.5, -6, -4, -6, 4, 5, 8],
      ),
    ],
    labels: <Object>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
    responsive: false,
    scales: [
      RadialLinearAxis(
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        display: ScaleDisplay.off,
        grid: AxisGrid(extra: <String, Object?>{'circular': true}),
      ),
    ],
    elements: ChartElements(
      point: PointElementStyle(radius: 0),
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0x00000000)),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toEnd,
      ),
    ),
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    extra: <String, Object?>{'spanGaps': false},
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 256},
  },
);
