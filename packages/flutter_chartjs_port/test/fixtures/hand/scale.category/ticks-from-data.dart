// Ported from Chart.js v4.6.1 test/fixtures/scale.category/ticks-from-data.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleDisplay;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'threshold': 0.01,
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[10, 5, 0, 25, 78],
          'backgroundColor': 'transparent',
        },
      ],
      'labels': <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5'],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{'display': ScaleDisplay.off},
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'y': <String, Object?>{'display': ScaleDisplay.on},
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 128, 'height': 256},
  },
};
