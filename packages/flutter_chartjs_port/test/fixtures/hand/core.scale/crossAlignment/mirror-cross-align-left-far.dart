// Ported from Chart.js v4.6.1 test/fixtures/core.scale/crossAlignment/mirror-cross-align-left-far.js (MIT, Chart.js Contributors).
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
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BarDataset(data: .values(<num?>[1, 2, 3])),
    ],
    labels: <Object>['Long long label 1', 'Label2', 'Label3'],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    scales: [
      CategoryAxis(
        CartesianAxis.y,
        position: ChartPosition.left,
        ticks: AxisTicks(
          crossAlign: TickCrossAlign.far,
          extra: <String, Object?>{'mirror': true},
        ),
      ),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
