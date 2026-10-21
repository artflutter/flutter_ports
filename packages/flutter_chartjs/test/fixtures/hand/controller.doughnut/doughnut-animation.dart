// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.doughnut/doughnut-animation.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart';
import 'package:flutter_chartjs/src/helpers/helpers.extras.dart';

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
            'borderWidth': 4,
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
        'animation': <String, Object?>{
          'duration': 8000,
          'easing': 'linear',
        },
        'responsive': false,
        'plugins': <String, Object?>{
          'legend': false,
          'title': false,
          'tooltip': false,
          'filler': false,
        },
      },
      'plugins': <Object?>[
        <String, Object?>{
          'id': 'hide',
          'afterInit': (Object? chart) {
            (chart! as Chart).toggleDataVisibility(4);
          },
        },
      ],
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{
        'height': 512,
        'width': 512,
      },
      'run': (Chart chart) {
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
          chart.ctx!.drawImage(
            (canvas as UiCanvasElement).toImageSource(),
            0,
            0,
          );

          animator.refresh = backup;
          completer.complete();
        });
        return completer.future;
      },
    },
  };
}
