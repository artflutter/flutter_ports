// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bar/stacking/replace-data.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final barChartData = <String, Object?>{
    'labels': <Object?>['January', 'February', 'March'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Dataset 1',
        'backgroundColor': 'red',
        'data': <Object?>[5, 5, 5],
      },
      <String, Object?>{
        'label': 'Dataset 2',
        'backgroundColor': 'blue',
        'data': <Object?>[5, 5, 5],
      },
      <String, Object?>{
        'label': 'Dataset 3',
        'backgroundColor': 'green',
        'data': <Object?>[5, 5, 5],
      },
    ],
  };

  return <String, Object?>{
    'description': 'https://github.com/chartjs/Chart.js/issues/8614',
    'config': <String, Object?>{
      'type': 'bar',
      'data': barChartData,
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'display': false,
            'stacked': true,
          },
          'y': <String, Object?>{
            'display': false,
            'stacked': true,
          },
        },
      },
    },
    'options': <String, Object?>{
      'run': (Chart chart) {
        (jsGet(jsGet(chart.data, 'datasets'), 1)!
            as Map<String, Object?>)['data'] = <Object?>[
          <String, Object?>{'x': 'January', 'y': 5},
          // Februay missing
          <String, Object?>{'x': 'March', 'y': 5},
        ];
        chart.update();
      },
    },
  };
}
