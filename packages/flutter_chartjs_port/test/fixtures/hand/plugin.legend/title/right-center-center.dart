// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/title/right-center-center.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
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
      'datasets': <Object?>[
        <String, Object?>{'label': 'a', 'data': <Object?>[]},
        <String, Object?>{'label': 'b', 'data': <Object?>[]},
        <String, Object?>{'label': 'c', 'data': <Object?>[]},
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'legend': const LegendOptions(
          position: ChartPosition.right,
          align: ChartAlign.center,
          title: LegendTitleOptions(
            display: true,
            position: ChartAlign.center,
            text: ['title'],
          ),
        ),
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 256, 'width': 256},
  },
};
