// Ported from Chart.js v4.5.1+7169e651 test/fixtures/core.interaction/nearest-point-behind-scale.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `jasmine.triggerMouseEvent` (:42) is [triggerMouseEvent] of the harness.
/// The point is a Map with the upstream keys. `chart.chartArea` is set
/// after the first layout of the chart, before the hook runs.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'scatter',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 1, 'y': 1},
            <String, Object?>{'x': 48, 'y': 1},
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'events': <Object?>['click'],
      'interaction': <String, Object?>{
        'mode': 'nearest',
        'intersect': false,
      },
      'plugins': <String, Object?>{
        'tooltip': true,
        'legend': false,
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'min': 5,
          'max': 50,
        },
        'y': <String, Object?>{
          'min': 0,
          'max': 2,
        },
      },
      'layout': <String, Object?>{
        'padding': 50,
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'width': 256,
      'height': 256,
    },
    'run': (Chart chart) async {
      final point = chart.getDatasetMeta(0).data[0];
      await triggerMouseEvent(chart, 'click', <String, Object?>{
        'y': point.y,
        'x': chart.chartArea!.left,
      });
    },
  },
};
