// Ported from Chart.js v4.6.1 test/fixtures/controller.line/segments/gap.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-line-segment-style, a LineSegmentStyle.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableLineSegmentContext;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/line_segment_style.dart';

// `ctx.p0` and `ctx.p1` are point elements: `ctx.p0.skip || ctx.p1.skip`.
bool _skipped(ScriptableLineSegmentContext ctx) =>
    (ctx.p0.skip ?? false) || (ctx.p1.skip ?? false);

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 3, double.nan, double.nan, 2, 1],
          'borderColor': 'black',
          'segment': LineSegmentStyle(
            borderColor: (ctx) => _skipped(ctx)
                ? const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1))
                : null,
            borderDash: (ctx) => _skipped(ctx) ? <double>[5, 5] : null,
          ),
          'spanGaps': true,
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
};
