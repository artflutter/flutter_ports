// Ported from Chart.js v4.6.1 test/fixtures/core.layouts/stacked-boxes-max-without-clip.js (MIT, Chart.js Contributors).
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
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 1, 'y': 5},
            <String, Object?>{'x': 2, 'y': 10},
            <String, Object?>{'x': 3, 'y': 5},
          ],
          'borderColor': 'red',
        },
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 1, 'y': 5},
            <String, Object?>{'x': 2, 'y': 10},
            <String, Object?>{'x': 3, 'y': 5},
          ],
          'yAxisID': 'y1',
          'xAxisID': 'x1',
          'borderColor': 'green',
        },
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 1, 'y': 5},
            <String, Object?>{'x': 2, 'y': 10},
            <String, Object?>{'x': 3, 'y': 5},
          ],
          'yAxisID': 'y2',
          'xAxisID': 'x2',
          'borderColor': 'blue',
        },
      ],
      'labels': <Object?>['tick1', 'tick2', 'tick3'],
    },
    'options': <String, Object?>{
      'plugins': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'linear',
          'position': 'bottom',
          'stack': '1',
          'offset': true,
          'clip': false,
          'bounds': 'data',
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFFFF0000)),
          ),
          'ticks': <String, Object?>{
            'autoSkip': false,
            'maxRotation': 0,
            'count': 3,
          },
        },
        'x1': <String, Object?>{
          'type': 'linear',
          'position': 'bottom',
          'stack': '1',
          'offset': true,
          'clip': false,
          'bounds': 'data',
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFF008000)),
          ),
          'ticks': <String, Object?>{
            'autoSkip': false,
            'maxRotation': 0,
            'count': 3,
          },
        },
        'x2': <String, Object?>{
          'type': 'linear',
          'position': 'bottom',
          'stack': '1',
          'offset': true,
          'clip': false,
          'bounds': 'data',
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFF0000FF)),
          ),
          'ticks': <String, Object?>{
            'autoSkip': false,
            'maxRotation': 0,
            'count': 3,
          },
        },
        'y': <String, Object?>{
          'type': 'linear',
          'position': 'left',
          'stack': '1',
          'offset': true,
          'clip': false,
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFFFF0000)),
          ),
          'ticks': <String, Object?>{'precision': 0},
          'max': 7,
        },
        'y1': <String, Object?>{
          'type': 'linear',
          'position': 'left',
          'stack': '1',
          'offset': true,
          'clip': false,
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFF008000)),
          ),
          'ticks': <String, Object?>{'precision': 0},
          'max': 7,
        },
        'y2': <String, Object?>{
          'type': 'linear',
          'position': 'left',
          'stack': '1',
          'offset': true,
          'clip': false,
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const AxisBorder(
            color: ChartPaint.solid(Color(0xFF0000FF)),
          ),
          'ticks': <String, Object?>{'precision': 0},
          'max': 7,
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 384, 'width': 384},
  },
};
