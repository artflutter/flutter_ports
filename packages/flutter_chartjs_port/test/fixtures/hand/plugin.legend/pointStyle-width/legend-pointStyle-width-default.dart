// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/pointStyle-width/legend-pointStyle-width-default.json (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['A', 'B', 'C'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[10, 10, 10],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
          'borderWidth': 1,
          'label': '',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const LinePointStyle(),
        },
        <String, Object?>{
          'data': <Object?>[15, 15, 15],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
          'borderWidth': 1,
          'label': '',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const TrianglePointStyle(),
        },
        <String, Object?>{
          'data': <Object?>[20, 20, 20],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
          'borderWidth': 1,
          'label': '',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const RectRoundedPointStyle(),
        },
        <String, Object?>{
          'data': <Object?>[30, 30, 30],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
          'borderWidth': 1,
          'label': '',
        },
        <String, Object?>{
          'data': <Object?>[40, 40, 40],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
          'borderWidth': 1,
          'label': '',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const RectPointStyle(),
        },
        <String, Object?>{
          'data': <Object?>[25, 25, 25],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
          'borderWidth': 1,
          'label': '',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const RectRotPointStyle(),
        },
        <String, Object?>{
          'data': <Object?>[35, 35, 35],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
          'borderWidth': 1,
          'label': '',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const CrossRotPointStyle(),
        },
        <String, Object?>{
          'data': <Object?>[45, 45, 45],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
          'borderWidth': 1,
          'label': '',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const CrossPointStyle(),
        },
        <String, Object?>{
          'data': <Object?>[50, 50, 50],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
          'borderWidth': 1,
          'label': '',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const StarPointStyle(),
        },
        <String, Object?>{
          'data': <Object?>[55, 55, 55],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
          'borderWidth': 1,
          'label': '',
          // DIVERGES(chartjs): adapt-point-style-objects, the style
          // class.
          'pointStyle': const DashPointStyle(),
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': <String, Object?>{
          'display': true,
          'labels': <String, Object?>{'usePointStyle': true},
        },
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 1024},
  },
};
