// Ported from Chart.js v4.6.1 test/fixtures/plugin.subtitle/basic.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADRs 0115
/// and 0197).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// title and the subtitle options as one object each. Each call makes
/// new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'scatter',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 0},
            <String, Object?>{'x': 1, 'y': 1},
            <String, Object?>{'x': 2, 'y': 2},
          ],
          'backgroundColor': 'red',
          'radius': 1,
          'hoverRadius': 0,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'plugins': <String, Object?>{
        'legend': false,
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'title': const TitleOptions(display: true, text: ['Title Text']),
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'subtitle': const SubtitleOptions(
          display: true,
          text: ['SubTitle Text'],
        ),
        'filler': false,
        'tooltip': false,
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 400, 'width': 400},
  },
};
