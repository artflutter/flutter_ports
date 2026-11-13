// Ported from Chart.js v4.6.1 test/fixtures/element.line/skip/middle-span.js (MIT, Chart.js Contributors).
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
    'parsing': false,
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 10},
            <String, Object?>{'x': 5, 'y': 0},
            <String, Object?>{'x': null, 'y': -10},
            <String, Object?>{'x': 19, 'y': -5},
          ],
          'borderColor': 'red',
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toOrigin, 'spanGaps': true, 'tension': 0,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'linear',
          'display': false,
          'min': 0,
          'max': 20,
        },
        'y': <String, Object?>{'display': false, 'min': -15, 'max': 15},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
