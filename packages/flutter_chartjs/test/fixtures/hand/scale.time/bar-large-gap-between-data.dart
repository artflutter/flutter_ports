// Ported from Chart.js v4.5.1+7169e651 test/fixtures/scale.time/bar-large-gap-between-data.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  // var date = moment('May 24 2020', 'MMM DD YYYY');
  // DIVERGES(chartjs): harness-fixture-sources, a moment value.
  final date = DateTime.utc(2020, 5, 24);

  return <String, Object?>{
    'threshold': 0.05,
    'config': <String, Object?>{
      'type': 'bar',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'backgroundColor': 'rgba(255, 0, 0, 0.5)',
            // date.clone().add(n, 'day') for each x except the third.
            // DIVERGES(chartjs): harness-fixture-sources, a moment value.
            'data': <Object?>[
              <String, Object?>{
                'x': DateTime.utc(2020, 5, 24 - 2),
                'y': 20,
              },
              <String, Object?>{
                'x': DateTime.utc(2020, 5, 24 - 1),
                'y': 30,
              },
              <String, Object?>{
                'x': date,
                'y': 40,
              },
              <String, Object?>{
                'x': DateTime.utc(2020, 5, 24 + 1),
                'y': 50,
              },
              <String, Object?>{
                'x': DateTime.utc(2020, 5, 24 + 7),
                'y': 10,
              },
            ],
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'display': false,
            'type': 'time',
            'ticks': <String, Object?>{
              'source': 'auto',
            },
            'time': <String, Object?>{
              'unit': 'day',
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
    },
  };
}
