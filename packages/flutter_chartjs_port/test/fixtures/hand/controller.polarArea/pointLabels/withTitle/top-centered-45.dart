// Ported from Chart.js v4.6.1 test/fixtures/controller.polarArea/pointLabels/withTitle/top-centered-45.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADRs 0115
/// and 0197).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// title options as one object. Each call makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'polarArea',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 2, 3, 4],
          'backgroundColor': <Object?>['#f003', '#0f03', '#00f3', '#0003'],
        },
      ],
      'labels': <Object?>[
        <Object?>['label 1', 'line 2'],
        <Object?>['label 2', 'line 2'],
        <Object?>['label 3', 'line 2'],
        <Object?>['label 4', 'line 2'],
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'title': const TitleOptions(display: true, text: ['Chart Title']),
        'legend': false,
      },
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'startAngle': 45,
          'pointLabels': <String, Object?>{
            'display': true,
            'centerPointLabels': true,
          },
        },
      },
    },
  },
  'options': <String, Object?>{'spriteText': true},
};
