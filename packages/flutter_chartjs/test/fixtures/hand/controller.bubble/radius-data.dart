// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bubble/radius-data.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/js/js_undefined.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bubble',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 5, 'r': 1},
            <String, Object?>{'x': 1, 'y': 4, 'r': 2},
            <String, Object?>{'x': 2, 'y': 3, 'r': 6},
            <String, Object?>{'x': 3, 'y': 2},
            <String, Object?>{'x': 4, 'y': 1, 'r': 2},
            <String, Object?>{'x': 5, 'y': 0, 'r': double.nan},
            <String, Object?>{'x': 6, 'y': -1, 'r': undefined},
            <String, Object?>{'x': 7, 'y': -2, 'r': null},
            <String, Object?>{'x': 8, 'y': -3, 'r': '4'},
            <String, Object?>{'x': 9, 'y': -4, 'r': '4px'},
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{
          'backgroundColor': '#444',
          'radius': 10,
        },
      },
      'layout': <String, Object?>{
        'padding': <String, Object?>{
          'left': 24,
          'right': 24,
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'height': 128,
      'width': 256,
    },
  },
};
