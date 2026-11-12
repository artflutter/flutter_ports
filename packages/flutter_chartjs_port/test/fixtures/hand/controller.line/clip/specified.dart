// Ported from Chart.js v4.6.1 test/fixtures/controller.line/clip/specified.json (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter/painting.dart' show EdgeInsets;

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'scatter',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'showLine': true,
          'borderColor': 'red',
          'data': <Object?>[
            <String, Object?>{'x': -4.0, 'y': -4.0},
            <String, Object?>{'x': 4.0, 'y': 4.0},
          ],
          'clip': false,
        },
        <String, Object?>{
          'showLine': true,
          'borderColor': 'green',
          'data': <Object?>[
            <String, Object?>{'x': -4.0, 'y': -5.0},
            <String, Object?>{'x': 4.0, 'y': 3.0},
          ],
          'clip': 5.0,
        },
        <String, Object?>{
          'showLine': true,
          'borderColor': 'blue',
          'data': <Object?>[
            <String, Object?>{'x': -4.0, 'y': -3.0},
            <String, Object?>{'x': 4.0, 'y': 5.0},
          ],
          'clip': -5.0,
        },
        <String, Object?>{
          'showLine': true,
          'borderColor': 'brown',
          'data': <Object?>[
            <String, Object?>{'x': -3.0, 'y': -3.0},
            <String, Object?>{'x': -1.0, 'y': 3.0},
            <String, Object?>{'x': 1.0, 'y': -2.0},
            <String, Object?>{'x': 2.0, 'y': 3.0},
          ],
          'clip': <String, Object?>{
            'top': 8.0,
            'left': false,
            'right': -20.0,
            'bottom': -20.0,
          },
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'min': -2.0,
          'max': 2.0,
          'ticks': <String, Object?>{'display': false},
        },
        'y': <String, Object?>{
          'min': -2.0,
          'max': 2.0,
          'ticks': <String, Object?>{'display': false},
        },
      },
      'layout': <String, Object?>{'padding': const EdgeInsets.all(24)},
      'elements': <String, Object?>{
        'line': <String, Object?>{'fill': false, 'borderWidth': 20.0},
        'point': <String, Object?>{'radius': 0.0},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256.0, 'width': 512.0},
  },
};
