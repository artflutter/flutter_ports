// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/skipNull/bar-skip-null-object-data.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The keys of the `data` objects are numbers in the source. A JavaScript
/// property key is a string: `{0: 5}` has the key `'0'`.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <String, Object?>{'0': 5, '1': 20, '2': 1, '3': 10},
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
        },
        <String, Object?>{
          'data': <String, Object?>{
            '0': 10,
            '1': null,
            '2': 1,
            '3': double.nan,
          },
          'backgroundColor': '#ff0000',
          'borderColor': '#ff0000',
        },
      ],
    },
    'options': <String, Object?>{
      'skipNull': true,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
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
