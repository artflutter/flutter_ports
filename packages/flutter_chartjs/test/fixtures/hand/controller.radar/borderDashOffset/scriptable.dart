// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.radar/borderDashOffset/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[1, 1, 1, 1],
          'borderColor': '#ff0000',
          'borderDash': <Object?>[20],
          'borderDashOffset': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0 ? 5.0 : 0.0;
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[0, 0, 0, 0],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': '#00ff00',
          'borderDash': <Object?>[20],
          'borderDashOffset': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0 ? 5.0 : 0.0;
          },
          'fill': false,
        },
        'point': <String, Object?>{
          'radius': 10,
        },
      },
      'layout': <String, Object?>{
        'padding': 32,
      },
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'display': false,
          'min': -1,
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'height': 512,
      'width': 512,
    },
  },
};
