// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/padding/2cols-with-padding.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      PieDataset(
        data: <num?>[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0],
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
      ),
    ],
    labels: <Object>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k'],
    padding: const EdgeInsets.fromLTRB(30, 50, 30, 50),
    extra: <String, Object?>{
      'plugins': <String, Object?>{
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'legend': const LegendOptions(position: ChartPosition.left),
      },
    },
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/9278',
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 400.0, 'height': 300.0},
  },
);
