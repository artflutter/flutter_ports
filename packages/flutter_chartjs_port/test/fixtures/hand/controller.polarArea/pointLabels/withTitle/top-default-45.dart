// Ported from Chart.js v4.6.1 test/fixtures/controller.polarArea/pointLabels/withTitle/top-default-45.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADRs 0115
/// and 0197).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// title options as one object. Each call makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      PolarAreaDataset(
        data: <num?>[1, 2, 3, 4],
        backgroundColor: .indexed(<ChartPaint>[
          ChartPaint.solid(Color(0x33FF0000)),
          ChartPaint.solid(Color(0x3300FF00)),
          ChartPaint.solid(Color(0x330000FF)),
          ChartPaint.solid(Color(0x33000000)),
        ]),
      ),
    ],
    labels: <Object>[
      <Object?>['label 1', 'line 2'],
      <Object?>['label 2', 'line 2'],
      <Object?>['label 3', 'line 2'],
      <Object?>['label 4', 'line 2'],
    ],
    scales: [
      RadialLinearAxis(startAngle: 45, pointLabelsDisplay: ScaleDisplay.on),
    ],
    disabledPlugins: [PluginOff<LegendPlugin>()],
    extra: <String, Object?>{
      'plugins': <String, Object?>{
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'title': const TitleOptions(display: true, text: ['Chart Title']),
      },
    },
  ),
  options: <String, Object?>{'spriteText': true},
);
