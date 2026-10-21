// Ported from Chart.js v4.5.1+7169e651 test/fixtures/element.line/skip/last.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 10},
            <String, Object?>{'x': 5, 'y': 0},
            <String, Object?>{'x': 15, 'y': -10},
            <String, Object?>{'x': double.nan, 'y': -5},
          ],
          'borderColor': 'red',
          'fill': true,
          'tension': 0,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'linear',
          'display': false,
          'min': 0,
          'max': 20,
        },
        'y': <String, Object?>{'display': false, 'min': -15, 'max': 15},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'height': 256,
      'width': 512,
    },
  },
};
