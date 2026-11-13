// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/offset-scale-minmax.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/12280',
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[10, 25, 15, 40, 30, 45],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toOrigin,
          'backgroundColor': 'red',
          'borderColor': 'blue',
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{'radius': 0},
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'display': false,
          'offset': true,
          'min': 'a',
          'max': 'd',
        },
        'y': <String, Object?>{'display': false},
      },
    },
  },
};
