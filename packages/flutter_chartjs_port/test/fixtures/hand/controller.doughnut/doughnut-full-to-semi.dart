// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-full-to-semi.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/9832',
  'config': <String, Object?>{
    'type': 'doughnut',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'label': 'Set 1',
          'data': <Object?>[50, 50, 25],
          'backgroundColor': <Object?>['#BF616A', '#D08770', '#EBCB8B'],
          'borderWidth': 0,
        },
        <String, Object?>{
          'label': 'Se1 2',
          'data': <Object?>[50, 50, 25],
          'backgroundColor': <Object?>['#BF616A', '#D08770', '#EBCB8B'],
          'borderWidth': 0,
        },
      ],
    },
    'options': <String, Object?>{
      'rotation': -90,
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'width': 512,
      'height': 512,
    },
    'run': (Chart chart) {
      chart.options['circumference'] = 180;
      chart.update();
    },
  },
};
