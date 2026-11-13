// Ported from Chart.js v4.6.1 test/fixtures/scale.time/custom-parser.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.adapters.dart' show TimeUnit;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'threshold': 0.01,
  'tolerance': 0.0025,
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['foo', 'bar'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0, 1],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'time',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.bottom,
          'time': <String, Object?>{
            // DIVERGES(chartjs): adapt-time-unit-enum, the enum value.
            'unit': TimeUnit.day,
            'round': true,
            'parser': (Object? label) {
              // moment('2000/01/02', 'YYYY/MM/DD') and
              // moment('2016/05/08', 'YYYY/MM/DD').
              // DIVERGES(chartjs): harness-fixture-sources, a moment value.
              return label == 'foo'
                  ? DateTime.utc(2000, 1, 2)
                  : DateTime.utc(2016, 5, 8);
            },
          },
          'ticks': <String, Object?>{
            // DIVERGES(chartjs): adapt-scale-option-enums, the enum value.
            'source': TickSource.labels,
          },
        },
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 256, 'height': 128},
  },
};
