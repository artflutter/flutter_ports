// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/floatBar/data-as-objects-horizontal.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'y': 'b',
              'x': <Object?>[2, 8],
            },
            <String, Object?>{
              'y': 'c',
              'x': <Object?>[2, 5],
            },
          ],
          'backgroundColor': '#ff0000',
        },
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'y': 'a', 'x': 10},
            <String, Object?>{
              'y': 'c',
              'x': <Object?>[6, 10],
            },
          ],
          'backgroundColor': '#00ff00',
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false, 'min': 0},
        'y': <String, Object?>{'display': false, 'stacked': true},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
