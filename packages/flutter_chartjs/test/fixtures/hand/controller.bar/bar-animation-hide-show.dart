// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bar/bar-animation-hide-show.js (MIT, Chart.js Contributors).
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
import 'package:flutter_chartjs/src/js/js_date.dart';

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
      'type': 'bar',
      'data': <String, Object?>{
        'labels': <Object?>[0],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[1],
            'backgroundColor': 'rgba(255,0,0,0.5)',
          },
          <String, Object?>{
            'data': <Object?>[2],
            'backgroundColor': 'rgba(0,0,255,0.5)',
          },
          <String, Object?>{
            'data': <Object?>[3],
            'backgroundColor': 'rgba(0,255,0,0.5)',
          },
        ],
      },
      'options': <String, Object?>{
        'animation': <String, Object?>{
          'duration': 14000,
          'easing': 'linear',
        },
        'events': <Object?>[],
        'scales': <String, Object?>{
          'x': <String, Object?>{'display': false},
          'y': <String, Object?>{'display': false, 'max': 4},
        },
      },
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
          // make sure previous animation is finished
          animator.update(jsDateNow() * 2);

          chart.hide(1);
          var start = anims.items[0].start;
          for (var i = 0.0; i < 8; i++) {
            animator.update(start + i * 2000);
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

          // make sure previous animation is finished
          animator.update(jsDateNow() * 2);

          chart.show(1);
          start = anims.items[0].start;
          for (var i = 0.0; i < 8; i++) {
            animator.update(start + i * 2000);
            final x = i.remainder(4) * 128;
            final y = (2 + i / 4).floorToDouble() * 128;
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
