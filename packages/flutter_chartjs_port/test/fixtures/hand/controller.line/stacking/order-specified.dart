// Ported from Chart.js v4.6.1 test/fixtures/controller.line/stacking/order-specified.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleDisplay;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/types/chart_meta.dart' show StackMode;

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[3.0, 1.0, 2.0, 0.0, 8.0, 1.0],
          'backgroundColor': '#ff0000',
          'order': 2.0,
        },
        <String, Object?>{
          'data': <Object?>[0.0, 4.0, 2.0, 6.0, 4.0, 8.0],
          'backgroundColor': '#00ff00',
          'order': 1.0,
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{'fill': FillTarget.toOrigin},
        'point': <String, Object?>{'radius': 0.0},
      },
      'layout': <String, Object?>{'padding': const EdgeInsets.all(32)},
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{
          'stacked': StackMode.on,
          'display': ScaleDisplay.off,
        },
        // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'y': <String, Object?>{
          'stacked': StackMode.on,
          'display': ScaleDisplay.off,
        },
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
        'filler': true,
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256.0, 'width': 512.0},
  },
};
