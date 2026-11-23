// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const stepped = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'before',
      data: .values([10, 40, 25, 60, 45, 80, 70]),
      borderColor: .constant(.solid(teal)),
      stepped: .before,
    ),
    LineDataset(
      label: 'after',
      data: .values([40, 70, 55, 90, 75, 110, 100]),
      borderColor: .constant(.solid(blue)),
      stepped: .after,
    ),
    LineDataset(
      label: 'middle',
      data: .values([70, 100, 85, 120, 105, 140, 130]),
      borderColor: .constant(.solid(red)),
      stepped: .middle,
    ),
  ],
);
// #enddocregion sample
