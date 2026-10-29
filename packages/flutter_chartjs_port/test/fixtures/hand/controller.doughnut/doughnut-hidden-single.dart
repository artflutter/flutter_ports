// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-hidden-single.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
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
        },
        <String, Object?>{
          'data': <Object?>[1, 5, 10, 50, 100],
          'backgroundColor': <Object?>[
            'rgba(255, 99, 132, 0.8)',
            'rgba(54, 162, 235, 0.8)',
            'rgba(255, 206, 86, 0.8)',
            'rgba(75, 192, 192, 0.8)',
            'rgba(153, 102, 255, 0.8)',
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
        'filler': false,
      },
    },
  },
  'options': <String, Object?>{
    'run': (Chart chart) {
      chart
        ..hide(0, 4)
        ..hide(1, 2);
    },
  },
};
