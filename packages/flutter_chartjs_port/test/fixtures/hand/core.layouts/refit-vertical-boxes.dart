// Ported from Chart.js v4.6.1 test/fixtures/core.layouts/refit-vertical-boxes.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADRs 0115
/// and 0197).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// title options as one object. Each call makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'tolerance': 0.002,
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[
        'Aaron',
        'Adam',
        'Albert',
        'Alex',
        'Allan',
        'Aman',
        'Anthony',
        'Autoenrolment',
        'Avril',
        'Bernard',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'rgba(252,233,79,0.5)',
          'borderColor': 'rgba(252,233,79,1)',
          'borderWidth': 1,
          'data': <Object?>[101, 185, 24, 311, 17, 21, 462, 340, 140, 24],
        },
      ],
    },
    'options': <String, Object?>{
      'maintainAspectRatio': false,
      'plugins': <String, Object?>{
        'legend': true,
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'title': const TitleOptions(display: true, text: ['test']),
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 185, 'width': 185},
  },
};
