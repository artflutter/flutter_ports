// Ported from Chart.js v4.5.1+7169e651 test/fixtures/core.scale/ticks/skip-by-callback.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';

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
            'callback': JsFunction((Object? self, Object? val, Object? index) {
              if (index == 1) {
                return undefined;
              }
              if (index == 3) {
                return null;
              }
              return (self! as Scale).getLabelForValue(val);
            }),
          },
        },
        'y': <String, Object?>{
          'ticks': <String, Object?>{
            'callback': (Object? val, Object? index) {
              return jsToNumber(index).remainder(2) == 0
                  ? jsAdd('', val)
                  : null;
            },
          },
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
  },
};
