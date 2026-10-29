// Ported from Chart.js v4.6.1 test/fixtures/scale.linear/tick-count-data-limits.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/4234',
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0, 2, 45, 30],
        },
      ],
      'labels': <Object?>['A', 'B', 'C', 'D'],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'y': <String, Object?>{
          'ticks': <String, Object?>{
            'count': 21,
            // (v) => v.toString(): a tick value is a number, thus
            // Number.prototype.toString.
            'callback': (Object? v) => jsNumberToString(v! as num),
          },
        },
        'x': <String, Object?>{
          'display': false,
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
  },
};
