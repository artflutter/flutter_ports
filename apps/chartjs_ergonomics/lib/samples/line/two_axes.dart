// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const twoAxes = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: sales,
      borderColor: .constant(.solid(teal)),
      yAxisID: 'y',
    ),
    LineDataset(
      label: 'Margin, %',
      data: [12, 18, 9, 22, 15, 30, 25],
      borderColor: .constant(.solid(orange)),
      yAxisID: 'margin',
    ),
  ],
  scales: {
    'y': LinearAxis(position: .left),
    'margin': LinearAxis(
      position: .right,
      grid: AxisGrid(drawOnChartArea: false),
    ),
  },
);
// #enddocregion sample
