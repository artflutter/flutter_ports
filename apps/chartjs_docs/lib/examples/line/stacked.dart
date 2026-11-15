// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion stacked
const stackedLines = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Mobile',
      data: [30, 35, 28, 40, 45, 42, 50],
      borderColor: .constant(.solid(teal)),
      backgroundColor: .constant(.solid(tealFill)),
      fill: .toStacked,
    ),
    LineDataset(
      label: 'Desktop',
      data: [20, 25, 22, 18, 24, 30, 26],
      borderColor: .constant(.solid(blue)),
      backgroundColor: .constant(.solid(blueFill)),
      fill: .toStacked,
    ),
    LineDataset(
      label: 'Tablet',
      data: [10, 8, 12, 14, 9, 11, 15],
      borderColor: .constant(.solid(red)),
      backgroundColor: .constant(.solid(redFill)),
      fill: .toStacked,
    ),
  ],
  scales: {'y': LinearAxis(stacked: true, beginAtZero: true)},
);
// #enddocregion stacked
