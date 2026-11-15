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

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

/// The third line color of the examples.
const Color blue = Color.fromRGBO(54, 162, 235, 1);

// #docregion bar-skip-null
const skipNullBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'North',
      data: [65, null, 80, null, 56, 55, null],
      backgroundColor: .constant(.solid(teal)),
      extra: {'skipNull': true},
    ),
    BarDataset(
      label: 'South',
      data: [50, 62, null, 60, null, 66, 52],
      backgroundColor: .constant(.solid(blue)),
      extra: {'skipNull': true},
    ),
  ],
);
// #enddocregion bar-skip-null

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: skipNullBars)),
        ),
      ),
    ),
  );
}
