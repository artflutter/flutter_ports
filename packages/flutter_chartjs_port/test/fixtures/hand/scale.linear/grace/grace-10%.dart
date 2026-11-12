// Ported from Chart.js v4.6.1 test/fixtures/scale.linear/grace/grace-10%.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/grace_length.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>[
        'a',
        'b',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            90,
            -10,
          ],
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        'y': <String, Object?>{
          'display': false,
        },
        'x': <String, Object?>{
          // DIVERGES(chartjs): adapt-length-objects, the length
          // class.
          'grace': const PercentGrace(10),
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'width': 512,
      'height': 128,
    },
  },
};
