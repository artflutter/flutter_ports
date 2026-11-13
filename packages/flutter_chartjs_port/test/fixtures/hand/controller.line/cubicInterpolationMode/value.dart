// Ported from Chart.js v4.6.1 test/fixtures/controller.line/cubicInterpolationMode/value.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0, 4, 2, 6, 4, 8],
          'borderColor': '#ff0000',
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': const MonotoneCubicInterpolationMode(),
        },
        <String, Object?>{
          'data': <Object?>[2, 6, 4, 8, 6, 10],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': '#00ff00',
          'borderWidth': 20,
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': const DefaultCubicInterpolationMode(),
          'fill': false,
          'tension': 0.4,
        },
      },
      'layout': <String, Object?>{'padding': const EdgeInsets.all(32)},
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
