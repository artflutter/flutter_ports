// Ported from Chart.js v4.5.1+7169e651 test/fixtures/core.layouts/hidden-vertical-boxes.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/js/js_number.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[10, 5, 0, 25, 78, -10],
        },
      ],
      'labels': <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5', ''],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': false,
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'display': false,
        },
        'y': <String, Object?>{
          'type': 'linear',
          'position': 'left',
          'ticks': <String, Object?>{
            'callback': (Object? value) {
              return jsAdd(value, ' very long unit!');
            },
          },
        },
        'y1': <String, Object?>{
          'type': 'linear',
          'position': 'left',
          'display': false,
        },
        'y2': <String, Object?>{
          'type': 'linear',
          'position': 'left',
          'display': false,
        },
        'y3': <String, Object?>{
          'type': 'linear',
          'position': 'left',
          'display': false,
        },
        'y4': <String, Object?>{
          'type': 'linear',
          'position': 'left',
          'display': false,
        },
        'y5': <String, Object?>{
          'type': 'linear',
          'position': 'left',
          'display': false,
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'height': 256,
      'width': 256,
    },
  },
};
