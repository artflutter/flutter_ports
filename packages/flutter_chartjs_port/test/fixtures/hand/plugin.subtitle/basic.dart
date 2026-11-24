// Ported from Chart.js v4.6.1 test/fixtures/plugin.subtitle/basic.js (MIT, Chart.js Contributors).
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
/// title and the subtitle options as one object each. Each call makes
/// new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      ScatterDataset(
        data: .points([DataPoint(0, 0), DataPoint(1, 1), DataPoint(2, 2)]),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        extra: <String, Object?>{'radius': 1, 'hoverRadius': 0},
      ),
    ],
    scales: [
      LinearAxis(CartesianAxis.x, display: ScaleDisplay.off),
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<FillerPlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    extra: <String, Object?>{
      'plugins': <String, Object?>{
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'title': const TitleOptions(display: true, text: ['Title Text']),
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'subtitle': const SubtitleOptions(
          display: true,
          text: ['SubTitle Text'],
        ),
      },
    },
  ),
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 400, 'width': 400},
  },
);
