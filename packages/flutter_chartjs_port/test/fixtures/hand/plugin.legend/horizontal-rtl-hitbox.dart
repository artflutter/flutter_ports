// Ported from Chart.js v4.5.1+7169e651 test/fixtures/plugin.legend/horizontal-rtl-hitbox.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The inline plugin reads `legendHitBoxes` through a cast to [Legend]
/// (Chart.js ADR 0038, section 6). A hit box is a Map with the upstream
/// keys.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/9278',
  'config': <String, Object?>{
    'type': 'pie',
    'data': <String, Object?>{
      'labels': <Object?>['aaa', 'bb', 'c'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
          'backgroundColor': 'red',
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': <String, Object?>{'position': 'top', 'rtl': 'true'},
      },
      'layout': <String, Object?>{
        'padding': <String, Object?>{
          'top': 50,
          'left': 30,
          'right': 30,
          'bottom': 50,
        },
      },
    },
    'plugins': <Object?>[
      <String, Object?>{
        'id': 'legend-hit-box',
        'afterDraw': (types.Chart chart) {
          final ctx = chart.ctx!
            ..save()
            ..strokeStyle = 'green'
            ..lineWidth = 1;

          final legend = chart.legend! as Legend;
          for (final box in legend.legendHitBoxes) {
            ctx.strokeRect(
              box['left']! as double,
              box['top']! as double,
              box['width']! as double,
              box['height']! as double,
            );
          }

          ctx.restore();
        },
      },
    ],
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 400, 'height': 300},
  },
};
