// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/points-outside-canvas-update.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The write `chart.scales.x.options.min = 5` of the `run` hook is the
/// write through `operator []=` of the option resolver, the `set` trap of
/// upstream.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/8699',
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'red',
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 3},
            <String, Object?>{'x': 2, 'y': -3},
            <String, Object?>{'x': 4, 'y': 0},
            <String, Object?>{'x': 6, 'y': 5},
            <String, Object?>{'x': 8, 'y': -5},
            <String, Object?>{'x': 10, 'y': 0},
          ],
          'fill': 'origin',
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{'legend': false, 'title': false},
      'scales': <String, Object?>{
        'x': <String, Object?>{'type': 'linear', 'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'run': (Chart chart) {
      chart.scales['x']!.options['min'] = 5;
      chart.update();
    },
  },
};
