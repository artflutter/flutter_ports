// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/before-dataset-draw.js (MIT, Chart.js Contributors).
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
        '15:00',
        '16:00',
        '17:00',
        '18:00',
        '19:00',
        '20:00',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'borderColor': '#00ADEE80',
          'backgroundColor': '#00ADEE',
          'data': <Object?>[
            0,
            1,
            1,
            2,
            2,
            0,
          ],
        },
        <String, Object?>{
          'borderColor': '#BD262880',
          'backgroundColor': '#BD2628',
          'data': <Object?>[
            0,
            2,
            2,
            1,
            1,
            1,
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'borderWidth': 4,
      'fill': true,
      'radius': 20,
      'pointBackgroundColor': '#ffff',
      // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
      // class.
      'cubicInterpolationMode': const MonotoneCubicInterpolationMode(),
      'plugins': <String, Object?>{
        'legend': false,
        'filler': <String, Object?>{
          'drawTime': 'beforeDatasetDraw',
        },
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'display': false,
        },
        'y': <String, Object?>{
          'display': false,
        },
      },
    },
  },
};
