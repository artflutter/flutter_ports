// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/fill/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `ctx.datasetIndex === 0 ? true : false` (:12, :26) is the comparison
/// itself: the result is the same boolean.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[-2, -6, -4, -8, -6, -10],
          'backgroundColor': '#ff0000',
          'fill': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0;
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[0, 4, 2, 6, 4, 8],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'backgroundColor': '#00ff00',
          'fill': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0;
          },
        },
      },
      'layout': <String, Object?>{
        'padding': 32,
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
        'filler': true,
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
