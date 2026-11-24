// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/radar/value.json (MIT, Chart.js Contributors).
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
        data: <num?>[0, -4, 2, 4, 2, 1, -1, 1, 2],
      ),
    ],
    labels: <Object>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
    responsive: false,
    scales: [
      RadialLinearAxis(
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        display: ScaleDisplay.off,
        grid: AxisGrid(circular: true),
      ),
    ],
    elements: ChartElements(
      point: PointElementStyle(radius: 0),
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0x00000000)),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: const FillTarget.toValue(3),
      ),
    ),
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    datasetDefaults: [RadarDataset(spanGaps: false)],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 256)),
);
