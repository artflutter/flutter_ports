// Ported from Chart.js v4.6.1 test/fixtures/scale.radialLinear/circular-border-dash.json (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.map(<String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>['A', 'B', 'C', 'D', 'E'],
    },
    'options': <String, Object?>{
      'responsive': false,
      'scales': <String, Object?>{
        'r': <String, Object?>{
          // DIVERGES(chartjs): adapt-native-scale-border, the border object.
          'border': const RadialAxisBorder(dash: <double>[4, 2], dashOffset: 2),
          'grid': <String, Object?>{
            'circular': true,
            'color': 'rgba(0, 0, 255, 0.5)',
            'lineWidth': 1,
          },
          'angleLines': <String, Object?>{
            'color': 'rgba(0, 0, 255, 0.5)',
            'lineWidth': 1,
            // DIVERGES(chartjs): adapt-dash-lists, a list of doubles.
            'borderDash': <double>[4, 2],
            'borderDashOffset': 2,
          },
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'pointLabels': <String, Object?>{'display': ScaleDisplay.off},
          'ticks': <String, Object?>{'display': false},
        },
      },
    },
  },
});
