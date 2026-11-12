// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/boundary/above-below-line-null.json (MIT, Chart.js Contributors).
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
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '10',
        '11',
        '12',
        '13',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'borderColor': 'rgb(42, 90, 145)',
          'data': <Object?>[
            4,
            12,
            30,
            36,
            45,
            53,
            68,
            79,
            null,
            95,
            18,
            null,
            18,
            180,
          ],
          'fill': <String, Object?>{
            'target': '+1',
            'above': 'rgba(4, 142, 43, 0.5)',
            'below': 'rgba(241, 49, 34, 0.5)',
          },
        },
        <String, Object?>{
          'borderColor': '#00ADEE',
          'data': <Object?>[
            0,
            0,
            0,
            0,
            0,
            0,
            20,
            108,
            null,
            72,
            72,
            null,
            72,
            72,
          ],
          'fill': false,
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'spanGaps': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'display': false,
        },
        'y': <String, Object?>{
          'display': false,
        },
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{
          'radius': 0,
        },
        'line': <String, Object?>{
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': const MonotoneCubicInterpolationMode(),
          'borderColor': 'transparent',
        },
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
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
