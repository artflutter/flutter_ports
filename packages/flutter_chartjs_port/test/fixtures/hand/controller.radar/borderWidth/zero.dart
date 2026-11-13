// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/borderWidth/zero.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0, 5, 10, null, -10, -5],
          'backgroundColor': '#0000ff',
          'borderColor': '#0000ff',
          'borderWidth': 0,
        },
        <String, Object?>{
          'data': <Object?>[4, -5, -10, null, 10, 5],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': '#00ff00', 'borderWidth': 1,
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
        },
        'point': <String, Object?>{'backgroundColor': '#00ff00', 'radius': 10},
      },
      'scales': <String, Object?>{
        'r': <String, Object?>{'display': false, 'min': -15},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
  },
};
