// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/fixtures/zoom/zoom-reset.js (MIT, chartjs-plugin-zoom contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show Mode, ZoomChart;
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_chartjs_port/helpers.dart' show clearCanvas;

import '../../../flutter_test_config.dart' show triggerWheelEvent;
import '../../observe.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final labels = <Object?>[];
  final data = <Object?>[];
  for (var i = 1; i <= 100; i++) {
    labels.add('Label $i');
    data.add(math.sin((i / 100) * math.pi) * 10);
  }

  // DIVERGES(zoom): harness-fixture-observations, no sprite canvas.

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'bar',
      'data': <String, Object?>{
        'labels': labels,
        'datasets': <Object?>[
          <String, Object?>{
            'data': data,
            'barPercentage': 1,
            'categoryPercentage': 1,
            'backgroundColor': 'red',
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{'display': false},
          'y': <String, Object?>{'display': false},
        },
        'plugins': <String, Object?>{
          'legend': false,
          'zoom': <String, Object?>{
            'zoom': <String, Object?>{
              'wheel': <String, Object?>{'enabled': true},
              // DIVERGES(zoom): adapt-zoom-option-enums, the enum value.
              'mode': Mode.x,
            },
          },
        },
        'layout': <String, Object?>{'padding': const EdgeInsets.all(2)},
      },
    },
    'options': <String, Object?>{
      'run': (Chart chart) {
        const steps = 4;
        for (var i = 0; i < steps; i++) {
          if (i > 0 && i < steps - 1) {
            triggerWheelEvent(chart, x: 255, y: 255, deltaY: -100);
          } else {
            chart.resetZoom();
          }
          // DIVERGES(zoom): harness-fixture-observations, for the sprite.
          snapshot(chart);
        }

        clearCanvas(chart.canvas);
        // chart.ctx.drawImage(canvas, 0, 0): image only.
      },
    },
  };
}
