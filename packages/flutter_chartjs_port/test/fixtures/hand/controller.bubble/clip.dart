// Ported from Chart.js v4.6.1 test/fixtures/controller.bubble/clip.js (MIT, Chart.js Contributors).
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
      'labels': <Object?>[0, 5, 10, 15, 20, 25, 30, 50, 55, 60],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[6, 11, 10, 10, 3, 22, 7, 24],
          'type': 'bubble',
          'label': 'test',
          'borderColor': '#3e95cd',
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
        },
        'y': <String, Object?>{
          'min': 8,
          'max': 25,
          'beginAtZero': true,
          'ticks': <String, Object?>{'display': false},
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 256},
  },
};
