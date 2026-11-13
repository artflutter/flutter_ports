// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/vertical.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'y': 1, 'x': 12},
            <String, Object?>{'y': 3, 'x': 14},
            <String, Object?>{'y': 4, 'x': 20},
            <String, Object?>{'y': 6, 'x': 13},
            <String, Object?>{'y': 9, 'x': 18},
          ],
          'borderColor': 'red',
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
        },
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'y': 1, 'x': 22.5},
            <String, Object?>{'y': 3, 'x': 23.5},
            <String, Object?>{'y': 4, 'x': 34},
            <String, Object?>{'y': 6, 'x': 17},
            <String, Object?>{'y': 9, 'x': 22.5},
          ],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target
          // value.
          'fill': FillTarget.toPrevious,
          'borderColor': 'blue',
          'backgroundColor': 'rgba(255, 200, 0, 0.5)',
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'radius': 0,
      'plugins': <String, Object?>{'legend': false},
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false, 'type': 'linear'},
        'y': <String, Object?>{'display': false, 'type': 'linear'},
      },
    },
  },
};
