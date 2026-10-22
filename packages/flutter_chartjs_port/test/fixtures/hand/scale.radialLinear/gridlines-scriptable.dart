// Ported from Chart.js v4.5.1+7169e651 test/fixtures/scale.radialLinear/gridlines-scriptable.js (MIT, Chart.js Contributors).
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
      'labels': <Object?>['A', 'B', 'C', 'D', 'E'],
    },
    'options': <String, Object?>{
      'responsive': false,
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'grid': <String, Object?>{
            'display': true,
            'color': (Object? context) {
              return jsToNumber(jsGet(context, 'index')).remainder(2) == 0
                  ? 'green'
                  : 'red';
            },
            'lineWidth': (Object? context) {
              return jsToNumber(jsGet(context, 'index')).remainder(2) == 0
                  ? 5
                  : 1;
            },
          },
          'angleLines': <String, Object?>{
            'color': 'rgba(255, 255, 255, 0.5)',
            'lineWidth': 2,
          },
          'pointLabels': <String, Object?>{
            'display': false,
          },
          'ticks': <String, Object?>{
            'display': false,
          },
        },
      },
    },
  },
};
