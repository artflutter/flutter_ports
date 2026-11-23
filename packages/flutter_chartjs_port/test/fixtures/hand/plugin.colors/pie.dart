// Ported from Chart.js v4.6.1 test/fixtures/plugin.colors/pie.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'pie',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0, 2, 4, null, 6, 8],
        },
        <String, Object?>{
          'data': <Object?>[5, 1, 6, 2, null, 9],
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': false,
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'colors': const ColorsPluginOptions(enabled: true),
      },
    },
  },
};
