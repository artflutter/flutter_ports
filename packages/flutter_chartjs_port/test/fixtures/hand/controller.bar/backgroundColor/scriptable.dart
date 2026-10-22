// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bar/backgroundColor/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[0, 5, 10, null, -10, -5],
          'backgroundColor': (Object? ctx) {
            final value = jsOrZero(
              jsGet(
                jsGet(jsGet(ctx, 'dataset'), 'data'),
                jsGet(ctx, 'dataIndex'),
              ),
            );
            return value > 8
                ? '#ff0000'
                : value > 0
                ? '#00ff00'
                : value > -8
                ? '#0000ff'
                : '#ff00ff';
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[0, 5, 10, null, -10, -5],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'bar': <String, Object?>{
          'backgroundColor': (Object? ctx) {
            final value = jsOrZero(
              jsGet(
                jsGet(jsGet(ctx, 'dataset'), 'data'),
                jsGet(ctx, 'dataIndex'),
              ),
            );
            return value > 8
                ? '#ff00ff'
                : value > 0
                ? '#0000ff'
                : value > -8
                ? '#ff0000'
                : '#00ff00';
          },
        },
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
