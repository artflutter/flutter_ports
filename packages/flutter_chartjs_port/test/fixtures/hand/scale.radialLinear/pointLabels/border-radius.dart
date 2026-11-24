// Ported from Chart.js v4.6.1 test/fixtures/scale.radialLinear/pointLabels/border-radius.js (MIT, Chart.js Contributors).
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
      RadarDataset(
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFE43E51))),
        label: 'Compétences entrepreunariales',
        data: <num?>[3.0, 2.0, 2.0, 1.0, 3.0, 1.0],
      ),
    ],
    labels: <Object>[
      <Object?>['VENTE ET', 'COMMERCIALISATION'],
      <Object?>['GESTION', 'FINANCIÈRE'],
      'NUMÉRIQUE',
      <Object?>['ADMINISTRATION', 'ET OPÉRATION'],
      <Object?>['RESSOURCES', 'HUMAINES'],
      'INNOVATION',
    ],
    scales: [
      RadialLinearAxis(
        min: 0,
        max: 3,
        ticks: AxisTicks(
          display: false,
          stepSize: 1,
          extra: <String, Object?>{'maxTicksLimit': 1.0},
        ),
        extra: <String, Object?>{
          'pointLabels': <String, Object?>{
            'backdropColor': ChartPaint.solid(Color(0xFF0000FF)),
            'backdropPadding': const EdgeInsets.fromLTRB(5, 2, 5, 2),
            'borderRadius': 10.0,
          },
        },
      ),
    ],
    responsive: true,
    maintainAspectRatio: false,
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TooltipPlugin>(),
      PluginOff<FillerPlugin>(),
    ],
  ),
  options: <String, Object?>{'spriteText': true},
);
