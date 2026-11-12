// Ported from Chart.js v4.6.1 test/fixtures/core.scale/tick-override-styles.json (MIT, Chart.js Contributors).
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
      'labels': <Object?>[
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
      ],
      'datasets': <Object?>[],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'category',
          'position': 'top',
          'id': 'x-axis-1',
          'ticks': <String, Object?>{
            'display': false,
          },
          'border': <String, Object?>{
            'display': false,
          },
          'grid': <String, Object?>{
            'drawOnChartArea': false,
            'color': 'rgba(0, 0, 0, 1)',
            'width': 1,
            'tickColor': 'rgba(255, 0, 0, 1)',
            'tickWidth': 5,
          },
        },
        'y': <String, Object?>{
          'position': 'left',
          'id': 'y-axis-1',
          'type': 'linear',
          'offset': false,
          'min': -100,
          'max': 100,
          'ticks': <String, Object?>{
            'display': false,
          },
          'border': <String, Object?>{
            'display': false,
          },
          'grid': <String, Object?>{
            'offset': false,
            'drawOnChartArea': false,
            'color': 'rgba(0, 0, 0, 1)',
            'tickColor': 'rgba(255, 0, 0, 1)',
            'tickWidth': 5,
          },
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'height': 256,
      'width': 512,
    },
  },
};
