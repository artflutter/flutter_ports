// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const gridBorder = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: sales,
      borderColor: .constant(.solid(teal)),
    ),
  ],
  scales: {
    'x': CategoryAxis(
      grid: AxisGrid(display: false),
      border: AxisBorder(width: 2, color: .solid(Color(0xFF555555))),
    ),
    'y': LinearAxis(
      grid: AxisGrid(color: .solid(Color(0x14000000))),
      border: AxisBorder(display: false),
    ),
  },
);
// #enddocregion sample
