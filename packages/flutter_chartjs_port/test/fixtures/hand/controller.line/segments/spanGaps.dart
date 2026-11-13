// Ported from Chart.js v4.6.1 test/fixtures/controller.line/segments/spanGaps.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-line-segment-style, a LineSegmentStyle.
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableLineSegmentContext;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/line_segment_style.dart';

// `ctx.p1` is a point element. `ctx.p1.parsed` is the access by name of the
// element (Chart.js ADR 0017, section 5): `jsGet` gives `undefined` for an
// element.
double _p1x(ScriptableLineSegmentContext ctx) =>
    jsToNumber(jsGet((ctx.p1 as Element)['parsed'], 'x'));

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 3, null, null, 2, 1],
          'segment': LineSegmentStyle(
            borderColor: (ctx) => _p1x(ctx) > 2
                ? const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1))
                : null,
            borderDash: (ctx) => _p1x(ctx) > 3 ? <double>[6, 6] : null,
          ),
          'spanGaps': true,
        },
        <String, Object?>{
          'data': <Object?>[0, 2, null, null, 1, 0],
          'segment': LineSegmentStyle(
            borderColor: (ctx) => _p1x(ctx) > 2
                ? const ChartPaint.solid(Color.fromRGBO(255, 0, 0, 1))
                : null,
            borderDash: (ctx) => _p1x(ctx) > 3 ? <double>[6, 6] : null,
          ),
          'spanGaps': false,
        },
      ],
    },
    'options': <String, Object?>{
      'borderColor': 'black',
      'radius': 0,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
};
