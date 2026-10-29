// Ported from Chart.js v4.6.1 test/fixtures/scale.time/data-ty.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  DateTime newDateFromRef(int days) {
    // moment('01/01/2015 12:00', 'DD/MM/YYYY HH:mm').add(days, 'd').toDate()
    // DIVERGES(chartjs): harness-fixture-sources, a moment value.
    return DateTime.utc(2015, 1, 1 + days, 12);
  }

  return <String, Object?>{
    'threshold': 0.01,
    'tolerance': 0.003,
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                't': newDateFromRef(0),
                'y': 1,
              },
              <String, Object?>{
                't': newDateFromRef(1),
                'y': 10,
              },
              <String, Object?>{
                't': newDateFromRef(2),
                'y': 0,
              },
              <String, Object?>{
                't': newDateFromRef(4),
                'y': 5,
              },
              <String, Object?>{
                't': newDateFromRef(6),
                'y': 77,
              },
              <String, Object?>{
                't': newDateFromRef(7),
                'y': 9,
              },
              <String, Object?>{
                't': newDateFromRef(9),
                'y': 5,
              },
            ],
            'fill': false,
            'parsing': <String, Object?>{
              'xAxisKey': 't',
            },
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'type': 'time',
            'position': 'bottom',
            'ticks': <String, Object?>{
              'maxRotation': 0,
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
      'canvas': <String, Object?>{'width': 800, 'height': 200},
    },
  };
}
