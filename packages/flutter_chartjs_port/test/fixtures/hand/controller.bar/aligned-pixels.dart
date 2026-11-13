// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/aligned-pixels.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>['a'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[-1],
        },
        <String, Object?>{
          'data': <Object?>[1],
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'events': <Object?>[],
      'backgroundColor': 'navy',
      'devicePixelRatio': 1.25,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false, 'alignToPixels': true},
        'y': <String, Object?>{'display': false, 'stacked': true},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'width': 100, 'height': 500},
  },
};
