// Ported from Chart.js v4.6.1 test/fixtures/controller.line/segments/single.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/line_segment_style.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 2, 3, 3, 2, 1],
          'borderColor': 'black',
          // DIVERGES(chartjs): adapt-native-line-segment-style, the constant
          // borderColor 'red' is a function that gives it for each part.
          'segment': LineSegmentStyle(
            borderColor: (_) =>
                const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1)),
          ),
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'width': 256, 'height': 256},
  },
};
