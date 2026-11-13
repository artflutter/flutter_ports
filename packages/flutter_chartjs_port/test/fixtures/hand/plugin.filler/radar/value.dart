// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/radar/value.json (MIT, Chart.js Contributors).
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
      'labels': <Object?>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'rgba(0, 0, 192, 0.25)',
          'data': <Object?>[0, -4, 2, 4, 2, 1, -1, 1, 2],
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'spanGaps': false,
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'display': false,
          'grid': <String, Object?>{'circular': true},
        },
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{'radius': 0},
        'line': <String, Object?>{
          'borderColor': 'transparent',
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': const FillTarget.toValue(3),
        },
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 256},
  },
};
