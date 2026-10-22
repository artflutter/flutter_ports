// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bubble/hover-radius-zero.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bubble',
    'data': <String, Object?>{
      'labels': <Object?>[2, 2, 2, 2],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <Object?>[1, 1],
            <Object?>[1, 2],
            <Object?>[1, 3, 20],
            <Object?>[1, 4, 20],
          ],
        },
        <String, Object?>{
          'data': <Object?>[1, 2, 3, 4],
        },
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 3, 'y': 1},
            <String, Object?>{'x': 3, 'y': 2},
            <String, Object?>{'x': 3, 'y': 3, 'r': 15},
            <String, Object?>{'x': 3, 'y': 4, 'r': 15},
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'events': <Object?>[],
      'radius': 10,
      'hoverRadius': 0,
      'backgroundColor': 'blue',
      'hoverBackgroundColor': 'red',
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false, 'bounds': 'data'},
        'y': <String, Object?>{'display': false},
      },
      'layout': <String, Object?>{
        'padding': 24,
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'height': 256,
      'width': 256,
    },
    'run': (Chart chart) {
      chart
        ..setActiveElements(<Object?>[
          <String, Object?>{'datasetIndex': 0, 'index': 1},
          <String, Object?>{'datasetIndex': 0, 'index': 2},
          <String, Object?>{'datasetIndex': 1, 'index': 1},
          <String, Object?>{'datasetIndex': 1, 'index': 2},
          <String, Object?>{'datasetIndex': 2, 'index': 1},
          <String, Object?>{'datasetIndex': 2, 'index': 2},
        ])
        ..update();
    },
  },
};
