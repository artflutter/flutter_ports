// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/drawTimeFillFalse/beforeDraw.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['0', '1', '2', '3', '4', '5'],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'red', 'data': <Object?>[3, -3, 0, 5, -5, 0],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'filler': <String, Object?>{'drawTime': 'beforeDraw'},
      },
    },
  },
};
