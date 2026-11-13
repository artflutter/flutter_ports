// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/radar/boundary/origin-spline.json (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'rgba(0, 0, 192, 0.25)',
          'data': <Object?>[null, null, 2, 4, 2, 1, -1, 1, 2],
        },
        <String, Object?>{
          'backgroundColor': 'rgba(0, 192, 0, 0.25)',
          'data': <Object?>[4, 2, null, 3, 2.5, null, -2, 1.5, 3],
        },
        <String, Object?>{
          'backgroundColor': 'rgba(192, 0, 0, 0.25)',
          'data': <Object?>[3.5, 2, 1, 2.5, -2, 3, -1, null, null],
        },
        <String, Object?>{
          'backgroundColor': 'rgba(128, 0, 128, 0.25)',
          'data': <Object?>[5, 6, 5, -2, -4, -3, 4, 2, 4.5],
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'spanGaps': false,
      'scales': <String, Object?>{
        'r': <String, Object?>{'display': false},
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{'radius': 0},
        'line': <String, Object?>{
          'borderColor': 'transparent', 'tension': 0.5,
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toOrigin,
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
    'canvas': <String, Object?>{'height': 256, 'width': 256},
  },
};
