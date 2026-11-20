// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const axisRange = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: sales,
      borderColor: .constant(.solid(teal)),
    ),
  ],
  scales: {'y': LinearAxis(min: 0, max: 100, ticks: AxisTicks(stepSize: 25))},
);
// #enddocregion sample
