// Ported from Chart.js v4.6.1 test/fixtures/plugin.colors/bubble.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bubble',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 12, 'y': 54, 'r': 22.4},
          ],
        },
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 18, 'y': 38, 'r': 25},
          ],
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
