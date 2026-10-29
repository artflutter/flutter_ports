// Ported from Chart.js v4.6.1 test/fixtures/scale.radialLinear/ticks-below-zero.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

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
          'min': -1,
          'max': 1,
          'grid': <String, Object?>{
            'display': true,
            'color': 'blue',
            'lineWidth': 2,
          },
          'angleLines': <String, Object?>{
            'color': 'rgba(255, 255, 255, 0.5)',
            'lineWidth': 2,
          },
          'pointLabels': <String, Object?>{
            'display': false,
          },
          'ticks': <String, Object?>{
            'display': true,
            'autoSkip': false,
            'stepSize': 0.2,
            'callback': (Object? value) {
              if (value == 0.8) {
                return 'Strong';
              }
              if (value == 0.4) {
                return 'Weak';
              }
              if (value == 0) {
                return 'No';
              }
              // The JS function ends without a return: undefined.
              return undefined;
            },
          },
        },
      },
    },
  },
};
