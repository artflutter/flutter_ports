// Ported from Chart.js v4.6.1 test/fixtures/scale.time/offset-with-no-ticks.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  int day(int day) {
    // moment('<day>/10/2020', 'DD/MM/YYYY').valueOf() in the zone Etc/UTC of
    // test/index.js.
    // DIVERGES(chartjs): harness-fixture-sources, a moment value.
    return DateTime.utc(2020, 10, day).millisecondsSinceEpoch;
  }

  final data = <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'x': day(15),
            'y': 55,
          },
          <String, Object?>{
            'x': day(18),
            'y': 10,
          },
          <String, Object?>{
            'x': day(19),
            'y': 15,
          },
        ],
        'backgroundColor': 'blue',
      },
      <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'x': day(15),
            'y': 6,
          },
          <String, Object?>{
            'x': day(18),
            'y': 11,
          },
          <String, Object?>{
            'x': day(19),
            'y': 16,
          },
        ],
        'backgroundColor': 'green',
      },
      <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'x': day(15),
            'y': 7,
          },
          <String, Object?>{
            'x': day(18),
            'y': 12,
          },
          <String, Object?>{
            'x': day(19),
            'y': 17,
          },
        ],
        'backgroundColor': 'red',
      },
    ],
  };

  return <String, Object?>{
    'description': 'https://github.com/chartjs/Chart.js/issues/7991',
    'config': <String, Object?>{
      'type': 'bar',
      'data': data,
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'type': 'time',
            'time': <String, Object?>{
              'unit': 'month',
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
}
