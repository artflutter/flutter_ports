// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion cubic
const cubicLines = ChartConfig(
  type: .line,
  labels: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
  datasets: [
    LineDataset(
      label: 'default',
      data: [0, 20, 20, 60, 60, 120, 180, 120, 125, 105, 110, 170],
      borderColor: .constant(.solid(red)),
      tension: 0.4,
    ),
    LineDataset(
      label: 'monotone',
      data: [0, 20, 20, 60, 60, 120, 180, 120, 125, 105, 110, 170],
      borderColor: .constant(.solid(blue)),
      tension: 0.4,
      cubicInterpolationMode: MonotoneCubicInterpolationMode(),
    ),
  ],
);
// #enddocregion cubic
