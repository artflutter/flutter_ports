// Ported from Chart.js v4.5.1+7169e651 test/fixtures/scale.radialLinear/pointLabels/scriptable-color-small.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>[
        'Red',
        'Blue',
        'Yellow',
        'Green',
        'Purple',
        'Orange',
        'Red',
        'Blue',
        'Yellow',
        'Green',
        'Purple',
        'Orange',
        'Red',
        'Blue',
        'Yellow',
        'Green',
        'Purple',
        'Orange',
        'Red',
        'Blue',
        'Yellow',
        'Green',
        'Purple',
        'Orange',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'label': '# of Votes',
          'data': <Object?>[
            12,
            19,
            3,
            5,
            1,
            3,
            12,
            19,
            3,
            5,
            1,
            3,
            12,
            19,
            3,
            5,
            1,
            3,
            12,
            19,
            3,
            5,
            1,
            3,
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'ticks': <String, Object?>{
            'display': false,
          },
          'angleLines': <String, Object?>{
            'color': (Object? ctx) {
              return jsToNumber(jsGet(ctx, 'index')).remainder(2) == 0
                  ? 'green'
                  : 'red';
            },
          },
          'pointLabels': <String, Object?>{
            'display': false,
          },
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'width': 300,
  },
};
