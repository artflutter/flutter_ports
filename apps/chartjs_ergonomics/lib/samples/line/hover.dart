// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const hover = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: sales,
      borderColor: .constant(.solid(teal)),
      pointRadius: 5,
      pointHoverRadius: 11,
      pointHoverBackgroundColor: .constant(.solid(red)),
      pointHoverBorderColor: .constant(.solid(redFill)),
    ),
  ],
);
// #enddocregion sample
