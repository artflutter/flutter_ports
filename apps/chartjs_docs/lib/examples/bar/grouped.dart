// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The second dataset of the examples with two datasets.
const List<num?> lastYear = [50, 62, 71, 60, 48, 66, 52];

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

/// The third line color of the examples.
const Color blue = Color.fromRGBO(54, 162, 235, 1);

// #docregion bar-grouped
const groupedBars = ChartConfig(
  labels: months,
  datasets: [
    BarDataset(
      label: 'This year',
      data: .values(values),
      backgroundColor: .constant(.solid(teal)),
    ),
    BarDataset(
      label: 'Last year',
      data: .values(lastYear),
      backgroundColor: .constant(.solid(blue)),
    ),
  ],
);
// #enddocregion bar-grouped

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: groupedBars)),
        ),
      ),
    ),
  );
}
