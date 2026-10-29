// Ported from Chart.js v4.6.1 test/fixtures/scale.category/invalid-data.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f', 'g'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 'a', 'y': 1},
            <String, Object?>{'x': null, 'y': 1},
            <String, Object?>{'x': 2, 'y': 1},
            <String, Object?>{'x': undefined, 'y': 1},
            <String, Object?>{'x': 4, 'y': 1},
            <String, Object?>{'x': double.nan, 'y': 1},
            <String, Object?>{'x': 6, 'y': 1},
          ],
          'backgroundColor': 'red',
          'borderColor': 'red',
          'borderWidth': 5,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'y': <String, Object?>{
          'display': false,
        },
        'x': <String, Object?>{
          'grid': <String, Object?>{
            'display': false,
          },
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'width': 256,
      'height': 256,
    },
  },
};
