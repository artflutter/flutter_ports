// Ported from Chart.js v4.6.1 test/fixtures/core.layouts/no-boxes-all-padding.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleDisplay;

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0.0],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0.0],
          'radius': 16.0,
          'borderWidth': 0.0,
          'backgroundColor': 'red',
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': false,
        'tooltip': false,
        'title': false,
        'filler': false,
      },
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{'display': ScaleDisplay.off, 'offset': true},
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'y': <String, Object?>{'display': ScaleDisplay.off},
      },
      'layout': <String, Object?>{'padding': const EdgeInsets.all(16)},
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 32.0, 'width': 32.0},
  },
};
