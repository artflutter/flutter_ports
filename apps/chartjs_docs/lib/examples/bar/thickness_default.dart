// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-thickness-default
// Bars on a linear x axis, with uneven spaces between the x values.
final unevenPoints = [
  DataPoint(1, 20),
  DataPoint(2, 35),
  DataPoint(4, 30),
  DataPoint(8, 45),
  DataPoint(9, 25),
];

final fitBars = ChartConfig(
  type: .bar,
  datasets: [
    BarDataset(
      label: 'Equal widths',
      points: unevenPoints,
      backgroundColor: const .constant(.solid(teal)),
    ),
  ],
  scales: const {'x': LinearAxis()},
);
// #enddocregion bar-thickness-default
