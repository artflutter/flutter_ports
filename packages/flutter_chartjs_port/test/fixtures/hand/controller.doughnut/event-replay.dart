// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.doughnut/event-replay.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element.arc.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `drawImage(canvas, ...)` takes the image source of the canvas layer,
/// read at the place of the upstream call (`toImageSource()` of
/// `UiCanvasElement`).
Map<String, Object?> fixture() {
  void drawMousePoint(CanvasRenderingContext2D ctx, ElementPoint center) {
    ctx
      ..beginPath()
      ..arc(center.x, center.y, 8, 0, math.pi * 2)
      ..fillStyle = 'yellow'
      ..fill();
  }

  final canvas = document.createElement<HTMLCanvasElement>('canvas')
    ..width = 512
    ..height = 512;
  final ctx = canvas.getContext('2d')!;

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'pie',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'backgroundColor': <Object?>['red', 'green', 'blue'],
            'hoverBackgroundColor': 'black',
            'data': <Object?>[1, 1, 1],
          },
        ],
      },
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{
        'width': 512,
        'height': 512,
      },
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
        chart.ctx!.drawImage(
          (canvas as UiCanvasElement).toImageSource(),
          0,
          0,
        );
      },
    },
  };
}
