// Ported from Chart.js v4.6.1 test/fixtures/scale.radialLinear/pointLabels/background.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter/painting.dart' show EdgeInsets;

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'tolerance': 0.01,
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>[
        <Object?>['VENTE ET', 'COMMERCIALISATION'],
        <Object?>['GESTION', 'FINANCIÈRE'],
        'NUMÉRIQUE',
        <Object?>['ADMINISTRATION', 'ET OPÉRATION'],
        <Object?>['RESSOURCES', 'HUMAINES'],
        'INNOVATION',
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': '#E43E51',
          'label': 'Compétences entrepreunariales',
          'data': <Object?>[3.0, 2.0, 2.0, 1.0, 3.0, 1.0],
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': false,
        'tooltip': false,
        'filler': false,
      },
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'min': 0.0,
          'max': 3.0,
          'pointLabels': <String, Object?>{
            'backdropColor': 'blue',
            'backdropPadding': const EdgeInsets.fromLTRB(5, 2, 5, 2),
          },
          'ticks': <String, Object?>{
            'display': false,
            'stepSize': 1.0,
            'maxTicksLimit': 1.0,
          },
        },
      },
      'responsive': true,
      'maintainAspectRatio': false,
    },
  },
  'options': <String, Object?>{'spriteText': true},
};
