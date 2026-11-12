// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/padding/2cols-with-padding.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/types/layout.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/9278',
  'config': <String, Object?>{
    'type': 'pie',
    'data': <String, Object?>{
      'labels': <Object?>[
        'a',
        'b',
        'c',
        'd',
        'e',
        'f',
        'g',
        'h',
        'i',
        'j',
        'k',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            1.0,
            2.0,
            3.0,
            4.0,
            5.0,
            6.0,
            7.0,
            8.0,
            9.0,
            10.0,
            11.0,
          ],
          'backgroundColor': 'red',
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': <String, Object?>{'position': ChartPosition.left},
      },
      'layout': <String, Object?>{
        'padding': const EdgeInsets.fromLTRB(30, 50, 30, 50),
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 400.0, 'height': 300.0},
  },
};
