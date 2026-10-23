// Ported from Chart.js v4.5.1+7169e651 test/fixtures/core.interaction/drawActiveElementsOnTop-false.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `jasmine.triggerMouseEvent` (:38) is [triggerMouseEvent] of the harness.
/// The point is a Map with the upstream keys.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bubble',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 1, 'y': 1, 'r': 80},
            <String, Object?>{'x': 1, 'y': 1, 'r': 20},
          ],
          'drawActiveElementsOnTop': false,
          'backgroundColor': (Object? ctx) =>
              jsGet(ctx, 'dataIndex') == 1 ? 'red' : 'blue',
          'hoverBackgroundColor': 'yellow',
          'hoverRadius': 0,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'display': false,
        },
        'y': <String, Object?>{
          'display': false,
        },
      },
      'plugins': <String, Object?>{
        'tooltip': false,
        'legend': false,
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'width': 256,
      'height': 256,
    },
    'run': (Chart chart) async {
      final point = chart.getDatasetMeta(0).data[0];
      await triggerMouseEvent(chart, 'click', <String, Object?>{
        'y': point.y,
        'x': point.x + 25,
      });
    },
  },
};
