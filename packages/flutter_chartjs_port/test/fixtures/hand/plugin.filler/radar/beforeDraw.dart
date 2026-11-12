// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/radar/beforeDraw.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/plugins/filler_draw_time.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
      'datasets': <Object?>[
        <String, Object?>{
          'label': '# of Votes',
          'data': <Object?>[9.0, 7.0, 3.0, 5.0, 2.0, 3.0],
          'fill': FillBoundary.origin,
          'borderColor': 'red',
          'backgroundColor': 'green',
          'pointRadius': 12.0,
          'pointBackgroundColor': 'red',
        },
      ],
    },
    'options': <String, Object?>{
      'layout': <String, Object?>{'padding': const EdgeInsets.all(20)},
      'plugins': <String, Object?>{
        'legend': false,
        'filler': <String, Object?>{'drawTime': FillerDrawTime.beforeDraw},
      },
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'angleLines': <String, Object?>{
            'color': 'rgba(0,0,0,0.5)',
            'lineWidth': 2.0,
          },
          'grid': <String, Object?>{
            'color': 'rgba(0,0,0,0.5)',
            'lineWidth': 2.0,
          },
          'pointLabels': <String, Object?>{'display': false},
          'ticks': <String, Object?>{'beginAtZero': true, 'display': false},
        },
      },
    },
  },
};
