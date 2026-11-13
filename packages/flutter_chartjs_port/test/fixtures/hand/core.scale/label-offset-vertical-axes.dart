// Ported from Chart.js v4.6.1 test/fixtures/core.scale/label-offset-vertical-axes.json (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>['◀', '■', '◆', '●'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[12, 19, 3, 5],
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
          'grid': <String, Object?>{'display': false},
          'border': <String, Object?>{'display': false},
        },
        'y': <String, Object?>{
          'ticks': <String, Object?>{'labelOffset': 25},
          'border': <String, Object?>{'display': false},
          'grid': <String, Object?>{'display': false},
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
