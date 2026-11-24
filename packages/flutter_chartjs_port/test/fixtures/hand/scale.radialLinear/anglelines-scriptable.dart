// Ported from Chart.js v4.6.1 test/fixtures/scale.radialLinear/anglelines-scriptable.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.map(<String, Object?>{
  'type': 'radar',
  'data': <String, Object?>{
    'labels': <Object?>['A', 'B', 'C', 'D', 'E'],
  },
  'options': <String, Object?>{
    'responsive': false,
    'scales': <String, Object?>{
      'r': <String, Object?>{
        'grid': <String, Object?>{'display': true},
        'angleLines': <String, Object?>{
          'color': (ScriptableScalePointLabelContext context) {
            return jsToNumber(context.index).remainder(2) == 0
                ? 'red'
                : 'green';
          },
          'lineWidth': (ScriptableScalePointLabelContext context) {
            return jsToNumber(context.index).remainder(2) == 0 ? 1 : 5;
          },
        },
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'pointLabels': <String, Object?>{'display': ScaleDisplay.off},
        'ticks': <String, Object?>{'display': false},
      },
    },
  },
});
