// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/title/left-center-center.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
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
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// legend options as one object. Each call makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(label: 'a', data: .values(<num?>[])),
      LineDataset(label: 'b', data: .values(<num?>[])),
      LineDataset(label: 'c', data: .values(<num?>[])),
    ],
    scales: [
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    extra: <String, Object?>{
      'plugins': <String, Object?>{
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'legend': const LegendOptions(
          position: ChartPosition.left,
          align: ChartAlign.center,
          title: LegendTitleOptions(
            display: true,
            position: ChartAlign.center,
            text: ['title'],
          ),
        ),
      },
    },
  ),
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 256, 'width': 256},
  },
);
