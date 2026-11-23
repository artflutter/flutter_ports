// Ported from Chart.js v4.6.1 test/fixtures/plugin.colors/chart-options-colors.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0, 5, 10, null, -10, -5],
        },
        <String, Object?>{
          'data': <Object?>[10, 2, 3, null, 10, 5],
        },
      ],
    },
    'options': <String, Object?>{
      'backgroundColor': <Object?>['red', 'green'],
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
