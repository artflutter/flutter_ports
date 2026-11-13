// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/radar/boundary/start.json (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'rgba(0, 0, 255, 0.25)',
          'data': <Object?>[null, null, 2, 3, 4, -4, -2, 1, 0],
        },
        <String, Object?>{
          'backgroundColor': 'rgba(0, 255, 0, 0.25)',
          'data': <Object?>[6, 2, null, 4, 5, null, null, 2, 1],
        },
        <String, Object?>{
          'backgroundColor': 'rgba(255, 0, 0, 0.25)',
          'data': <Object?>[7, 3, 4, 5, 6, 1, 4, null, null],
        },
        <String, Object?>{
          'backgroundColor': 'rgba(0, 0, 255, 0.25)',
          'data': <Object?>[8, 7, 6, -6, -4, -6, 4, 5, 8],
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'spanGaps': false,
      'plugins': <String, Object?>{'legend': false, 'title': false},
      'scales': <String, Object?>{
        'r': <String, Object?>{'display': false},
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{'radius': 0},
        'line': <String, Object?>{
          'borderColor': 'transparent',
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toStart,
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 256},
  },
};
