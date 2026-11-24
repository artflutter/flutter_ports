// Ported from Chart.js v4.6.1 test/fixtures/scale.timeseries/data-timestamps.js (MIT, Chart.js Contributors).
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
      LineDataset(
        data: .points([
          DataPoint(1687849697000, 904),
          DataPoint(1687817063000, 905),
          DataPoint(1687694268000, 913),
          DataPoint(1687609438000, 914),
          DataPoint(1687561387000, 916),
          DataPoint(1686875127000, 918),
          DataPoint(1686873138000, 920),
          DataPoint(1686872777000, 928),
          DataPoint(1686081641000, 915),
        ]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
      ),
      LineDataset(
        data: .points([
          DataPoint(1687816803000, 1105),
          DataPoint(1686869490000, 1114),
          DataPoint(1686869397000, 1103),
          DataPoint(1686869225000, 1091),
          DataPoint(1686556516000, 1078),
        ]),
      ),
    ],
    scales: [
      TimeSeriesAxis(
        CartesianAxis.x,
        bounds: ScaleBounds.data,
        unit: TimeUnit.day,
        ticks: AxisTicks(source: TickSource.auto),
      ),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
  ),
  options: <String, Object?>{'spriteText': true},
);
