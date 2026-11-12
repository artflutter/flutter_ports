// Ported from Chart.js v4.6.1 test/fixtures/controller.line/rotation/indexable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[
        0,
        1,
        2,
        3,
        4,
        5,
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
          ],
          'pointBorderColor': '#00ff00',
          'pointRotation': <Object?>[
            0,
            30,
            60,
            90,
            120,
            150,
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
          'borderColor': '#ff0000',
          'borderWidth': 10,
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const LinePointStyle(),
          'rotation': <Object?>[
            150,
            120,
            90,
            60,
            30,
            0,
          ],
        },
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'display': false,
        },
        'y': <String, Object?>{
          'display': false,
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
