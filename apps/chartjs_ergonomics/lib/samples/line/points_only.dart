// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const pointsOnly = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: sales,
      showLine: false,
      pointRadius: 6,
      pointBackgroundColor: .constant(.solid(teal)),
    ),
  ],
);
// #enddocregion sample
