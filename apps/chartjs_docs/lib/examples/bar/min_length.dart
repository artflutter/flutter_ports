// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-min-length
const minLengthBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Small values stay visible',
      data: [65, 0.5, 80, 1, 56, 0, 40],
      backgroundColor: .constant(.solid(teal)),
      minBarLength: 10,
    ),
  ],
);
// #enddocregion bar-min-length
