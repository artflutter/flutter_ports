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

// #docregion bar-border-radius-stacked
const roundedStack = ChartConfig(
  labels: months,
  datasets: [
    BarDataset(
      label: 'Mobile',
      data: [30, 35, 28, 40, 45, 42, 50],
      backgroundColor: .constant(.solid(teal)),
      borderRadius: 10,
    ),
    BarDataset(
      label: 'Desktop',
      data: [20, 25, 22, 18, 24, 30, 26],
      backgroundColor: .constant(.solid(blue)),
      borderRadius: 10,
    ),
  ],
  scales: {
    'x': CategoryAxis(stacked: StackMode.on),
    'y': LinearAxis(stacked: StackMode.on),
  },
);
// #enddocregion bar-border-radius-stacked

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: roundedStack)),
        ),
      ),
    ),
  );
}
