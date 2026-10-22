// Ported from Chart.js v4.5.1+7169e651 test/fixtures/scale.time/labels-date.js (MIT, Chart.js Contributors).
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
    'threshold': 0.1,
    'tolerance': 0.002,
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>[
          newDateFromRef(0),
          newDateFromRef(1),
          newDateFromRef(2),
          newDateFromRef(4),
          newDateFromRef(6),
          newDateFromRef(7),
          newDateFromRef(9),
        ],
        'fill': false,
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'type': 'time',
          },
          'y': <String, Object?>{
            'display': false,
          },
        },
      },
    },
    'options': <String, Object?>{
      'spriteText': true,
      'canvas': <String, Object?>{'width': 1000, 'height': 200},
    },
  };
}
