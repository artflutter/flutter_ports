// Ported from Chart.js v4.6.1 test/fixtures/scale.time/autoskip-major.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[];
  for (var i = 0; i < 60; i++) {
    // moment('Jan 01 1990', 'MMM DD YYYY'), then date.clone().add(1, 'month')
    // at each pass, and date.valueOf() in the zone Etc/UTC of test/index.js.
    // DIVERGES(chartjs): harness-fixture-sources, a moment value.
    final x = DateTime.utc(1990, 1 + i).millisecondsSinceEpoch;
    data.add(<String, Object?>{'x': x, 'y': i});
  }

  return <String, Object?>{
    'threshold': 0.05,
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'xAxisID': 'x',
            'data': data,
            'fill': false,
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'type': 'time',
            'ticks': <String, Object?>{
              'major': <String, Object?>{
                'enabled': true,
              },
              'source': 'data',
              'autoSkip': true,
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
    },
  };
}
