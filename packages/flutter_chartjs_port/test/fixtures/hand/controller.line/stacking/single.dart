// Ported from Chart.js v4.6.1 test/fixtures/controller.line/stacking/single.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

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
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            0,
            -1,
            -1,
          ],
          'backgroundColor': '#ff0000',
        },
        <String, Object?>{
          'data': <Object?>[
            0,
            2,
            2,
          ],
          'backgroundColor': '#00ff00',
        },
        <String, Object?>{
          'data': <Object?>[
            0,
            0,
            1,
          ],
          'backgroundColor': '#0000ff',
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          // DIVERGES(chartjs): adapt-fill-target-objects, the target
          // value.
          'fill': const RelativeFill(-1),
        },
        'point': <String, Object?>{
          'radius': 0,
        },
      },
      'layout': <String, Object?>{
        'padding': const EdgeInsets.all(32),
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
        'filler': true,
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'display': false,
        },
        'y': <String, Object?>{
          'display': false,
          'stacked': 'single',
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
