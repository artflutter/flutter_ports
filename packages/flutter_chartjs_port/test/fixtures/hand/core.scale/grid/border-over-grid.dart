// Ported from Chart.js v4.6.1 test/fixtures/core.scale/grid/border-over-grid.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
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
    'type': 'scatter',
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'position': <String, Object?>{'y': 0}, 'min': -10, 'max': 10,
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFF000000)),
            width: 5,
          ),
          'grid': <String, Object?>{'color': 'lightGray', 'lineWidth': 3},
          'ticks': <String, Object?>{'display': false},
        },
        'y': <String, Object?>{
          'position': <String, Object?>{'x': 0}, 'min': -10, 'max': 10,
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFF000000)),
            width: 5,
          ),
          'grid': <String, Object?>{'color': 'lightGray', 'lineWidth': 3},
          'ticks': <String, Object?>{'display': false},
        },
      },
    },
  },
};
