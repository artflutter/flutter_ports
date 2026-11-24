// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/legend-doughnut-left-center-mulitiline.json (MIT, Chart.js Contributors).
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
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// legend options as one object. Each call makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      DoughnutDataset(
        data: <num?>[
          10,
          20,
          30,
          40,
          50,
          60,
          70,
          10,
          20,
          30,
          40,
          50,
          60,
          70,
          10,
          20,
          30,
        ],
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
        borderWidth: 0,
      ),
    ],
    labels: <Object>[
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
    ],
    pluginOptions: [
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const LegendOptions(
        position: ChartPosition.left,
        align: ChartAlign.center,
      ),
    ],
  ),
  options: <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
);
