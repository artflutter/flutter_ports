// Ported from Chart.js v4.5.1+7169e651 test/fixtures/core.scale/grid/scriptable-borderDash.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'scatter',
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'position': <String, Object?>{'y': 0},
          'min': -10,
          'max': 10,
          'border': <String, Object?>{
            'dash': (Object? ctx) =>
                jsToNumber(jsGet(ctx, 'index')).remainder(2) == 0
                ? <Object?>[6, 3]
                : <Object?>[],
          },
          'grid': <String, Object?>{
            'color': 'lightGray',
            'lineWidth': 3,
          },
          'ticks': <String, Object?>{
            'display': false,
          },
        },
        'y': <String, Object?>{
          'position': <String, Object?>{'x': 0},
          'min': -10,
          'max': 10,
          'border': <String, Object?>{
            'dash': (Object? ctx) =>
                jsToNumber(jsGet(ctx, 'index')).remainder(2) == 0
                ? <Object?>[6, 3]
                : <Object?>[],
          },
          'grid': <String, Object?>{
            'color': 'lightGray',
            'lineWidth': 3,
          },
          'ticks': <String, Object?>{
            'display': false,
          },
        },
      },
    },
  },
};
