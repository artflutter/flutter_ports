// Ported from Chart.js v4.6.1 test/fixtures/scale.time/offset-auto-skip-ticks.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/10215',
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>[],
      'datasets': <Object?>[
        <String, Object?>{
          'label': 'Dataset',
          'borderColor': '#2f54eb',
          'data': <Object?>[
            <String, Object?>{'y': 3, 'x': 1646345700000},
            <String, Object?>{'y': 7, 'x': 1646346600000},
            <String, Object?>{'y': 9, 'x': 1646347500000},
            <String, Object?>{'y': 5, 'x': 1646348400000},
            <String, Object?>{'y': 5, 'x': 1646349300000},
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'maintainAspectRatio': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'time',
          'offset': true,
          'offsetAfterAutoskip': true,
          // DIVERGES(chartjs): adapt-axis-objects, the axis
          // class.
          'axis': const XAxis(),
          'grid': <String, Object?>{'offset': true},
        },
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 600, 'height': 400},
  },
};
