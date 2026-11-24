// Ported from Chart.js v4.6.1 test/fixtures/plugin.colors/mixed.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.map(<String, Object?>{
  'data': <String, Object?>{
    'labels': <Object?>[0, 1, 2, 3],
    'datasets': <Object?>[
      <String, Object?>{
        'type': 'line',
        'data': <Object?>[5, 20, 1, 10],
      },
      <String, Object?>{
        'type': 'bar',
        'data': <Object?>[6, 16, 3, 19],
      },
      <String, Object?>{
        'type': 'pie',
        'data': <Object?>[5, 20, 1, 10],
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
});
