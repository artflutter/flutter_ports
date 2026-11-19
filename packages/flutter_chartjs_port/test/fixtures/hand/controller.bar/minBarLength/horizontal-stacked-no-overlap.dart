// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/minBarLength/horizontal-stacked-no-overlap.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleDisplay;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/chart_meta.dart' show StackMode;

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>[1, 2, 3, 4],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, -1, 1, 20],
          'backgroundColor': '#bb000066',
          'minBarLength': 50,
        },
        <String, Object?>{
          'data': <Object?>[1, -1, -1, -20],
          'backgroundColor': '#00bb0066',
          'minBarLength': 50,
        },
        <String, Object?>{
          'data': <Object?>[1, -1, 1, 40],
          'backgroundColor': '#0000bb66',
          'minBarLength': 50,
        },
        <String, Object?>{
          'data': <Object?>[1, -1, -1, -40],
          'backgroundColor': '#00000066',
          'minBarLength': 50,
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{
          'display': ScaleDisplay.off,
          'stacked': StackMode.on,
        },
        'y': <String, Object?>{
          'type': 'linear',
          'position': 'left',
          // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
          'stacked': StackMode.on,
          'ticks': <String, Object?>{'display': false},
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
  },
};
