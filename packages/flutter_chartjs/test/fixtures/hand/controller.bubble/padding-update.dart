// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bubble/padding-update.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bubble',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'red',
          'data': <Object?>[
            <String, Object?>{'x': 12, 'y': 54, 'r': 22.4},
          ],
        },
        <String, Object?>{
          'backgroundColor': 'blue',
          'data': <Object?>[
            <String, Object?>{'x': 18, 'y': 38, 'r': 25},
          ],
        },
      ],
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'width': 256,
      'height': 256,
    },
    'run': (Chart chart) {
      chart.update();
    },
  },
};
