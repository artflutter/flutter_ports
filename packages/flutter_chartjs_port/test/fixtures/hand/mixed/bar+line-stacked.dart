// Ported from Chart.js v4.6.1 test/fixtures/mixed/bar+line-stacked.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'stack': 'mixed',
          'data': <Object?>[
            5,
            20,
            1,
            10,
          ],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
        },
        <String, Object?>{
          'type': 'line',
          'stack': 'mixed',
          'data': <Object?>[
            6,
            16,
            3,
            19,
          ],
          'borderColor': '#0000ff',
          'fill': false,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          // DIVERGES(chartjs): adapt-axis-objects, the axis
          // class.
          'axis': const YAxis(),
          'labels': <Object?>[
            'a',
            'b',
            'c',
            'd',
          ],
        },
        'y': <String, Object?>{
          'stacked': true,
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'height': 256,
      'width': 512,
    },
  },
};
