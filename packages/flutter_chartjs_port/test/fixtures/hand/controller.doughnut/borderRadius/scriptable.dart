// Ported from Chart.js v4.6.1 test/fixtures/controller.doughnut/borderRadius/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'doughnut',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[0, 2, 4, null, 6, 8],
          'borderRadius': () => 4,
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'arc': <String, Object?>{
          'backgroundColor': 'transparent',
          'borderColor': '#888',
        },
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
