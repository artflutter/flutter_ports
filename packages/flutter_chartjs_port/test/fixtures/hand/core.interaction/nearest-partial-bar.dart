// Ported from Chart.js v4.6.1 test/fixtures/core.interaction/nearest-partial-bar.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `jasmine.triggerMouseEvent` (:39) is [triggerMouseEvent] of the harness.
/// The point is a Map with the upstream keys. `chart.chartArea` is set
/// after the first layout of the chart, before the hook runs.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[220, 250, 225],
        },
      ],
    },
    'options': <String, Object?>{
      'events': <Object?>['click'],
      'interaction': <String, Object?>{
        'mode': 'nearest',
      },
      'plugins': <String, Object?>{
        'tooltip': true,
        'legend': false,
      },
      'scales': <String, Object?>{
        'y': <String, Object?>{
          'beginAtZero': false,
        },
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
      final chartArea = chart.chartArea!;
      final point = <String, Object?>{
        'x': chartArea.left + chartArea.width / 2,
        'y': chartArea.top + chartArea.height / 2,
      };
      await triggerMouseEvent(chart, 'click', point);
    },
  },
};
