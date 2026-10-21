// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/borderJoinStyle/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[6, 18, 6],
          'borderColor': '#ff0000',
          'borderJoinStyle': (Object? ctx) {
            final index = jsToNumber(jsGet(ctx, 'datasetIndex')).remainder(3);
            return index == 0
                ? 'round'
                : index == 1
                ? 'miter'
                : 'bevel';
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[2, 14, 2],
          'borderColor': '#0000ff',
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[-2, 10, -2],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': '#00ff00',
          'borderJoinStyle': (Object? ctx) {
            final index = jsToNumber(jsGet(ctx, 'datasetIndex')).remainder(3);
            return index == 0
                ? 'round'
                : index == 1
                ? 'miter'
                : 'bevel';
          },
          'borderWidth': 25,
          'fill': false,
          'tension': 0,
        },
      },
      'layout': <String, Object?>{
        'padding': 32,
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
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
