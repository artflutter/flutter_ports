// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const fillBetween = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Low',
      data: [20, 25, 30, 28, 35, 32, 30],
      borderColor: .constant(.solid(blue)),
    ),
    LineDataset(
      label: 'High',
      data: [50, 62, 58, 70, 75, 66, 72],
      borderColor: .constant(.solid(blue)),
      backgroundColor: .constant(.solid(blueFill)),
      fill: .toPrevious,
    ),
  ],
);
// #enddocregion sample
