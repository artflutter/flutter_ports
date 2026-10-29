// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/stacking/issue-9105.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/9105',
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>[
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'rgba(255,99,132,0.8)',
          'label': 'Dataset 1',
          'data': <Object?>[12, 19, 3, 5, 2, 3],
          'stack': '0',
          'yAxisID': 'y',
        },
        <String, Object?>{
          'backgroundColor': 'rgba(54,162,235,0.8)',
          'label': 'Dataset 2',
          'data': <Object?>[13, 19, 3, 5, 8, 3],
          'stack': '0',
          'yAxisID': 'y',
        },
        <String, Object?>{
          'backgroundColor': 'rgba(75,192,192,0.8)',
          'label': 'Dataset 3',
          'data': <Object?>[13, 19, 3, 5, 8, 3],
          'stack': '0',
          'yAxisID': 'y',
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'display': false,
        },
        'y': <String, Object?>{
          'display': false,
        },
      },
    },
  },
  'options': <String, Object?>{
    'run': (Chart chart) {
      (jsGet(jsGet(chart.data, 'datasets'), 1)!
              as Map<String, Object?>)['stack'] =
          '1';
      chart.update();
    },
  },
};
