// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.bar/baseLine/value-y.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `context.tick` is a `Tick` of core.scale.dart, a class and not a Map:
/// the color function reads its field `value`.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b'],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': '#AAFFCC',
          'borderColor': '#0000FF',
          'borderWidth': 1,
          'data': <Object?>[1, 3],
        },
      ],
    },
    'options': <String, Object?>{
      'base': 2,
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'display': false,
        },
        'y': <String, Object?>{
          'ticks': <String, Object?>{
            'display': false,
          },
          'grid': <String, Object?>{
            'color': (Object? context) {
              return (jsGet(context, 'tick')! as Tick).value == 2
                  ? 'red'
                  : 'transparent';
            },
            'lineWidth': 5,
            'tickLength': 0,
          },
        },
      },
      'maintainAspectRatio': false,
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'width': 128,
      'height': 128,
    },
  },
};
