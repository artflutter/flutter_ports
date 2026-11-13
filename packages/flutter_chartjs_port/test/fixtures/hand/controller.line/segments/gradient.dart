// Ported from Chart.js v4.6.1 test/fixtures/controller.line/segments/gradient.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Offset;

import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  Object? getGradient(Object? context) {
    // Upstream: const {chart, p0, p1} = context;
    final p0 = jsGet(context, 'p0')! as Element;
    final p1 = jsGet(context, 'p1')! as Element;
    // Upstream: const {x: x0} = p0.getProps(['x'], true);
    final x0 = p0.getProps(const ['x'], true)['x'];
    // Upstream: const {x: x1} = p1.getProps(['x'], true);
    final x1 = p1.getProps(const ['x'], true)['x'];
    return ChartGradient.linear(
      Offset(jsToNumber(x0), 0),
      Offset(jsToNumber(x1), 0),
      [
        (jsGet(p0.options, 'backgroundColor')! as SolidChartPaint).color,
        (jsGet(p1.options, 'backgroundColor')! as SolidChartPaint).color,
      ],
    );
  }

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[
              <String, Object?>{'x': 0, 'y': 0},
              <String, Object?>{'x': 1, 'y': 1},
              <String, Object?>{'x': 2, 'y': 2},
              <String, Object?>{'x': 3, 'y': 3},
              <String, Object?>{'x': 4, 'y': 4},
              <String, Object?>{'x': 5, 'y': 5},
              <String, Object?>{'x': 6, 'y': 6},
            ],
            'pointBackgroundColor': <Object?>[
              'red',
              'yellow',
              'green',
              'green',
              'blue',
              'pink',
              'blue',
            ],
            'pointBorderWidth': 0,
            'pointRadius': 10,
            'borderWidth': 5,
            'segment': <String, Object?>{
              'borderColor': getGradient,
            },
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{'type': 'linear', 'display': false},
          'y': <String, Object?>{'display': false},
        },
      },
    },
  };
}
