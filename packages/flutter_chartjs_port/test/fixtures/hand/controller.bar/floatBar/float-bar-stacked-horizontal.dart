// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/floatBar/float-bar-stacked-horizontal.json (MIT, Chart.js Contributors).
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
      'labels': <Object?>['2030', '2034', '2038', '2042'],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': '#FF6384',
          'data': <Object?>[
            11,
            <Object?>[6, 2],
            <Object?>[-4, -7],
            -2,
          ],
        },
        <String, Object?>{
          'backgroundColor': '#36A2EB',
          'data': <Object?>[
            <Object?>[1, 2],
            <Object?>[3, 4],
            <Object?>[-2, -3],
            <Object?>[1, 4],
          ],
        },
        <String, Object?>{
          'backgroundColor': '#FFCE56',
          'data': <Object?>[
            <Object?>[0, 1],
            <Object?>[1, 2],
            <Object?>[-2, -1],
            <Object?>[1, -7],
          ],
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false, 'stacked': true},
        'y': <String, Object?>{'display': false, 'stacked': true},
      },
    },
  },
  'debug': false,
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
