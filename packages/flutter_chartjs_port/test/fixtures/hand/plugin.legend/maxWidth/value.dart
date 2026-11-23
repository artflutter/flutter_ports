// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/maxWidth/value.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADRs 0115
/// and 0193).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// legend options as one object. Each call makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
      'datasets': <Object?>[
        <String, Object?>{
          'label': '# of Votes',
          'data': <Object?>[12, 19, 3, 5, 2, 3],
          'borderWidth': 1,
        },
        <String, Object?>{
          'label': '# of Points',
          'data': <Object?>[7, 11, 5, 8, 3, 7],
          'borderWidth': 1,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'plugins': <String, Object?>{
        'title': false,
        'tooltip': false,
        'filler': false,
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'legend': const LegendOptions(
          position: ChartPosition.left,
          maxWidth: 100,
        ),
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 150, 'height': 75},
  },
};
