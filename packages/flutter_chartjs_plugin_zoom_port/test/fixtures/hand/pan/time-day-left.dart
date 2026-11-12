// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/fixtures/pan/time-day-left.js (MIT, chartjs-plugin-zoom contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show PanAmount, ZoomChart;
import 'package:flutter_chartjs_port/chartjs.dart' show Chart, TimeUnit;
import 'package:flutter_chartjs_port/helpers.dart' show clearCanvas;

import '../../observe.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  // DIVERGES(zoom): harness-fixture-observations, no sprite canvas.

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'bar',
      'data': <String, Object?>{
        // DIVERGES(zoom): harness-date-zone, a local Date in the zone UTC.
        'labels': <Object?>[
          DateTime.utc(2020, 1, 2),
          DateTime.utc(2020, 1, 3),
          DateTime.utc(2020, 1, 4),
          DateTime.utc(2020, 1, 5),
        ],
        'datasets': <Object?>[
          <String, Object?>{
            'backgroundColor': <Object?>['red', 'green', 'blue', 'orange'],
            'data': <Object?>[1, 2, 3, 4],
          },
        ],
      },
      'options': <String, Object?>{
        'animation': false,
        'events': <Object?>[],
        'scales': <String, Object?>{
          'y': <String, Object?>{'display': false, 'max': 5},
          'x': <String, Object?>{
            'type': 'time',
            // DIVERGES(zoom): harness-date-zone, a local Date in the zone UTC.
            'min': DateTime.utc(2020, 1, 3),
            'max': DateTime.utc(2020, 1, 5),
            'time': <String, Object?>{
              // DIVERGES(zoom): adapt-host-time-unit, the enum value.
              'unit': TimeUnit.day,
              'round': TimeUnit.day,
            },
          },
        },
        'plugins': <String, Object?>{
          'legend': false,
          'zoom': <String, Object?>{
            'pan': <String, Object?>{'enabled': true, 'mode': 'x'},
          },
        },
      },
    },
    'options': <String, Object?>{
      'spriteText': true,
      'run': (Chart chart) {
        const steps = 4;
        for (var i = 0; i < steps; i++) {
          if (i > 0) {
            chart
              ..pan(const PanAmount(x: 150))
              ..update();
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
