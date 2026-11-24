// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-animation.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `drawImage(canvas, ...)` takes the image source of the canvas layer,
/// read at the place of the upstream call (`toImageSource()` of
/// `UiCanvasElement`).
FixtureConfig fixture() {
  final canvas = document.createElement<HTMLCanvasElement>('canvas')
    ..width = 512
    ..height = 512;
  final ctx = canvas.getContext('2d')!;

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        DoughnutDataset(
          data: <num?>[1, 5, 10, 50, 100],
          backgroundColor: .indexed(<ChartPaint>[
            ChartPaint.solid(Color(0xCCFF6384)),
            ChartPaint.solid(Color(0xCC36A2EB)),
            ChartPaint.solid(Color(0xCCFFCE56)),
            ChartPaint.solid(Color(0xCC4BC0C0)),
            ChartPaint.solid(Color(0xCC9966FF)),
          ]),
          borderWidth: 4,
          borderColor: .indexed(<ChartPaint>[
            ChartPaint.solid(Color(0xFFFF6384)),
            ChartPaint.solid(Color(0xFF36A2EB)),
            ChartPaint.solid(Color(0xFFFFCE56)),
            ChartPaint.solid(Color(0xFF4BC0C0)),
            ChartPaint.solid(Color(0xFF9966FF)),
          ]),
        ),
      ],
      labels: <Object>['A', 'B', 'C', 'D', 'E'],
      responsive: false,
      disabledPlugins: [
        PluginOff<LegendPlugin>(),
        PluginOff<TitlePlugin>(),
        PluginOff<TooltipPlugin>(),
        PluginOff<FillerPlugin>(),
      ],
      plugins: [
        // DIVERGES(chartjs): adapt-typed-plugins, a native Plugin.
        Plugin<Object?>(
          id: 'hide',
          afterInit: (chart, _, _) {
            (chart as Chart).toggleDataVisibility(4);
          },
        ),
      ],
      extra: <String, Object?>{
        'animation': <String, Object?>{
          'duration': 8000,
          // DIVERGES(chartjs): adapt-flutter-curves, the curve.
          'easing': Curves.linear,
        },
      },
    ),
    options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
    run: (chart) {
      // `const animator = Chart.animator`: the singleton `animator` of
      // core.animator.dart.
      final anims = animator.getAnims(chart);
      // disable animator
      final backup = animator.refresh;
      animator.refresh = () {};

      final completer = Completer<void>();
      requestAnimFrame(() {
        final start = anims.items[0].start;
        for (var i = 0.0; i < 16; i++) {
          animator.update(start + i * 500);
          final x = i.remainder(4) * 128;
          final y = (i / 4).floorToDouble() * 128;
          ctx.drawImage(
            (chart.canvas! as UiCanvasElement).toImageSource(),
            x,
            y,
            128,
            128,
          );
        }
        clearCanvas(chart.canvas);
        chart.ctx!.drawImage((canvas as UiCanvasElement).toImageSource(), 0, 0);

        animator.refresh = backup;
        completer.complete();
      });
      return completer.future;
    },
  );
}
