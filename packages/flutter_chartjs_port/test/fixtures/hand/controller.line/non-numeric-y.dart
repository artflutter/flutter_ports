// Ported from Chart.js v4.6.1 test/fixtures/controller.line/non-numeric-y.json (MIT, Chart.js Contributors).
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
      'xLabels': <Object?>[
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
      ],
      'yLabels': <Object?>[
        '',
        'Request Added',
        'Request Viewed',
        'Request Accepted',
        'Request Solved',
        'Solving Confirmed',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'label': 'My First dataset',
          'data': <Object?>[
            '',
            'Request Added',
            'Request Added',
            'Request Added',
            'Request Viewed',
            'Request Viewed',
            'Request Viewed',
          ],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
          'borderColor': 'red',
          'backgroundColor': 'red',
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'type': 'category', 'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
