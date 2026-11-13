// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/points-outside-canvas-initial.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/8699',
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'red',
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 3},
            <String, Object?>{'x': 2, 'y': -3},
            <String, Object?>{'x': 4, 'y': 0},
            <String, Object?>{'x': 6, 'y': 5},
            <String, Object?>{'x': 8, 'y': -5},
            <String, Object?>{'x': 10, 'y': 0},
          ],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toOrigin,
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{'legend': false, 'title': false},
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false, 'type': 'linear', 'min': 5},
        'y': <String, Object?>{'display': false},
      },
    },
  },
};
