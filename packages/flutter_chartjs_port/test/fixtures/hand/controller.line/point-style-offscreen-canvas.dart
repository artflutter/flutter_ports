// Ported from Chart.js v4.6.1 test/fixtures/controller.line/point-style-offscreen-canvas.json (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
      'datasets': <Object?>[
        <String, Object?>{
          'borderColor': 'transparent',
          'data': <Object?>[3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
          'pointBackgroundColor': '#00ff00',
          'pointBorderColor': 'transparent',
          'pointBorderWidth': 0,
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': <Object?>[
            const CirclePointStyle(),
            const CrossPointStyle(),
            const CrossRotPointStyle(),
            const DashPointStyle(),
            const LinePointStyle(),
            const RectPointStyle(),
            const RectRoundedPointStyle(),
            const RectRotPointStyle(),
            const StarPointStyle(),
            const TrianglePointStyle(),
          ],
        },
        <String, Object?>{
          'borderColor': 'transparent',
          'data': <Object?>[2, 2, 2, 2, 2, 2, 2, 2, 2, 2],
          'pointBackgroundColor': 'transparent',
          'pointBorderColor': '#0000ff',
          'pointBorderWidth': 1,
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': <Object?>[
            const CirclePointStyle(),
            const CrossPointStyle(),
            const CrossRotPointStyle(),
            const DashPointStyle(),
            const LinePointStyle(),
            const RectPointStyle(),
            const RectRoundedPointStyle(),
            const RectRotPointStyle(),
            const StarPointStyle(),
            const TrianglePointStyle(),
          ],
        },
        <String, Object?>{
          'borderColor': 'transparent',
          'data': <Object?>[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
          'pointBackgroundColor': '#00ff00',
          'pointBorderColor': '#0000ff',
          'pointBorderWidth': 1,
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': <Object?>[
            const CirclePointStyle(),
            const CrossPointStyle(),
            const CrossRotPointStyle(),
            const DashPointStyle(),
            const LinePointStyle(),
            const RectPointStyle(),
            const RectRoundedPointStyle(),
            const RectRotPointStyle(),
            const StarPointStyle(),
            const TrianglePointStyle(),
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false, 'min': 0, 'max': 4},
      },
      'elements': <String, Object?>{
        'line': <String, Object?>{'fill': FillTarget.none},
        'point': <String, Object?>{'radius': 16},
      },
      'layout': <String, Object?>{
        'padding': const EdgeInsets.only(left: 24, right: 24),
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
    'useOffscreenCanvas': true,
  },
};
