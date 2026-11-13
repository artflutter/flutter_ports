// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/dataset/spline-span.json (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'rgba(255, 0, 0, 0.25)',
          'data': <Object?>[null, null, 0, -1, 0, 1, 0, -1, 0],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': const FillTarget.toDataset(1),
        },
        <String, Object?>{
          'backgroundColor': 'rgba(0, 255, 0, 0.25)',
          'data': <Object?>[1, 0, null, 1, 0, null, -1, 0, 1],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toNext,
        },
        <String, Object?>{
          'backgroundColor': 'rgba(0, 0, 255, 0.25)',
          'data': <Object?>[0, 2, 0, -2, 0, 2, 0],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': const FillTarget.toDataset(3),
        },
        <String, Object?>{
          'backgroundColor': 'rgba(255, 0, 255, 0.25)',
          'data': <Object?>[2, 0, -2, 0, 2, 0, -2, 0, 2],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': const FillTarget.toRelative(-2),
        },
        <String, Object?>{
          'backgroundColor': 'rgba(255, 255, 0, 0.25)',
          'data': <Object?>[3, 1, -1, -3, -1, 1, 3, 1, -1],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toPrevious,
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'spanGaps': true,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{'radius': 0},
        'line': <String, Object?>{
          // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
          // class.
          'cubicInterpolationMode': const MonotoneCubicInterpolationMode(),
          'borderColor': 'transparent',
        },
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
