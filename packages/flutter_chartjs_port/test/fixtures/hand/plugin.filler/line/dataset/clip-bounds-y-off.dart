// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/dataset/clip-bounds-y-off.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart'
    show RelativeFill;

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/12052',
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            55,
            49,
            70,
            71,
            46,
            45,
            30,
          ],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': 1,
          'borderColor': 'rgb(255, 0, 0)',
          'backgroundColor': 'rgba(255, 0, 0, 0.25)',
          'yAxisID': 'y1',
        },
        <String, Object?>{
          'data': <Object?>[
            65,
            59,
            80,
            81,
            56,
            55,
            40,
          ],
          'fill': false,
          'borderColor': 'rgb(255, 0, 0)',
          'yAxisID': 'y1',
        },
        <String, Object?>{
          'data': <Object?>[
            65,
            59,
            80,
            81,
            56,
            55,
            40,
          ],
          'fill': false,
          'borderColor': 'rgb(0, 0, 255)',
          'yAxisID': 'y2',
        },
        <String, Object?>{
          'data': <Object?>[
            75,
            69,
            90,
            91,
            66,
            65,
            50,
          ],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': const RelativeFill(-1),
          'borderColor': 'rgb(0, 0, 255)',
          'backgroundColor': 'rgba(0, 0, 255, 0.25)',
          'yAxisID': 'y2',
        },
      ],
    },
    'options': <String, Object?>{
      'clip': false,
      'animation': false,
      'responsive': false,
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{
          'radius': 0,
        },
        'line': <String, Object?>{
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': const MonotoneCubicInterpolationMode(),
          'borderColor': 'transparent',
          'tension': 0,
        },
      },
      'scales': <String, Object?>{
        'y2': <String, Object?>{
          'axis': 'y',
          'stack': 'stack',
          'max': 80,
          'display': false,
        },
        'y1': <String, Object?>{
          'min': 50,
          'axis': 'y',
          'stack': 'stack',
          'display': false,
        },
        'x': <String, Object?>{
          'display': false,
        },
      },
    },
  },
};
