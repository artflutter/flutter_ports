// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/chart-area-clip.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:flutter/painting.dart' show EdgeInsets;

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>[0.0, 1.0, 3.0, 4.0],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[5.0, 20.0, -5.0, -20.0],
          'borderColor': '#ff0000',
        },
      ],
    },
    'options': <String, Object?>{
      'layout': <String, Object?>{
        'padding': const EdgeInsets.fromLTRB(0, 50, 0, 50),
      },
      'elements': <String, Object?>{
        'bar': <String, Object?>{
          'backgroundColor': '#00ff00',
          'borderWidth': 8.0,
        },
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false, 'min': -10.0, 'max': 10.0},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256.0, 'width': 512.0},
  },
};
