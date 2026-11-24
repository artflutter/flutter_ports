// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/event-replay.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native paint inputs.
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:math' as math;
import 'dart:ui';
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
  // DIVERGES(chartjs): adapt-offset-points, the center is an Offset.
  void drawMousePoint(CanvasRenderingContext2D ctx, Offset center) {
    ctx
      ..beginPath()
      ..arc(center.dx, center.dy, 8, 0, math.pi * 2)
      ..fillStyle = const native_ui.Color(0xffffff00)
      ..fill();
  }

  final canvas = document.createElement<HTMLCanvasElement>('canvas')
    ..width = 512
    ..height = 512;
  final ctx = canvas.getContext('2d')!;

  return FixtureConfig.typed(
    ChartConfig(
      datasets: [
        PieDataset(
          backgroundColor: .indexed(<ChartPaint>[
            ChartPaint.solid(Color(0xFFFF0000)),
            ChartPaint.solid(Color(0xFF008000)),
            ChartPaint.solid(Color(0xFF0000FF)),
          ]),
          hoverBackgroundColor: .constant(ChartPaint.solid(Color(0xFF000000))),
          data: <num?>[1, 1, 1],
        ),
      ],
    ),
    options: <String, Object?>{
      'canvas': <String, Object?>{'width': 512, 'height': 512},
      'run': (Chart chart) async {
        ctx.drawImage(
          (chart.canvas! as UiCanvasElement).toImageSource(),
          0,
          0,
          256,
          256,
        );

        // `getCenterPoint` is a member of the arc element: the cast gives
        // the element class of the `pie` dataset.
        final arc = chart.getDatasetMeta(0).data[0] as ArcElement;
        final center = arc.getCenterPoint();
        await triggerMouseEvent(chart, 'mousemove', arc);
        drawMousePoint(chart.ctx!, center);
        ctx.drawImage(
          (chart.canvas! as UiCanvasElement).toImageSource(),
          256,
          0,
          256,
          256,
        );

        chart
          ..toggleDataVisibility(0)
          ..update();
        drawMousePoint(chart.ctx!, center);
        ctx.drawImage(
          (chart.canvas! as UiCanvasElement).toImageSource(),
          0,
          256,
          256,
          256,
        );

        await triggerMouseEvent(chart, 'mouseout', arc);
        ctx.drawImage(
          (chart.canvas! as UiCanvasElement).toImageSource(),
          256,
          256,
          256,
          256,
        );

        clearCanvas(chart.canvas);
        chart.ctx!.drawImage((canvas as UiCanvasElement).toImageSource(), 0, 0);
      },
    },
  );
}
