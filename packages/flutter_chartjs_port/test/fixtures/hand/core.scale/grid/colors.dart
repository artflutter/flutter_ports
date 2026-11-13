// Ported from Chart.js v4.6.1 test/fixtures/core.scale/grid/colors.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/types/axis_border.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['1', '2', '3', '4', '5', '6'],
      'datasets': <Object?>[
        <String, Object?>{
          'label': '# of Votes',
          'data': <Object?>[12, 19, 3, 5, 2, 3],
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFF0000FF)),
            width: 2,
          ),
          'grid': <String, Object?>{'color': 'green', 'drawTicks': false},
        },
        'y': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFF000000)),
            width: 2,
          ),
          'grid': <String, Object?>{'color': 'red', 'drawTicks': false},
        },
      },
    },
  },
};
