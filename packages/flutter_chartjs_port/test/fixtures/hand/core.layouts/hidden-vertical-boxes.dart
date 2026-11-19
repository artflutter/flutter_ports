// Ported from Chart.js v4.6.1 test/fixtures/core.layouts/hidden-vertical-boxes.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[10, 5, 0, 25, 78, -10],
        },
      ],
      'labels': <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5', ''],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{'legend': false},
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{'display': ScaleDisplay.off},
        'y': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          'ticks': <String, Object?>{
            // A TickCallback (row adapt-native-tick).
            'callback':
                (Object? scale, double value, int index, Object? ticks) {
                  return <String>['${jsToString(value)} very long unit!'];
                },
          },
        },
        'y1': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
        'y2': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
        'y3': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
        'y4': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
        'y5': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 256, 'width': 256},
  },
};
