// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/above-below-vertical-linechart.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[
        1,
        2,
        3,
        4,
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            200,
            400,
            200,
            400,
          ],
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': const MonotoneCubicInterpolationMode(),
          'tension': 0.4,
          'spanGaps': true,
          'borderColor': 'blue',
          'pointRadius': 0,
          'fill': <String, Object?>{
            'target': 1,
            'below': 'rgba(255, 0, 0, 0.4)',
            'above': 'rgba(53, 221, 53, 0.4)',
          },
        },
        <String, Object?>{
          'data': <Object?>[
            400,
            200,
            400,
            200,
          ],
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': const MonotoneCubicInterpolationMode(),
          'tension': 0.4,
          'spanGaps': true,
          'borderColor': 'orange',
          'pointRadius': 0,
        },
      ],
    },
    'options': <String, Object?>{
      'indexAxis': 'y',
      'plugins': <String, Object?>{
        'filler': <String, Object?>{
          'propagate': false,
        },
        'datalabels': <String, Object?>{
          'display': false,
        },
        'legend': <String, Object?>{
          'display': false,
        },
      },
    },
  },
};
