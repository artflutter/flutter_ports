// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 test/fixtures/zoom/drag.js (MIT, chartjs-plugin-zoom contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/chartjs.dart' show Chart;

import '../../../flutter_test_config.dart' show triggerMouseEvent;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[];
  for (var i = 0; i < 100; i++) {
    data.add(<String, Object?>{
      'x': i,
      // js-ok: data of a hidden scale with the nice bounds -10 and 10.
      'y': math.sin((i / 25) * math.pi) * 10,
    });
  }

  return <String, Object?>{
    'tolerance': 0.004,
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{'data': data, 'borderColor': 'red'},
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{'type': 'linear', 'display': false},
          'y': <String, Object?>{'display': false},
        },
        'plugins': <String, Object?>{
          'legend': false,
          'zoom': <String, Object?>{
            'zoom': <String, Object?>{
              'drag': <String, Object?>{
                'enabled': true,
                'backgroundColor': 'yellow',
                'borderColor': 'black',
                'borderWidth': 1,
              },
            },
          },
        },
        'layout': <String, Object?>{'padding': 2},
      },
    },
    'options': <String, Object?>{
      'run': (Chart chart) {
        final scaleX = chart.scales['x']!;
        final scaleY = chart.scales['y']!;
        triggerMouseEvent(chart, 'mousedown', (
          x: scaleX.getPixelForValue(5),
          y: scaleY.getPixelForValue(10),
        ));
        triggerMouseEvent(chart, 'mousemove', (
          x: scaleX.getPixelForValue(60),
          y: scaleY.getPixelForValue(0),
        ));
        // DIVERGES(zoom): harness-fixture-observations, render stays.
      },
    },
  };
}
