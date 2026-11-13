// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/issue81.js (MIT, Jukka Kurkela).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'column': <String, Object?>{
            'Air1': 1,
            'Air2': 2,
            'Oil': 0,
            'Oil1': 1,
            'Stuff1': 1,
            'Stuff2': 2,
          },
          'data': <Object?>[
            <String, Object?>{'flow': 15, 'from': 'Oil', 'to': 'Air1'},
            <String, Object?>{'flow': 20, 'from': 'Oil', 'to': 'Stuff1'},
            <String, Object?>{'flow': 25, 'from': 'Oil1', 'to': 'Air2'},
            <String, Object?>{'flow': 25, 'from': 'Oil1', 'to': 'Stuff2'},
          ],
          'priority': <String, Object?>{
            'Air': 3,
            'Air2': 1,
            'Oil': 1,
            'Oil1': 2,
            'Stuff1': 2,
            'Stuff2': 1,
          },
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
