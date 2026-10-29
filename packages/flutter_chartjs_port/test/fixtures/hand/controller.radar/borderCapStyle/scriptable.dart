// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/borderCapStyle/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[null, 3, 3],
          'borderCapStyle': (Object? ctx) {
            final index = jsToNumber(jsGet(ctx, 'datasetIndex')).remainder(2);
            return index == 0
                ? 'round'
                : index == 1
                ? 'square'
                : 'butt';
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[null, 2, 2],
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[null, 1, 1],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderCapStyle': (Object? ctx) {
            final index = jsToNumber(jsGet(ctx, 'datasetIndex')).remainder(3);
            return index == 0
                ? 'round'
                : index == 1
                ? 'square'
                : 'butt';
          },
          'borderColor': '#ff0000',
          'borderWidth': 32,
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
          'beginAtZero': true,
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
