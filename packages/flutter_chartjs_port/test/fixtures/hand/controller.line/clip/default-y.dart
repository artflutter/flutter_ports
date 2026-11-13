// Ported from Chart.js v4.6.1 test/fixtures/controller.line/clip/default-y.json (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'scatter',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'borderColor': 'red',
          'data': <Object?>[
            <String, Object?>{'x': -5.0, 'y': 5.0},
            <String, Object?>{'x': -4.0, 'y': 6.0},
            <String, Object?>{'x': -3.0, 'y': 7.0},
            <String, Object?>{'x': -2.0, 'y': 6.0},
            <String, Object?>{'x': -1.0, 'y': 5.0},
            <String, Object?>{'x': 0.0, 'y': 4.0},
            <String, Object?>{'x': 1.0, 'y': 3.0},
            <String, Object?>{'x': 2.0, 'y': 2.0},
            <String, Object?>{'x': 3.0, 'y': 5.0},
            <String, Object?>{'x': 4.0, 'y': 7.0},
            <String, Object?>{'x': 5.0, 'y': 9.0},
          ],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
          'showLine': true,
          'borderWidth': 20.0,
          'pointRadius': 0.0,
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
        },
        'y': <String, Object?>{
          'min': 2.0,
          'max': 6.0,
          'ticks': <String, Object?>{'display': false},
        },
      },
      'layout': <String, Object?>{'padding': const EdgeInsets.all(24)},
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256.0, 'width': 512.0},
  },
};
