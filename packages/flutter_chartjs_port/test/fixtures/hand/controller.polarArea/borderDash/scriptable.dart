// Ported from Chart.js v4.6.1 test/fixtures/controller.polarArea/borderDash/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'polarArea',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[5, 2, 4, 7, 6, 8],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'arc': <String, Object?>{
          'backgroundColor': 'transparent',
          'borderColor': 'black',
          'borderWidth': 1,
          'borderDash': (Object? ctx) {
            final value = jsOrZero(jsGet(ctx, 'dataIndex')).remainder(2);
            return value == 0 ? <Object?>[3, 3] : <Object?>[];
          },
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
