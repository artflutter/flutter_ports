// Ported from Chart.js v4.6.1 test/fixtures/scale.time/custom-parser.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'threshold': 0.01,
  'tolerance': 0.0025,
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['foo', 'bar'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0, 1],
          'fill': false,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'time',
          'position': 'bottom',
          'time': <String, Object?>{
            'unit': 'day',
            'round': true,
            'parser': (Object? label) {
              // moment('2000/01/02', 'YYYY/MM/DD') and
              // moment('2016/05/08', 'YYYY/MM/DD').
              // DIVERGES(chartjs): harness-fixture-sources, a moment value.
              return label == 'foo'
                  ? DateTime.utc(2000, 1, 2)
                  : DateTime.utc(2016, 5, 8);
            },
          },
          'ticks': <String, Object?>{
            'source': 'labels',
          },
        },
        'y': <String, Object?>{
          'display': false,
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 256, 'height': 128},
  },
};
