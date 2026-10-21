// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.scatter/showLine/changed.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'showLine option should draw a line if true',
  'config': <String, Object?>{
    'type': 'scatter',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 10, 'y': 15},
            <String, Object?>{'x': 15, 'y': 10},
          ],
          'pointRadius': 10,
          'backgroundColor': 'red',
          'label': 'dataset1',
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'display': false,
        },
        'y': <String, Object?>{
          'display': false,
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'width': 256,
      'height': 256,
    },
    'run': (Chart chart) {
      chart.options['showLine'] = true;
      chart.update();
    },
  },
};
