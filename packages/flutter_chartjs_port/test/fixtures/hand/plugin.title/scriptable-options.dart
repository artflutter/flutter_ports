// Ported from Chart.js v4.6.1 test/fixtures/plugin.title/scriptable-options.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[];
  for (var x = 0; x < 3; x++) {
    for (var y = 0; y < 3; y++) {
      data.add(<String, Object?>{'x': x, 'y': y});
    }
  }

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'scatter',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'data': data,
            'backgroundColor': 'red',
            'radius': 1,
            'hoverRadius': 0,
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{'display': false},
          'y': <String, Object?>{'display': false},
        },
        'plugins': <String, Object?>{
          'legend': false,
          'title': <String, Object?>{
            'display': true,
            'text': () => 'Title Text',
          },
          'filler': false,
          'tooltip': false,
        },
      },
    },
    'options': <String, Object?>{
      'spriteText': true,
      'canvas': <String, Object?>{'height': 400, 'width': 400},
    },
  };
}
