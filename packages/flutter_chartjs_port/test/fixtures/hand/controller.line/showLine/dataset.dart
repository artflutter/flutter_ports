// Ported from Chart.js v4.6.1 test/fixtures/controller.line/showLine/dataset.js (MIT, Chart.js Contributors).
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
          data: .values(<num?>[10, 15, 0, -4]),
          label: 'dataset1',
          borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
          backgroundColor: .constant(ChartPaint.solid(Color(0xFF008000))),
          showLine: false,
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          fill: FillTarget.none,
        ),
      ],
      labels: <Object>['label1', 'label2', 'label3', 'label4'],
      scales: [
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
      disabledPlugins: [
        PluginOff<LegendPlugin>(),
        PluginOff<TitlePlugin>(),
        PluginOff<TooltipPlugin>(),
      ],
    ),
    <String, Object?>{
      'showLine': true,
      'plugins': <String, Object?>{'filler': true},
    },
  ),
  description: 'should draw all elements except lines turned off per dataset',
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
);
