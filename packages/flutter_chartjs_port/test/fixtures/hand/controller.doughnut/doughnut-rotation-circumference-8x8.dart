// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.doughnut/doughnut-rotation-circumference-8x8.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `drawImage(canvas, ...)` takes the image source of the canvas layer,
/// read at the place of the upstream call (`toImageSource()` of
/// `UiCanvasElement`).
Map<String, Object?> fixture() {
  final canvas = document.createElement<HTMLCanvasElement>('canvas')
    ..width = 512
    ..height = 512;
  final ctx = canvas.getContext('2d')!;

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'doughnut',
      'data': <String, Object?>{
        'labels': <Object?>['A', 'B', 'C', 'D', 'E'],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[1, 5, 10, 50, 100],
            'backgroundColor': <Object?>[
              'rgba(255, 99, 132, 0.8)',
              'rgba(54, 162, 235, 0.8)',
              'rgba(255, 206, 86, 0.8)',
              'rgba(75, 192, 192, 0.8)',
              'rgba(153, 102, 255, 0.8)',
            ],
            'borderColor': <Object?>[
              'rgb(255, 99, 132)',
              'rgb(54, 162, 235)',
              'rgb(255, 206, 86)',
              'rgb(75, 192, 192)',
              'rgb(153, 102, 255)',
            ],
          },
        ],
      },
      'options': <String, Object?>{
        'rotation': -360,
        'circumference': 180,
        'events': <Object?>[],
      },
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{
        'height': 512,
        'width': 512,
      },
      'run': (Chart chart) {
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
          ..strokeStyle = 'red'
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
        chart.ctx!.drawImage(
          (canvas as UiCanvasElement).toImageSource(),
          0,
          0,
        );
        completer.complete();
        return completer.future;
      },
    },
  };
}
