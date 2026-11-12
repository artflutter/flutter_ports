// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/legend-doughnut-point-style.json (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'doughnut',
    'data': <String, Object?>{
      'labels': <Object?>[
        '',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            10,
          ],
          'backgroundColor': '#00ff00',
          'borderWidth': 0,
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': <String, Object?>{
          'labels': <String, Object?>{
            // DIVERGES(chartjs): adapt-point-style-objects, the style
            // class.
            'pointStyle': const TrianglePointStyle(),
            'usePointStyle': true,
          },
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'height': 256,
      'width': 512,
    },
  },
};
