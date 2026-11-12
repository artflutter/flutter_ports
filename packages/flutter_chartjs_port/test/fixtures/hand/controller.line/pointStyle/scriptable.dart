// Ported from Chart.js v4.6.1 test/fixtures/controller.line/pointStyle/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show CrossPointStyle, RectPointStyle, StarPointStyle, TrianglePointStyle;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[0, 5, 10, null, -10, -5],
          'pointBackgroundColor': '#ff0000',
          'pointBorderColor': '#ff0000',
          // DIVERGES(chartjs): adapt-point-style-objects, the style classes.
          'pointStyle': (Object? ctx) {
            final value = jsOrZero(
              jsGet(
                jsGet(jsGet(ctx, 'dataset'), 'data'),
                jsGet(ctx, 'dataIndex'),
              ),
            );
            return value > 8
                ? const RectPointStyle()
                : value > 0
                ? const StarPointStyle()
                : value > -8
                ? const CrossPointStyle()
                : const TrianglePointStyle();
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[4, -5, -10, null, 10, 5],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'fill': false,
        },
        'point': <String, Object?>{
          'backgroundColor': '#0000ff',
          'borderColor': '#0000ff',
          // DIVERGES(chartjs): adapt-point-style-objects, the style classes.
          'pointStyle': (Object? ctx) {
            final value = jsOrZero(
              jsGet(
                jsGet(jsGet(ctx, 'dataset'), 'data'),
                jsGet(ctx, 'dataIndex'),
              ),
            );
            return value > 8
                ? const TrianglePointStyle()
                : value > 0
                ? const CrossPointStyle()
                : value > -8
                ? const StarPointStyle()
                : const RectPointStyle();
          },
          'radius': 10,
        },
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{
          'display': false,
          'beginAtZero': true,
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'height': 256,
      'width': 512,
    },
  },
};
