// Ported from Chart.js v4.6.1 test/fixtures/scale.timeseries/data-timestamps.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'threshold': 0.01,
  'tolerance': 0.0015,
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 1687849697000, 'y': 904},
            <String, Object?>{'x': 1687817063000, 'y': 905},
            <String, Object?>{'x': 1687694268000, 'y': 913},
            <String, Object?>{'x': 1687609438000, 'y': 914},
            <String, Object?>{'x': 1687561387000, 'y': 916},
            <String, Object?>{'x': 1686875127000, 'y': 918},
            <String, Object?>{'x': 1686873138000, 'y': 920},
            <String, Object?>{'x': 1686872777000, 'y': 928},
            <String, Object?>{'x': 1686081641000, 'y': 915},
          ],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
        },
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 1687816803000, 'y': 1105},
            <String, Object?>{'x': 1686869490000, 'y': 1114},
            <String, Object?>{'x': 1686869397000, 'y': 1103},
            <String, Object?>{'x': 1686869225000, 'y': 1091},
            <String, Object?>{'x': 1686556516000, 'y': 1078},
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'timeseries',
          'bounds': 'data',
          'time': <String, Object?>{'unit': 'day'},
          'ticks': <String, Object?>{'source': 'auto'},
        },
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{'spriteText': true},
};
