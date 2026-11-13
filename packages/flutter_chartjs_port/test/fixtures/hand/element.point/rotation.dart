// Ported from Chart.js v4.6.1 test/fixtures/element.point/rotation.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' as native_ui;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show
        CirclePointStyle,
        CrossPointStyle,
        CrossRotPointStyle,
        DashPointStyle,
        LinePointStyle,
        RectPointStyle,
        RectRotPointStyle,
        RectRoundedPointStyle,
        StarPointStyle,
        TrianglePointStyle;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  ChartGradient? gradient;

  // DIVERGES(chartjs): adapt-point-style-objects, the style classes.
  final datasets =
      const <Object?>[
        CirclePointStyle(),
        CrossPointStyle(),
        CrossRotPointStyle(),
        DashPointStyle(),
        LinePointStyle(),
        RectPointStyle(),
        RectRoundedPointStyle(),
        RectRotPointStyle(),
        StarPointStyle(),
        TrianglePointStyle(),
        false,
      ].indexed.map((entry) {
        final (y, style) = entry;
        return <String, Object?>{
          'pointStyle': style,
          // Upstream: Array.apply(null, Array(17)).map(function(v, x) {...}).
          'data': List<Object?>.generate(17, (x) {
            return <String, Object?>{'x': x, 'y': 11 - y};
          }),
        };
      }).toList();

  // Upstream: Array.apply(null, Array(17)).map(function(v, i) {...}).
  final angles = List<Object?>.generate(17, (i) {
    return -180 + i * 22.5;
  });

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'bubble',
      'data': <String, Object?>{'datasets': datasets},
      'options': <String, Object?>{
        'responsive': false,
        'elements': <String, Object?>{
          'point': <String, Object?>{
            'rotation': angles,
            'radius': 10,
            'backgroundColor': (Object? context) {
              return gradient ??= const ChartGradient.linear(
                native_ui.Offset.zero,
                native_ui.Offset(512, 256),
                [native_ui.Color(0xffff0000), native_ui.Color(0xff0000ff)],
              );
            },
            'borderColor': '#cccccc',
          },
        },
        'layout': <String, Object?>{'padding': const EdgeInsets.all(20)},
        'scales': <String, Object?>{
          'x': <String, Object?>{'display': false},
          'y': <String, Object?>{'display': false},
        },
      },
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{'height': 256, 'width': 512},
    },
  };
}
