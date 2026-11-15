// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The labels of `Utils.months({count: 7})`.
const List<Object> months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
];

/// The values of the first docs chart.
const List<num?> values = [65, 59, 80, 81, 56, 55, 40];

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

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

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: minLengthBars)),
        ),
      ),
    ),
  );
}
