// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' show YAxis;

/// The vertical bar chart of `docs/charts/bar.md:5-54`.
///
/// The labels are the strings of `Utils.months({count: 7})`
/// (`docs/scripts/utils.js:91-104`). Each other key and value is the docs
/// block.
Map<String, Object?> barVerticalConfig() => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
    ],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 80.0, 81.0, 56.0, 55.0, 40.0],
        'backgroundColor': <Object?>[
          const ChartPaint.solid(ui.Color.fromRGBO(255, 99, 132, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(255, 159, 64, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(255, 205, 86, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(75, 192, 192, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(54, 162, 235, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(153, 102, 255, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(201, 203, 207, 0.2)),
        ],
        'borderColor': <Object?>[
          const ChartPaint.solid(ui.Color.fromRGBO(255, 99, 132, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(255, 159, 64, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(255, 205, 86, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(75, 192, 192, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(54, 162, 235, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(153, 102, 255, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(201, 203, 207, 1)),
        ],
        'borderWidth': 1.0,
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'y': <String, Object?>{'beginAtZero': true},
    },
  },
};

/// The horizontal bar chart of `docs/charts/bar.md:304-351`.
///
/// The labels are the strings of `Utils.months({count: 7})`
/// (`docs/scripts/utils.js:91-104`). Each other key and value is the docs
/// block.
Map<String, Object?> barHorizontalConfig() => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
    ],
    'datasets': <Object?>[
      <String, Object?>{
        'axis': const YAxis(),
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 80.0, 81.0, 56.0, 55.0, 40.0],
        'fill': false,
        'backgroundColor': <Object?>[
          const ChartPaint.solid(ui.Color.fromRGBO(255, 99, 132, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(255, 159, 64, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(255, 205, 86, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(75, 192, 192, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(54, 162, 235, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(153, 102, 255, 0.2)),
          const ChartPaint.solid(ui.Color.fromRGBO(201, 203, 207, 0.2)),
        ],
        'borderColor': <Object?>[
          const ChartPaint.solid(ui.Color.fromRGBO(255, 99, 132, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(255, 159, 64, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(255, 205, 86, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(75, 192, 192, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(54, 162, 235, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(153, 102, 255, 1)),
          const ChartPaint.solid(ui.Color.fromRGBO(201, 203, 207, 1)),
        ],
        'borderWidth': 1.0,
      },
    ],
  },
  'options': <String, Object?>{'indexAxis': const YAxis()},
};
