// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/segments/slope.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-line-segment-style, a LineSegmentStyle.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableLineSegmentContext;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/line_segment_style.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  // Upstream: function slope({p0, p1}). `p0` and `p1` are point elements:
  // `x` and `y` are their number properties (Chart.js ADR 0017).
  double slope(ScriptableLineSegmentContext ctx) {
    final p0 = ctx.p0;
    final p1 = ctx.p1;
    return (p0.y - p1.y) / (p1.x - p0.x);
  }

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[1, 2, 3, 3, 2, 1],
            'backgroundColor': 'black',
            'borderColor': 'orange',
            // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
            'fill': FillTarget.toOrigin,
            'segment': LineSegmentStyle(
              backgroundColor: (ctx) => slope(ctx) > 0
                  ? const ChartPaint.solid(Color.fromRGBO(0, 128, 0, 1))
                  : slope(ctx) < 0
                  ? const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1))
                  : null,
            ),
          },
        ],
      },
      'options': <String, Object?>{
        'plugins': <String, Object?>{'legend': false},
        'scales': <String, Object?>{
          'x': <String, Object?>{'display': false},
          'y': <String, Object?>{'display': false},
        },
      },
    },
  };
}
