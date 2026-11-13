// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-outer-radius-percent.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/radius_length.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
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
      // DIVERGES(chartjs): adapt-length-objects, the length
      // class.
      'radius': const PercentRadius(30),
    },
  },
};
