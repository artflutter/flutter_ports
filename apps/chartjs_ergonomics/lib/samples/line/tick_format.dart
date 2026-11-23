// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const tickFormat = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Revenue',
      data: .values(sales),
      borderColor: .constant(.solid(teal)),
    ),
  ],
  scales: [LinearAxis(.y, ticks: AxisTicks(callback: thousands))],
);

// One String for each line of the label; null removes the tick.
List<String>? thousands(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => ['€${value.toStringAsFixed(0)}k'];
// #enddocregion sample
