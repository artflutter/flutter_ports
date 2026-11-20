// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const gaps = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Broken at null',
      data: [65, 59, null, 81, 56, null, 40],
      borderColor: .constant(.solid(red)),
    ),
    LineDataset(
      label: 'spanGaps: true',
      data: [95, 89, null, 111, 86, null, 70],
      borderColor: .constant(.solid(teal)),
      spanGaps: true,
    ),
  ],
);
// #enddocregion sample
