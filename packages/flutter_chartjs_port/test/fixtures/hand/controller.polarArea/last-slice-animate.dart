// Ported from Chart.js v4.6.1 test/fixtures/controller.polarArea/last-slice-animate.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart';

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
      'type': 'polarArea',
      'data': <String, Object?>{
        'labels': <Object?>['A'],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[20],
            'backgroundColor': 'red',
          },
        ],
      },
      'options': <String, Object?>{
        'animation': <String, Object?>{
          'duration': 0,
          'easing': 'linear',
        },
        'responsive': false,
        'plugins': <String, Object?>{
          'legend': false,
          'title': false,
          'tooltip': false,
          'filler': false,
        },
        'scales': <String, Object?>{
          'r': <String, Object?>{
            'ticks': <String, Object?>{
              'display': false,
            },
          },
        },
      },
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{
        'height': 512,
        'width': 512,
      },
      'run': (Chart chart) {
        (chart.options['animation']! as Map<String, Object?>)['duration'] =
            8000;
        chart
          ..toggleDataVisibility(0)
          ..update();
        // `const animator = Chart.animator`: the singleton `animator` of
        // core.animator.dart.
        // disable animator
        final backup = animator.refresh;
        animator.refresh = () {};

        final completer = Completer<void>();
        requestAnimFrame(() {
          final anims = animator.getAnims(chart);
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
