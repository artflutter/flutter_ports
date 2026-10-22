// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.radar/rotation/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[0, 5, 10, null, -10, -5],
          'pointBorderColor': '#0000ff',
          'pointRotation': (Object? ctx) {
            final value = jsOrZero(
              jsGet(
                jsGet(jsGet(ctx, 'dataset'), 'data'),
                jsGet(ctx, 'dataIndex'),
              ),
            );
            return value > 4
                ? 120
                : value > -4
                ? 60
                : 0;
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[4, -5, -10, null, 10, 5],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'fill': false,
        },
        'point': <String, Object?>{
          'borderColor': '#ff0000',
          'rotation': (Object? ctx) {
            final value = jsOrZero(
              jsGet(
                jsGet(jsGet(ctx, 'dataset'), 'data'),
                jsGet(ctx, 'dataIndex'),
              ),
            );
            return value > 4
                ? 0
                : value > -4
                ? 60
                : 120;
          },
          'pointStyle': 'line',
          'radius': 10,
        },
      },
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'display': false,
          'min': -15,
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
