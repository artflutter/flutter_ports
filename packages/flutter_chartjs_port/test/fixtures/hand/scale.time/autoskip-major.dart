// Ported from Chart.js v4.6.1 test/fixtures/scale.time/autoskip-major.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() {
  final data = <Object?>[];
  for (var i = 0; i < 60; i++) {
    // moment('Jan 01 1990', 'MMM DD YYYY'), then date.clone().add(1, 'month')
    // at each pass, and date.valueOf() in the zone Etc/UTC of test/index.js.
    // DIVERGES(chartjs): harness-fixture-sources, a moment value.
    final x = DateTime.utc(1990, 1 + i).millisecondsSinceEpoch;
    data.add(<String, Object?>{'x': x, 'y': i});
  }

  final xAxis = TimeAxis(
    CartesianAxis.x,
    ticks: AxisTicks(
      // DIVERGES(chartjs): adapt-scale-option-enums, the enum value.
      source: TickSource.data,
      autoSkip: true,
      maxRotation: 0,
      extra: <String, Object?>{
        'major': <String, Object?>{'enabled': true},
      },
    ),
  );
  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        LineDataset(
          xAxis: xAxis,
          fill: FillTarget.none,
          extra: <String, Object?>{'data': data},
        ),
      ],
      scales: [
        xAxis,
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
      ],
    ),
    options: <String, Object?>{'spriteText': true},
  );
}
