// Ported from Chart.js v4.6.1 test/fixtures/core.scale/crossAlignment/mirror-cross-align-right-far.js (MIT, Chart.js Contributors).
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
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            1,
            2,
            3,
          ],
        },
      ],
      'labels': <Object?>[
        'Long long label 1',
        'Label2',
        'Label3',
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        'y': <String, Object?>{
          'position': 'right',
          'ticks': <String, Object?>{
            'mirror': true,
            'crossAlign': 'far',
          },
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'height': 256,
      'width': 512,
    },
  },
};
