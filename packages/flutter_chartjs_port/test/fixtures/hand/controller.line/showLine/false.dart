// Ported from Chart.js v4.6.1 test/fixtures/controller.line/showLine/false.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'should draw all elements except lines',
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[10, 15, 0, -4],
          'label': 'dataset1',
          'borderColor': 'red',
          'backgroundColor': 'green',
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toOrigin,
        },
      ],
      'labels': <Object?>['label1', 'label2', 'label3', 'label4'],
    },
    'options': <String, Object?>{
      'showLine': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
        'filler': true,
      },
    },
  },
};
