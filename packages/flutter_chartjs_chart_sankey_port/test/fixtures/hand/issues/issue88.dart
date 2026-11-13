// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/issue88.js (MIT, Jukka Kurkela).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'flow': 10, 'from': 'a', 'to': 'b'},
            <String, Object?>{'flow': 5, 'from': 'a', 'to': 'c'},
            <String, Object?>{'flow': 10, 'from': 'a', 'to': 'd'},
            <String, Object?>{'flow': 7, 'from': 'e', 'to': 'c'},
            <String, Object?>{'flow': 7, 'from': 'c', 'to': 'f'},
            <String, Object?>{'flow': 7, 'from': 'c', 'to': 'g'},
            <String, Object?>{'flow': 7, 'from': 'd', 'to': 'h'},
            <String, Object?>{'flow': 7, 'from': 'h', 'to': 'i'},
          ],
        },
      ],
    },
    'type': 'sankey',
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
    'spriteText': true,
  },
};
