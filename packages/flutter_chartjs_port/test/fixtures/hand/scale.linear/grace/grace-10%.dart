// Ported from Chart.js v4.6.1 test/fixtures/scale.linear/grace/grace-10%.js (MIT, Chart.js Contributors).
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
      BarDataset(data: .values(<num?>[90, -10])),
    ],
    labels: <Object>['a', 'b'],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.y, display: ScaleDisplay.off),
      LinearAxis(
        CartesianAxis.x,
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-length-objects, the length
          // class.
          'grace': const PercentGrace(10),
        },
      ),
    ],
  ),
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 512, 'height': 128},
  },
);
