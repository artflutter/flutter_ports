// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/horizontal-rtl-hitbox.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-legend-hit-box, native geometry reads.
// DIVERGES(chartjs): adapt-direct-colors, native paint inputs.
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The inline plugin reads `legendHitBoxes` through a cast to [Legend]
/// (Chart.js ADR 0038, section 6). A hit box is a Map with the upstream
/// keys.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      PieDataset(
        data: <num?>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        backgroundColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
      ),
    ],
    labels: <Object>['aaa', 'bb', 'c'],
    padding: const EdgeInsets.only(left: 30, top: 50, right: 30, bottom: 50),
    pluginOptions: [
      // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      const LegendOptions(
        position: ChartPosition.top,
        // DIVERGES(chartjs): adapt-bool-options, the text 'true' of
        // upstream is the bool true.
        rtl: true,
      ),
    ],
    plugins: [
      // DIVERGES(chartjs): adapt-typed-plugins, a native Plugin.
      Plugin<Object?>(
        id: 'legend-hit-box',
        afterDraw: (chart, _, _) {
          final ctx = chart.ctx!
            ..save()
            ..strokeStyle = const native_ui.Color(0xff008000)
            ..lineWidth = 1;

          final legend = chart.legend! as Legend;
          for (final box in legend.legendHitBoxes) {
            ctx.strokeRect(box.left, box.top, box.width, box.height);
          }

          ctx.restore();
        },
      ),
    ],
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/9278',
  options: AcquireOptions(canvas: HarnessCanvas(width: 400, height: 300)),
);
