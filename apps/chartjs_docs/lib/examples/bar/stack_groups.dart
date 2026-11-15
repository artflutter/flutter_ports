// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-stack-groups
const groupedStacks = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Mobile 2026',
      data: [30, 35, 28, 40, 45, 42, 50],
      backgroundColor: .constant(.solid(teal)),
      stack: '2026',
    ),
    BarDataset(
      label: 'Desktop 2026',
      data: [20, 25, 22, 18, 24, 30, 26],
      backgroundColor: .constant(.solid(blue)),
      stack: '2026',
    ),
    BarDataset(
      label: 'Mobile 2025',
      data: [25, 28, 30, 33, 36, 38, 41],
      backgroundColor: .constant(.solid(tealFill)),
      stack: '2025',
    ),
    BarDataset(
      label: 'Desktop 2025',
      data: [24, 26, 25, 21, 27, 29, 28],
      backgroundColor: .constant(.solid(blueFill)),
      stack: '2025',
    ),
  ],
  scales: {'x': CategoryAxis(stacked: true), 'y': LinearAxis(stacked: true)},
);
// #enddocregion bar-stack-groups
