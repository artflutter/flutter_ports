// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/stack-multiple-scales.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['0', '1', '2', '3'],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'rgba(255, 0, 0, 0.5)',
          'data': <Object?>[null, 1, 1, 1],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toStacked,
        },
        <String, Object?>{
          'backgroundColor': 'rgba(0, 255, 0, 0.5)',
          'data': <Object?>[null, 2, 2, 2],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toStacked,
        },
        <String, Object?>{
          'backgroundColor': 'rgba(0, 0, 255, 0.5)',
          'data': <Object?>[null, 3, 3, 3],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toStacked,
        },
        <String, Object?>{
          'backgroundColor': 'rgba(255, 0, 255, 0.5)',
          'data': <Object?>[0.5, 0.5, 0.5, null],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toStacked, 'yAxisID': 'y2',
        },
        <String, Object?>{
          'backgroundColor': 'rgba(0, 0, 0, 0.5)',
          'data': <Object?>[1.5, 1.5, 1.5, null],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toStacked, 'yAxisID': 'y2',
        },
        <String, Object?>{
          'backgroundColor': 'rgba(255, 255, 0, 0.5)',
          'data': <Object?>[2.5, 2.5, 2.5, null],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toStacked, 'yAxisID': 'y2',
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'spanGaps': false,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'position': 'right', 'stacked': true, 'min': 0},
        'y2': <String, Object?>{'position': 'left', 'stacked': true, 'min': 0},
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{'radius': 0},
        'line': <String, Object?>{'borderColor': 'transparent', 'tension': 0},
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
