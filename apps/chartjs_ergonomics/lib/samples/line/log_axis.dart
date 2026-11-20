// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const logAxis = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Users',
      data: [3, 40, 180, 2500, 9000, 60000, 410000],
      borderColor: .constant(.solid(red)),
    ),
  ],
  scales: [LogarithmicAxis(.y)],
);
// #enddocregion sample
