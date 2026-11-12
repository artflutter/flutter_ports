// Ported from Chart.js v4.6.1 test/fixtures/controller.bubble/point-style.json (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bubble',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'x': 0,
              'y': 3,
            },
            <String, Object?>{
              'x': 1,
              'y': 3,
            },
            <String, Object?>{
              'x': 2,
              'y': 3,
            },
            <String, Object?>{
              'x': 3,
              'y': 3,
            },
            <String, Object?>{
              'x': 4,
              'y': 3,
            },
            <String, Object?>{
              'x': 5,
              'y': 3,
            },
            <String, Object?>{
              'x': 6,
              'y': 3,
            },
            <String, Object?>{
              'x': 7,
              'y': 3,
            },
            <String, Object?>{
              'x': 8,
              'y': 3,
            },
            <String, Object?>{
              'x': 9,
              'y': 3,
            },
          ],
          'backgroundColor': '#00ff00',
          'borderColor': 'transparent',
          'borderWidth': 0,
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
          'data': <Object?>[
            <String, Object?>{
              'x': 0,
              'y': 2,
            },
            <String, Object?>{
              'x': 1,
              'y': 2,
            },
            <String, Object?>{
              'x': 2,
              'y': 2,
            },
            <String, Object?>{
              'x': 3,
              'y': 2,
            },
            <String, Object?>{
              'x': 4,
              'y': 2,
            },
            <String, Object?>{
              'x': 5,
              'y': 2,
            },
            <String, Object?>{
              'x': 6,
              'y': 2,
            },
            <String, Object?>{
              'x': 7,
              'y': 2,
            },
            <String, Object?>{
              'x': 8,
              'y': 2,
            },
            <String, Object?>{
              'x': 9,
              'y': 2,
            },
          ],
          'backgroundColor': 'transparent',
          'borderColor': '#0000ff',
          'borderWidth': 1,
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
          'data': <Object?>[
            <String, Object?>{
              'x': 0,
              'y': 1,
            },
            <String, Object?>{
              'x': 1,
              'y': 1,
            },
            <String, Object?>{
              'x': 2,
              'y': 1,
            },
            <String, Object?>{
              'x': 3,
              'y': 1,
            },
            <String, Object?>{
              'x': 4,
              'y': 1,
            },
            <String, Object?>{
              'x': 5,
              'y': 1,
            },
            <String, Object?>{
              'x': 6,
              'y': 1,
            },
            <String, Object?>{
              'x': 7,
              'y': 1,
            },
            <String, Object?>{
              'x': 8,
              'y': 1,
            },
            <String, Object?>{
              'x': 9,
              'y': 1,
            },
          ],
          'backgroundColor': '#00ff00',
          'borderColor': '#0000ff',
          'borderWidth': 1,
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
        'x': <String, Object?>{
          'display': false,
        },
        'y': <String, Object?>{
          'display': false,
          'min': 0,
          'max': 4,
        },
      },
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': 'transparent',
          'borderWidth': 1,
          'fill': false,
        },
        'point': <String, Object?>{
          'radius': 16,
        },
      },
      'layout': <String, Object?>{
        'padding': <String, Object?>{
          'left': 24,
          'right': 24,
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
