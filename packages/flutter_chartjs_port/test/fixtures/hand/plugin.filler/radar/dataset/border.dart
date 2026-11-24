// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/radar/dataset/border.json (MIT, Chart.js Contributors).
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
          ChartPaint.solid(Color.fromRGBO(255, 0, 0, 0.25)),
        ),
        data: <num?>[null, null, 0, -1, 0, 1, 0, -1, 0],
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': const FillTarget.toDataset(1),
        },
      ),
      RadarDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 255, 0, 0.25)),
        ),
        data: <num?>[1, 0, null, 1, 0, null, -1, 0, 1],
        // DIVERGES(chartjs): adapt-fill-target-objects, the target
        // value.
        fill: FillTarget.toNext,
      ),
      RadarDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 0, 255, 0.25)),
        ),
        data: <num?>[0, 2, 0, -2, 0, 2, 0],
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': const FillTarget.toDataset(3),
        },
      ),
      RadarDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(255, 0, 255, 0.25)),
        ),
        data: <num?>[2, 0, -2, 0, 2, 0, -2, 0, 2],
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-fill-target-objects, the target
          // value.
          'fill': const FillTarget.toRelative(-2),
        },
      ),
      RadarDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(255, 255, 0, 0.25)),
        ),
        data: <num?>[3, 1, -1, -3, -1, 1, 3, 1, -1],
        // DIVERGES(chartjs): adapt-fill-target-objects, the target
        // value.
        fill: FillTarget.toPrevious,
      ),
    ],
    labels: <Object>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
    responsive: false,
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      RadialLinearAxis(display: ScaleDisplay.off),
    ],
    elements: ChartElements(
      point: PointElementStyle(radius: 0),
      line: LineElementStyle(
        borderColor: ChartPaint.solid(Color(0xFF000000)),
        borderWidth: 5,
        tension: 0,
      ),
    ),
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    extra: <String, Object?>{'spanGaps': false},
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 256)),
);
