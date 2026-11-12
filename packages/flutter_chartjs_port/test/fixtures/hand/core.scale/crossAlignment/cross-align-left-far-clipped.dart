// Ported from Chart.js v4.6.1 test/fixtures/core.scale/crossAlignment/cross-align-left-far-clipped.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 2, 3],
        },
      ],
      'labels': <Object?>[
        'Long long long long label 1',
        'Label 2',
        'Less more longer label 3',
      ],
    },
    'options': <String, Object?>{
      'indexAxis': 'y',
      'scales': <String, Object?>{
        'y': <String, Object?>{
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          'ticks': <String, Object?>{
            // DIVERGES(chartjs): adapt-scale-option-enums, the enum value.
            'crossAlign': TickCrossAlign.far,
          },
          'afterFit': (Scale axis) {
            axis.width = 64;
          },
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'height': 256,
      'width': 512,
    },
  },
};
