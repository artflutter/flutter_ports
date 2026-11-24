// Ported from Chart.js v4.6.1 test/fixtures/controller.polarArea/pointLabels/overlapping.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      PolarAreaDataset(
        backgroundColor: .indexed(<ChartPaint>[
          ChartPaint.solid(Color(0x33FF0000)),
          ChartPaint.solid(Color(0x3300FF00)),
          ChartPaint.solid(Color(0x330000FF)),
          ChartPaint.solid(Color(0x33000000)),
        ]),
        extra: <String, Object?>{
          'data': List<Object?>.filled(50, 5, growable: true),
        },
      ),
    ],
    labels: <Object>[
      for (final (i, _) in List<Object?>.filled(50, 0).indexed)
        <Object?>['label $i', 'line 2'],
    ],
    scales: [RadialLinearAxis(pointLabelsDisplay: ScaleDisplay.on)],
  ),
  options: <String, Object?>{
    'spriteText': true,
    'run': (Chart chart) {
      // Avoid browser-specific interpolation of the overlapping text sprites.
      // DIVERGES(chartjs): harness-fixture-sources, no imageSmoothingEnabled.
      // `chart.ctx.imageSmoothingEnabled = false`: the canvas layer has no
      // `imageSmoothingEnabled`. The port draws no text sprite
      // (`spriteText` is n/a, Chart.js ADR 0022 section 4 item 5) and
      // compares no image (Chart.js ADR 0034), so the write has no effect.
      chart.draw();
    },
  },
);
