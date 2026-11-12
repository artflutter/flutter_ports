// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/fixtures/pan/category-x-50.js (MIT, chartjs-plugin-zoom contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show Mode, PanAmount, ZoomChart;
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_chartjs_port/helpers.dart' show clearCanvas;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet, jsToNumber;

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
            'backgroundColor': (Object? c) =>
                jsToNumber(jsGet(c, 'index')) < 50 ? 'blue' : 'red',
          },
        ],
      },
      'options': <String, Object?>{
        'events': <Object?>[],
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'display': false,
            'min': 'Label 50',
            'max': 'Label 100',
          },
          'y': <String, Object?>{'display': false, 'max': 10},
        },
        'plugins': <String, Object?>{
          'legend': false,
          'tooltip': false,
          'zoom': <String, Object?>{
            // DIVERGES(zoom): adapt-zoom-option-enums, the enum value.
            'pan': <String, Object?>{'enabled': true, 'mode': Mode.x},
          },
        },
        'layout': <String, Object?>{'padding': const EdgeInsets.all(2)},
      },
    },
    'options': <String, Object?>{
      'run': (Chart chart) {
        const steps = 16;
        for (var i = 0; i < steps; i++) {
          chart
            ..pan(const PanAmount(x: 25))
            ..update();
          // DIVERGES(zoom): harness-fixture-observations, for the sprite.
          snapshot(chart);
        }
        clearCanvas(chart.canvas);
        // chart.ctx.drawImage(canvas, 0, 0): image only.
      },
    },
  };
}
