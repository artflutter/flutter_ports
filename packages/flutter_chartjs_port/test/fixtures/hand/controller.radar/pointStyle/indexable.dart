// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/pointStyle/indexable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>[
        0,
        1,
        2,
        3,
        4,
        5,
        6,
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            0,
            5,
            10,
            null,
            -10,
            -5,
            0,
          ],
          'pointBackgroundColor': '#ff0000',
          'pointBorderColor': '#ff0000',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': <Object?>[
            const CirclePointStyle(),
            const CrossPointStyle(),
            const CrossRotPointStyle(),
            const DashPointStyle(),
            const LinePointStyle(),
            const RectPointStyle(),
            false,
          ],
        },
        <String, Object?>{
          'data': <Object?>[
            4,
            -5,
            -10,
            null,
            10,
            5,
            -4,
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'fill': false,
        },
        'point': <String, Object?>{
          'backgroundColor': '#00ff00',
          'borderColor': '#00ff00',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': <Object?>[
            const LinePointStyle(),
            const RectPointStyle(),
            const RectRoundedPointStyle(),
            const RectRotPointStyle(),
            const StarPointStyle(),
            const TrianglePointStyle(),
          ],
          'radius': 10,
        },
      },
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'display': false,
          'min': -15,
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'height': 512,
      'width': 512,
    },
  },
};
