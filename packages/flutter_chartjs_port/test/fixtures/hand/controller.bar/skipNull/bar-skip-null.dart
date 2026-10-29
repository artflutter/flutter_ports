// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/skipNull/bar-skip-null.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 3, 4],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[5, 20, 1, 10],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
        },
        <String, Object?>{
          'data': <Object?>[10, null, 1, undefined],
          'backgroundColor': '#ff0000',
          'borderColor': '#ff0000',
        },
      ],
    },
    'options': <String, Object?>{
      'skipNull': true,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
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
