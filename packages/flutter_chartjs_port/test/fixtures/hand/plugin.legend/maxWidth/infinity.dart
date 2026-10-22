// Ported from Chart.js v4.5.1+7169e651 test/fixtures/plugin.legend/maxWidth/infinity.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `Infinity` is [double.infinity].
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
      'datasets': <Object?>[
        <String, Object?>{
          'label': '# of Votes',
          'data': <Object?>[12, 19, 3, 5, 2, 3],
          'borderWidth': 1,
        },
        <String, Object?>{
          'label': '# of Points',
          'data': <Object?>[7, 11, 5, 8, 3, 7],
          'borderWidth': 1,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'plugins': <String, Object?>{
        'title': false,
        'tooltip': false,
        'filler': false,
        'legend': <String, Object?>{
          'position': 'left',
          'maxWidth': double.infinity,
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 150, 'height': 75},
  },
};
