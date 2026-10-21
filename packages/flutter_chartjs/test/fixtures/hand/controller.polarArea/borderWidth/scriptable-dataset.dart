// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.polarArea/borderWidth/scriptable-dataset.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'polarArea',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[0, 2, 4, null, 6, 8],
          'borderWidth': (Object? ctx) {
            final value = jsOrZero(
              jsGet(
                jsGet(jsGet(ctx, 'dataset'), 'data'),
                jsGet(ctx, 'dataIndex'),
              ),
            );
            return value.abs();
          },
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'arc': <String, Object?>{
          'backgroundColor': 'transparent',
          'borderColor': '#888',
        },
      },
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'display': false,
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
