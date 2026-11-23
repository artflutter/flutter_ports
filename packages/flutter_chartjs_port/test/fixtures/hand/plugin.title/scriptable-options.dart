// Ported from Chart.js v4.6.1 test/fixtures/plugin.title/scriptable-options.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

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
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'x': <String, Object?>{'display': ScaleDisplay.off},
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'y': <String, Object?>{'display': ScaleDisplay.off},
        },
        'plugins': <String, Object?>{
          'legend': false,
          // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
          'title': TitleOptions(
            display: true,
            // DIVERGES(chartjs): adapt-title-scripted, the scriptable text in
            // the one function `scripted`.
            // DIVERGES(chartjs): adapt-title-text-lines, the lines of the text.
            scripted: (context, options) =>
                const TitleOptions(text: ['Title Text']),
          ),
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
