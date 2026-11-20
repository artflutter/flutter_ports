// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/fixtures/pan/category-x-5.js (MIT, chartjs-plugin-zoom contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

import '../../../flutter_test_config.dart';
import '../../observe.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final labels = <Object?>[];
  final data = <Object?>[];
  for (var i = 1; i <= 100; i++) {
    labels.add('Label $i');
    data.add(sin((i / 100) * pi) * 10);
  }

  // DIVERGES(zoom): harness-fixture-observations, no sprite canvas.

  return <String, Object?>{
    'tolerance': 0.02,
    'config': <String, Object?>{
      'type': 'bar',
      'data': <String, Object?>{
        'labels': labels,
        'datasets': <Object?>[
          <String, Object?>{
            'data': data,
            'barPercentage': 1,
            'categoryPercentage': 1,
            'backgroundColor': (ScriptableContext c) =>
                c.index < 50 ? 'blue' : 'red',
          },
        ],
      },
      'options': <String, Object?>{
        'events': <Object?>[],
        'scales': <String, Object?>{
          'x': <String, Object?>{
            // DIVERGES(zoom): adapt-host-scale-display, the enum value.
            'display': ScaleDisplay.off,
            'min': 'Label 1',
            'max': 'Label 5',
          },
          // DIVERGES(zoom): adapt-host-scale-display, the enum value.
          'y': <String, Object?>{'display': ScaleDisplay.off, 'max': 10},
        },
        'plugins': <String, Object?>{
          'legend': false,
          'tooltip': false,
          'zoom': const ZoomPluginOptions(
            // DIVERGES(zoom): adapt-zoom-option-enums, the enum value.
            pan: PanOptions(enabled: true, mode: Mode.x),
          ),
        },
        'layout': <String, Object?>{'padding': const EdgeInsets.all(2)},
      },
    },
    'options': <String, Object?>{
      'spriteText': true,
      'run': (Chart chart) {
        const steps = 16;
        // new Promise((resolve) => {...})
        final promise = Completer<void>();
        var i = 0;
        void next() {
          if (i < steps) {
            i++;

            // DIVERGES(zoom): harness-fixture-observations, for the sprite.
            snapshot(chart);
            simulatePan(chart, deltaX: -350, done: next);
          } else {
            clearCanvas(chart.canvas);
            // chart.ctx.drawImage(canvas, 0, 0): image only.
            promise.complete();
          }
        }

        next();
        return promise.future;
      },
    },
  };
}
