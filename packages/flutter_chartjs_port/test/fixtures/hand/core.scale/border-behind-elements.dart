// Ported from Chart.js v4.6.1 test/fixtures/core.scale/border-behind-elements.js (MIT, Chart.js Contributors).
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
    'type': 'bubble',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'label': '# of Votes',
          'data': <Object?>[
            <String, Object?>{'x': 19, 'y': 3, 'r': 3},
            <String, Object?>{'x': 2, 'y': 2, 'r': 60},
          ],
          'radius': 100,
          'backgroundColor': 'pink',
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': <String, Object?>{'display': false},
      },
      'scales': <String, Object?>{
        'y': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFFFF0000)),
            width: 5,
          ),
        },
        'x': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFFFF0000)),
            width: 5,
          ),
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
  },
};
