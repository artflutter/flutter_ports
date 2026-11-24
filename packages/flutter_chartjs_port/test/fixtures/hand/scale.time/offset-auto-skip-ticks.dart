// Ported from Chart.js v4.6.1 test/fixtures/scale.time/offset-auto-skip-ticks.js (MIT, Chart.js Contributors).
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
      BarDataset(
        label: 'Dataset',
        borderColor: .constant(ChartPaint.solid(Color(0xFF2F54EB))),
        data: .points([
          DataPoint(1646345700000, 3),
          DataPoint(1646346600000, 7),
          DataPoint(1646347500000, 9),
          DataPoint(1646348400000, 5),
          DataPoint(1646349300000, 5),
        ]),
      ),
    ],
    labels: <Object>[],
    maintainAspectRatio: false,
    scales: [
      TimeAxis(
        CartesianAxis.x,
        grid: AxisGrid(offset: true),
        extra: <String, Object?>{'offset': true, 'offsetAfterAutoskip': true},
      ),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/10215',
  options: AcquireOptions(canvas: HarnessCanvas(width: 600, height: 400)),
);
