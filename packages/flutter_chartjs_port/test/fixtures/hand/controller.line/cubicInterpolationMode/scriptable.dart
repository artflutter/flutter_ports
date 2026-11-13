// Ported from Chart.js v4.6.1 test/fixtures/controller.line/cubicInterpolationMode/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[0, 4, 2, 6, 4, 8],
          'borderColor': '#ff0000',
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0
                ? const MonotoneCubicInterpolationMode()
                : const DefaultCubicInterpolationMode();
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[2, 6, 4, 8, 6, 10],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': '#00ff00',
          'borderWidth': 20,
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': (Object? ctx) {
            return jsGet(ctx, 'datasetIndex') == 0
                ? const MonotoneCubicInterpolationMode()
                : const DefaultCubicInterpolationMode();
          },
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
          'tension': 0.4,
        },
      },
      'layout': <String, Object?>{'padding': const EdgeInsets.all(32)},
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
