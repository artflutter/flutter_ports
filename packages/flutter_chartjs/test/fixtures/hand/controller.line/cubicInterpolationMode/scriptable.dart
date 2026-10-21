// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/cubicInterpolationMode/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[0, 4, 2, 6, 4, 8],
          'borderColor': '#ff0000',
          'cubicInterpolationMode': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0 ? 'monotone' : 'default';
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[2, 6, 4, 8, 6, 10],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': '#00ff00',
          'borderWidth': 20,
          'cubicInterpolationMode': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0 ? 'monotone' : 'default';
          },
          'fill': false,
          'tension': 0.4,
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
