// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/label-textAlign/center.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADRs 0115
/// and 0193).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// legend options as one object. Each call makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      PieDataset(data: <num?>[1, 2, 3]),
    ],
    labels: <Object>['aaaa', 'bb', 'c'],
    pluginOptions: [
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const LegendOptions(
        position: ChartPosition.right,
        labels: LegendLabelOptions(textAlign: TextAlign.center),
      ),
    ],
  ),
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 256, 'height': 256},
  },
);
