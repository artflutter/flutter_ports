// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-rotation-circumference-8x8.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native paint inputs.
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:async';
import 'dart:ui' as native_ui;

import 'package:chartjs_test_utils/flutter.dart';
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
      events: <String>[],
      extra: <String, Object?>{'rotation': -360, 'circumference': 180},
    ),
    options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 512)),
    run: (chart) {
      final completer = Completer<void>();
      for (var i = 0.0; i < 64; i++) {
        final col = i.remainder(8);
        final row = (i / 8).floorToDouble();
        final evenodd = jsTruthy(row.remainder(2)) ? 1 : -1;
        chart.options['rotation'] = col * 45 * evenodd;
        chart.options['circumference'] = 360 - row * 45;
        chart.update();
        ctx.drawImage(
          (chart.canvas! as UiCanvasElement).toImageSource(),
          col * 64,
          row * 64,
          64,
          64,
        );
      }
      ctx
        ..strokeStyle = const native_ui.Color(0xffff0000)
        ..lineWidth = 0.5
        ..beginPath();
      for (var i = 1.0; i < 8; i++) {
        ctx
          ..moveTo(i * 64, 0)
          ..lineTo(i * 64, 511)
          ..moveTo(0, i * 64)
          ..lineTo(511, i * 64);
      }
      ctx.stroke();
      clearCanvas(chart.canvas);
      chart.ctx!.drawImage((canvas as UiCanvasElement).toImageSource(), 0, 0);
      completer.complete();
      return completer.future;
    },
  );
}
