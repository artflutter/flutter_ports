// Ported from Chart.js v4.6.1 test/fixtures/core.scale/ticks/skip-by-callback.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/8892',
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[12, 19, 3, 5, 2, 3],
        },
        <String, Object?>{
          'data': <Object?>[7, 11, 5, 8, 3, 7],
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'ticks': <String, Object?>{
            // A TickCallback (row adapt-native-tick): the scale is the
            // first parameter, and null stands for `undefined` and `null`.
            'callback': (Scale scale, double val, int index, Object? ticks) {
              if (index == 1) {
                return null;
              }
              if (index == 3) {
                return null;
              }
              return <String>[jsToString(scale.getLabelForValue(val))];
            },
          },
        },
        'y': <String, Object?>{
          'ticks': <String, Object?>{
            'callback': (Object? scale, double val, int index, Object? ticks) {
              return index.remainder(2) == 0
                  ? <String>[jsNumberToString(val)]
                  : null;
            },
          },
        },
      },
    },
  },
  'options': <String, Object?>{'spriteText': true},
};
