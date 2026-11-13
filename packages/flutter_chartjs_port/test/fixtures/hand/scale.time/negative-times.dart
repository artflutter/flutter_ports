// Ported from Chart.js v4.6.1 test/fixtures/scale.time/negative-times.js (MIT, Chart.js Contributors).
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
      'datasets': <Object?>[
        <String, Object?>{
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toOrigin,
          'backgroundColor': 'red',
          'data': <Object?>[
            <String, Object?>{'x': -1000000, 'y': 1},
            <String, Object?>{'x': 1000000000, 'y': 2},
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'time',
          'time': <String, Object?>{'unit': 'day'},
          'ticks': <String, Object?>{'display': false},
        },
        'y': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
        },
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'width': 1000, 'height': 200},
  },
};
