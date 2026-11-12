// Ported from Chart.js v4.6.1 test/fixtures/controller.line/backgroundColor/value.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter/painting.dart' show EdgeInsets;

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0.0, 5.0, 10.0, null, -10.0, -5.0],
          'backgroundColor': '#ff0000',
        },
        <String, Object?>{
          'data': <Object?>[4.0, -5.0, -10.0, null, 10.0, 5.0],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{'fill': true, 'backgroundColor': '#00ff00'},
        'point': <String, Object?>{'radius': 10.0},
      },
      'layout': <String, Object?>{'padding': const EdgeInsets.all(32)},
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
        'filler': true,
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256.0, 'width': 512.0},
  },
};
