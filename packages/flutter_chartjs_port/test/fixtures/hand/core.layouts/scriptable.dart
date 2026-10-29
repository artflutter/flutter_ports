// Ported from Chart.js v4.6.1 test/fixtures/core.layouts/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

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
      'labels': <Object?>['tick1', 'tick2', 'tick3', 'tick4', 'tick5', 'tick6'],
    },
    'options': <String, Object?>{
      'layout': <String, Object?>{
        'padding': (Object? ctx) {
          // 10% padding
          final horizontalPadding = (jsGet(ctx, 'chart')! as Chart).width * 0.1;
          final verticalPadding = (jsGet(ctx, 'chart')! as Chart).height * 0.1;
          return <String, Object?>{
            'top': verticalPadding,
            'right': horizontalPadding,
            'bottom': verticalPadding,
            'left': horizontalPadding,
          };
        },
      },
      'plugins': <String, Object?>{
        'legend': false,
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'category',
          'ticks': <String, Object?>{
            'maxRotation': 0,
            'autoSkip': false,
          },
        },
        'y': <String, Object?>{
          'type': 'linear',
          'position': 'right',
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{
      'height': 150,
      'width': 512,
    },
  },
};
