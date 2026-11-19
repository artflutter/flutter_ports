// Ported from Chart.js v4.6.1 test/fixtures/controller.line/borderDashOffset/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/chartjs_core.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[1, 1, 1, 1],
          'borderColor': '#ff0000',
          // DIVERGES(chartjs): adapt-dash-lists, a list of doubles.
          'borderDash': <double>[20],
          'borderDashOffset': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0 ? 5.0 : 0.0;
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[0, 0, 0, 0],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': '#00ff00',
          // DIVERGES(chartjs): adapt-dash-lists, a list of doubles.
          'borderDash': <double>[20],
          'borderDashOffset': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0 ? 5.0 : 0.0;
          },
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
        },
        'point': <String, Object?>{'radius': 10},
      },
      'layout': <String, Object?>{'padding': const EdgeInsets.all(32)},
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{'display': ScaleDisplay.off},
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'y': <String, Object?>{'display': ScaleDisplay.off},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
