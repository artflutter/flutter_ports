// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/dataset/dual.json (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart' show nativeFixturePaint;
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(255, 0, 0, 0.25)),
        ),
        data: .values(<num?>[0, 1, 2, -1, 0, 2, 1, -1, -2]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toNext.split(
          above: nativeFixturePaint('rgba(255, 0, 0, 0.25)'),
          below: nativeFixturePaint('rgba(0, 0, 255, 0.25)'),
        ),
      ),
      LineDataset(data: .values(<num?>[0, 0, 0, 0, 0, 0, 0, 0, 0])),
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
        borderColor: ChartPaint.solid(Color(0x00000000)),
        tension: 0,
      ),
    ),
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    extra: <String, Object?>{'spanGaps': true},
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
);
