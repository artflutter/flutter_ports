// Ported from Chart.js v4.6.1 test/fixtures/scale.linear/grace/issue-8912.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/grace_length.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/8912',
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>[
        'Red',
        'Blue',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            10,
            -10,
          ],
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
          // DIVERGES(chartjs): adapt-length-objects, the length
          // class.
          'grace': const PercentGrace(100),
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
  },
};
