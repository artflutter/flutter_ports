// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/bar/basic.dart';
import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-horizontal
const horizontalBar = ChartConfig(
  type: .bar,
  labels: months,
  indexAxis: YAxis(),
  datasets: [
    BarDataset(
      label: 'My First Dataset',
      data: [65, 59, 80, 81, 56, 55, 40],
      backgroundColor: .indexed(barFills),
      borderColor: .indexed(barBorders),
      borderWidth: 1,
    ),
  ],
);
// #enddocregion bar-horizontal
