// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const curve = <num?>[0, 20, 20, 60, 60, 120, 180, 120, 125, 105, 110, 170];

const monotone = ChartConfig(
  type: .line,
  labels: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
  datasets: [
    LineDataset(
      label: 'Default',
      data: curve,
      borderColor: .constant(.solid(red)),
      tension: 0.4,
    ),
    LineDataset(
      label: 'Monotone',
      data: curve,
      borderColor: .constant(.solid(blue)),
      tension: 0.4,
      cubicInterpolationMode: MonotoneCubicInterpolationMode(),
    ),
  ],
);
// #enddocregion sample
