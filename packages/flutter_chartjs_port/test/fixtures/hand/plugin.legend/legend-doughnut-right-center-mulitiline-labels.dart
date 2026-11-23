// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/legend-doughnut-right-center-mulitiline-labels.json (MIT, Chart.js Contributors).
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
    'type': 'doughnut',
    'data': <String, Object?>{
      'labels': <Object?>[
        'Example Label',
        <Object?>['I like these colors', 'Red', 'Green', 'Blue', 'Yellow'],
        'Example Label',
        'Example Label',
        'Example Label',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[10, 20, 30, 40, 50],
          'backgroundColor': '#00ff00',
          'borderWidth': 0,
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'legend': const LegendOptions(
          position: ChartPosition.right,
          align: ChartAlign.center,
        ),
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
