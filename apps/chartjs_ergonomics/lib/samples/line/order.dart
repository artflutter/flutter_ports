// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const order = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales (order 1, below)',
      data: sales,
      borderColor: .constant(.solid(teal)),
      backgroundColor: .constant(.solid(teal)),
      fill: .toOrigin,
      order: 1,
    ),
    LineDataset(
      label: 'Costs (order 0, on top)',
      data: costs,
      borderColor: .constant(.solid(red)),
      backgroundColor: .constant(.solid(red)),
      fill: .toOrigin,
      order: 0,
    ),
  ],
);
// #enddocregion sample
