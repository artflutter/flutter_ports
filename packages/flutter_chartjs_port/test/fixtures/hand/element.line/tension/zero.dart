// Ported from Chart.js v4.6.1 test/fixtures/element.line/tension/zero.js (MIT, Chart.js Contributors).
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
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 1, 'y': 10},
            <String, Object?>{'x': 5, 'y': 0},
            <String, Object?>{'x': 15, 'y': -10},
            <String, Object?>{'x': 19, 'y': -5},
          ],
          'borderColor': 'red',
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none, 'tension': 0,
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
