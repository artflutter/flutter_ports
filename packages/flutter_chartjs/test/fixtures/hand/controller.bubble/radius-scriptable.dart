// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bubble/radius-scriptable.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bubble',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 0},
            <String, Object?>{'x': 1, 'y': 0},
            <String, Object?>{'x': 2, 'y': 0},
            <String, Object?>{'x': 3, 'y': 0},
            <String, Object?>{'x': 4, 'y': 0},
            <String, Object?>{'x': 5, 'y': 0},
          ],
          'radius': (Object? ctx) {
            return jsToNumber(
                  jsGet(
                    jsGet(
                      jsGet(jsGet(ctx, 'dataset'), 'data'),
                      jsGet(ctx, 'dataIndex'),
                    ),
                    'x',
                  ),
                ) *
                4;
          },
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
