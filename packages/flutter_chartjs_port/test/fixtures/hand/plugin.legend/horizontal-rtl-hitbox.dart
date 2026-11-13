// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/horizontal-rtl-hitbox.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-legend-hit-box, native geometry reads.
// DIVERGES(chartjs): adapt-direct-colors, native paint inputs.
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' as native_ui;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;

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
        // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
        'legend': <String, Object?>{
          'position': ChartPosition.top,
          // DIVERGES(chartjs): adapt-bool-options, the text 'true' of
          // upstream is the bool true.
          'rtl': true,
        },
      },
      'layout': <String, Object?>{
        'padding': const EdgeInsets.only(
          left: 30,
          top: 50,
          right: 30,
          bottom: 50,
        ),
      },
    },
    'plugins': <Object?>[
      <String, Object?>{
        'id': 'legend-hit-box',
        'afterDraw': (types.Chart chart) {
          final ctx = chart.ctx!
            ..save()
            ..strokeStyle = const native_ui.Color(0xff008000)
            ..lineWidth = 1;

          final legend = chart.legend! as Legend;
          for (final box in legend.legendHitBoxes) {
            ctx.strokeRect(box.left, box.top, box.width, box.height);
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
