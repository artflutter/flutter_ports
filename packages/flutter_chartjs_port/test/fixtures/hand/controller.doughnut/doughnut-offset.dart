// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-offset.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:flutter/painting.dart' show EdgeInsets;

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'doughnut',
    'data': <String, Object?>{
      'labels': <Object?>['Red', 'Blue', 'Yellow'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[12.0, 4.0, 6.0],
          'backgroundColor': <Object?>['red', 'blue', 'yellow'],
        },
      ],
    },
    'options': <String, Object?>{
      'offset': 40.0,
      'layout': <String, Object?>{'padding': const EdgeInsets.all(50)},
    },
  },
};
