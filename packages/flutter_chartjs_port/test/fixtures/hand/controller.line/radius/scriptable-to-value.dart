// Ported from Chart.js v4.6.1 test/fixtures/controller.line/radius/scriptable-to-value.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleDisplay;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['A', 'B', 'C'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[12, 19, 3],
        },
      ],
    },
    'options': <String, Object?>{
      'animation': <String, Object?>{'duration': 0},
      'backgroundColor': 'red',
      'radius': () => 20,
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{'display': ScaleDisplay.off},
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'y': <String, Object?>{'display': ScaleDisplay.off},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
    'run': (Chart chart) {
      chart.options['radius'] = 5;
      chart.update();
    },
  },
};
