// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-dataset-config
const thinBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Thin bars',
      barPercentage: 0.5,
      barThickness: 6,
      maxBarThickness: 8,
      minBarLength: 2,
      data: [10, 20, 30, 40, 50, 60, 70],
    ),
  ],
);
// #enddocregion bar-dataset-config
