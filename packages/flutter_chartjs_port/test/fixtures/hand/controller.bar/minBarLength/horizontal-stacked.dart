// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/minBarLength/horizontal-stacked.js (MIT, Chart.js Contributors).
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
      'labels': <Object?>[0, 1, 2, 3, 4],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0, 0.01, 30],
          'backgroundColor': '#00ff00',
          'borderColor': '#000',
          'borderWidth': 4,
          'minBarLength': 20,
          'xAxisID': 'x2',
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'stack': 'demo',
          'ticks': <String, Object?>{'display': false},
        },
        'x2': <String, Object?>{
          'type': 'linear',
          'position': 'bottom',
          'stack': 'demo',
          'stackWeight': 1,
          'ticks': <String, Object?>{'display': false},
        },
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
  },
};
