// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.doughnut/doughnut-hidden.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/core/core.controller.dart';

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
          'borderWidth': 4,
          'borderColor': <Object?>[
            'rgb(255, 99, 132)',
            'rgb(54, 162, 235)',
            'rgb(255, 206, 86)',
            'rgb(75, 192, 192)',
            'rgb(153, 102, 255)',
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
    'plugins': <Object?>[
      <String, Object?>{
        'id': 'hide',
        'afterInit': (Object? chart) {
          (chart! as Chart).toggleDataVisibility(4);
        },
      },
    ],
  },
};
