// Ported from Chart.js v4.6.1 test/fixtures/scale.logarithmic/large-range.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'red', 'borderColor': 'red',
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
          'data': <Object?>[23, 21, 34, 52, 115, 3333, 5116],
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': true,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{
          'type': 'logarithmic',
          'ticks': <String, Object?>{'autoSkip': false},
        },
      },
    },
  },
  'options': <String, Object?>{'spriteText': true},
};
