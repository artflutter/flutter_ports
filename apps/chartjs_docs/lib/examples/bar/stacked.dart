// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-stacked
const stackedBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Mobile',
      data: [30, 35, 28, 40, 45, 42, 50],
      backgroundColor: .constant(.solid(teal)),
    ),
    BarDataset(
      label: 'Desktop',
      data: [20, 25, 22, 18, 24, 30, 26],
      backgroundColor: .constant(.solid(blue)),
    ),
    BarDataset(
      label: 'Tablet',
      data: [10, 8, 12, 14, 9, 11, 15],
      backgroundColor: .constant(.solid(red)),
    ),
  ],
  scales: {'x': CategoryAxis(stacked: true), 'y': LinearAxis(stacked: true)},
);
// #enddocregion bar-stacked
