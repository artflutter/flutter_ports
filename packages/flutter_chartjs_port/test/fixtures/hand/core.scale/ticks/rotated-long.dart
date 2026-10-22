// Ported from Chart.js v4.5.1+7169e651 test/fixtures/core.scale/ticks/rotated-long.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[
        'Red Red Red Red',
        'Blue Blue Blue Blue',
        'Black Black Black Black',
        'Green Green Green Green',
        'Purple Purple Purple Purple',
        'Orange Orange Orange Orange Orange Orange',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[12, 19, 3, 5, 2, 3],
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': false,
        'tooltip': false,
        'filler': false,
        'title': false,
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'category',
          'position': 'bottom',
        },
        'x2': <String, Object?>{
          'type': 'category',
          'position': 'top',
        },
      },
    },
    'plugins': <Object?>[
      <String, Object?>{
        'afterDraw': (Chart chart) {
          // const ctx = chart.ctx; ctx.save(); ...
          chart.ctx!
            ..save()
            ..strokeStyle = 'red'
            ..strokeRect(0, 0, chart.width, chart.height)
            ..restore();
        },
      },
    ],
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'width': 1024,
      'height': 512,
    },
  },
};
