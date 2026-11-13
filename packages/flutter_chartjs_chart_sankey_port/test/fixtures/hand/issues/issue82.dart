// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/issue82.js (MIT, Jukka Kurkela).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'column': <String, Object?>{
            'Coal': 2,
            'Electricity': 3,
            'Energy': 4,
            'Natural Gas': 1,
            'Oil': 0,
          },
          'data': <Object?>[
            <String, Object?>{'flow': 15, 'from': 'Oil', 'to': 'Energy'},
            <String, Object?>{
              'flow': 20,
              'from': 'Natural Gas',
              'to': 'Energy',
            },
            <String, Object?>{'flow': 25, 'from': 'Coal', 'to': 'Energy'},
            <String, Object?>{
              'flow': 25,
              'from': 'Electricity',
              'to': 'Energy',
            },
          ],
        },
      ],
    },
    'type': 'sankey',
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
    'spriteText': true,
  },
};
