// Ported from Chart.js v4.6.1 test/fixtures/element.point/point-style-circle.json (MIT, Chart.js Contributors).
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
              'r': 0,
            },
            <String, Object?>{
              'x': 1,
              'y': 3,
              'r': 2,
            },
            <String, Object?>{
              'x': 2,
              'y': 3,
              'r': 4,
            },
            <String, Object?>{
              'x': 3,
              'y': 3,
              'r': 8,
            },
            <String, Object?>{
              'x': 4,
              'y': 3,
              'r': 16,
            },
            <String, Object?>{
              'x': 5,
              'y': 3,
              'r': 32,
            },
          ],
          'backgroundColor': '#00ff00',
          'borderColor': 'transparent',
          'borderWidth': 0,
        },
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'x': 0,
              'y': 2,
              'r': 0,
            },
            <String, Object?>{
              'x': 1,
              'y': 2,
              'r': 2,
            },
            <String, Object?>{
              'x': 2,
              'y': 2,
              'r': 4,
            },
            <String, Object?>{
              'x': 3,
              'y': 2,
              'r': 8,
            },
            <String, Object?>{
              'x': 4,
              'y': 2,
              'r': 16,
            },
            <String, Object?>{
              'x': 5,
              'y': 2,
              'r': 32,
            },
          ],
          'backgroundColor': 'transparent',
          'borderColor': '#0000ff',
          'borderWidth': 1,
        },
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{
              'x': 0,
              'y': 1,
              'r': 0,
            },
            <String, Object?>{
              'x': 1,
              'y': 1,
              'r': 2,
            },
            <String, Object?>{
              'x': 2,
              'y': 1,
              'r': 4,
            },
            <String, Object?>{
              'x': 3,
              'y': 1,
              'r': 8,
            },
            <String, Object?>{
              'x': 4,
              'y': 1,
              'r': 16,
            },
            <String, Object?>{
              'x': 5,
              'y': 1,
              'r': 32,
            },
          ],
          'backgroundColor': '#00ff00',
          'borderColor': '#0000ff',
          'borderWidth': 2,
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'elements': <String, Object?>{
        'point': <String, Object?>{
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const CirclePointStyle(),
        },
      },
      'layout': <String, Object?>{
        'padding': 40,
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
