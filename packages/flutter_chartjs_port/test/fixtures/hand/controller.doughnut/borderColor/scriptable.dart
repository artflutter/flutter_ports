// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/borderColor/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'doughnut',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[0, 2, 4, null, 6, 8],
          'borderColor': (Object? ctx) {
            final value = jsOrZero(
              jsGet(
                jsGet(jsGet(ctx, 'dataset'), 'data'),
                jsGet(ctx, 'dataIndex'),
              ),
            );
            return value > 8
                ? '#ff0000'
                : value > 6
                ? '#00ff00'
                : value > 2
                ? '#0000ff'
                : '#ff00ff';
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[0, 2, 4, null, 6, 8],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'arc': <String, Object?>{
          'backgroundColor': 'transparent',
          'borderColor': (Object? ctx) {
            final value = jsOrZero(
              jsGet(
                jsGet(jsGet(ctx, 'dataset'), 'data'),
                jsGet(ctx, 'dataIndex'),
              ),
            );
            return value > 8
                ? '#ff00ff'
                : value > 6
                ? '#0000ff'
                : value > 2
                ? '#ff0000'
                : '#00ff00';
          },
          'borderWidth': 8,
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
