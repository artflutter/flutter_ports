// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/above-below-vertical-linechart.js (MIT, Chart.js Contributors).
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
import 'package:chartjs_test_utils/pure.dart' show nativeFixturePaint;
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        data: .values(<num?>[200, 400, 200, 400]),
        // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
        // class.
        cubicInterpolationMode: const MonotoneCubicInterpolationMode(),
        tension: 0.4,
        spanGaps: true,
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        pointRadius: .constant(0),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: const FillTarget.toDataset(1).split(
          above: nativeFixturePaint('rgba(53, 221, 53, 0.4)'),
          below: nativeFixturePaint('rgba(255, 0, 0, 0.4)'),
        ),
      ),
      LineDataset(
        data: .values(<num?>[400, 200, 400, 200]),
        // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
        // class.
        cubicInterpolationMode: const MonotoneCubicInterpolationMode(),
        tension: 0.4,
        spanGaps: true,
        borderColor: .constant(ChartPaint.solid(Color(0xFFFFA500))),
        pointRadius: .constant(0),
      ),
    ],
    labels: <Object>[1, 2, 3, 4],
    // DIVERGES(chartjs): adapt-axis-objects, the axis
    // class.
    indexAxis: const YAxis(),
    pluginOptions: [
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const FillerOptions(propagate: false),
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const LegendOptions(display: false),
    ],
    extra: <String, Object?>{
      'plugins': <String, Object?>{
        'datalabels': <String, Object?>{'display': false},
      },
    },
  ),
);
