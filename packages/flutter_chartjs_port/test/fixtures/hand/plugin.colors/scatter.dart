// Ported from Chart.js v4.6.1 test/fixtures/plugin.colors/scatter.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'scatter',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 10, 'y': 15},
            <String, Object?>{'x': 15, 'y': 10},
          ],
          'pointRadius': 10,
          'showLine': true,
          'label': 'dataset1',
        },
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 20, 'y': 45},
            <String, Object?>{'x': 5, 'y': 15},
          ],
          'pointRadius': 20,
          'label': 'dataset2',
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
        },
        'y': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
        },
      },
      'plugins': <String, Object?>{
        'legend': false,
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'colors': const ColorsPluginOptions(enabled: true),
      },
    },
  },
};
