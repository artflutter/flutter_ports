// Ported from Chart.js v4.6.1 test/fixtures/controller.line/borderDash/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[4, 5, 10, null, -10, -5],
          'borderDash': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0
                ? <Object?>[5]
                : <Object?>[10];
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[-4, -5, -10, null, 10, 5],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': '#00ff00',
          'borderDash': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0
                ? <Object?>[5]
                : <Object?>[10];
          },
        },
        'point': <String, Object?>{
          'radius': 10,
        },
      },
      'layout': <String, Object?>{
        'padding': 32,
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{
          'display': false,
          'beginAtZero': true,
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
