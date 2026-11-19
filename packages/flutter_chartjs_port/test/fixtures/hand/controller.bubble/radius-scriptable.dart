// Ported from Chart.js v4.6.1 test/fixtures/controller.bubble/radius-scriptable.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleDisplay;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bubble',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 0},
            <String, Object?>{'x': 1, 'y': 0},
            <String, Object?>{'x': 2, 'y': 0},
            <String, Object?>{'x': 3, 'y': 0},
            <String, Object?>{'x': 4, 'y': 0},
            <String, Object?>{'x': 5, 'y': 0},
          ],
          'radius': (Object? ctx) {
            return jsToNumber(
                  jsGet(
                    jsGet(
                      jsGet(jsGet(ctx, 'dataset'), 'data'),
                      jsGet(ctx, 'dataIndex'),
                    ),
                    'x',
                  ),
                ) *
                4;
          },
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{'display': ScaleDisplay.off},
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'y': <String, Object?>{'display': ScaleDisplay.off},
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{'backgroundColor': '#444'},
      },
      'layout': <String, Object?>{
        'padding': const EdgeInsets.only(left: 24, right: 24),
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 128, 'width': 256},
  },
};
