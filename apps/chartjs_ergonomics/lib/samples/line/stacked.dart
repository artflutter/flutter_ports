// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const stacked = ChartConfig(
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
  ],
  scales: {'y': LinearAxis(stacked: .on, beginAtZero: true)},
);
// #enddocregion sample
