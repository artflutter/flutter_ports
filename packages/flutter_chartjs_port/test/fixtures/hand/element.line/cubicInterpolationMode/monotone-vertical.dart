// Ported from Chart.js v4.6.1 test/fixtures/element.line/cubicInterpolationMode/monotone-vertical.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 10, 'y': 1},
            <String, Object?>{'x': 0, 'y': 5},
            <String, Object?>{'x': -10, 'y': 15},
            <String, Object?>{'x': -5, 'y': 19},
          ],
          'borderColor': 'red',
          'fill': false,
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': const MonotoneCubicInterpolationMode(),
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false, 'min': -15, 'max': 15},
        'y': <String, Object?>{
          'type': 'linear',
          'display': false,
          'min': 0,
          'max': 20,
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
