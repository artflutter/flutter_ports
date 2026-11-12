// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/doughnut-set-active-elements.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/radius_length.dart'
    show PercentRadius;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/9248',
  'config': <String, Object?>{
    'type': 'doughnut',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[34, 33, 17, 16],
          'backgroundColor': <Object?>[
            '#D92323',
            '#E45757',
            '#ED8D8D',
            '#F5C4C4',
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'events': <Object?>[], // for easier saving of the fixture only
      'borderWidth': 0,
      'hoverBorderWidth': 4,
      'hoverBorderColor': 'black',
      // DIVERGES(chartjs): adapt-length-objects, the length class.
      'cutout': const PercentRadius(80),
    },
  },
  'options': <String, Object?>{
    'run': (Chart chart) {
      chart
        ..setActiveElements(<Object?>[
          <String, Object?>{'datasetIndex': 0, 'index': 1},
        ])
        ..update();
    },
  },
};
