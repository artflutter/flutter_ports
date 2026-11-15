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

/// The fill color that goes with [teal].
const Color tealFill = Color.fromRGBO(75, 192, 192, 0.25);

/// The third line color of the examples.
const Color blue = Color.fromRGBO(54, 162, 235, 1);

/// The fill color that goes with [blue].
const Color blueFill = Color.fromRGBO(54, 162, 235, 0.25);

// #docregion bar-stack-groups
const groupedStacks = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Mobile 2026',
      data: [30, 35, 28, 40, 45, 42, 50],
      backgroundColor: .constant(.solid(teal)),
      stack: '2026',
    ),
    BarDataset(
      label: 'Desktop 2026',
      data: [20, 25, 22, 18, 24, 30, 26],
      backgroundColor: .constant(.solid(blue)),
      stack: '2026',
    ),
    BarDataset(
      label: 'Mobile 2025',
      data: [25, 28, 30, 33, 36, 38, 41],
      backgroundColor: .constant(.solid(tealFill)),
      stack: '2025',
    ),
    BarDataset(
      label: 'Desktop 2025',
      data: [24, 26, 25, 21, 27, 29, 28],
      backgroundColor: .constant(.solid(blueFill)),
      stack: '2025',
    ),
  ],
  scales: {'x': CategoryAxis(stacked: true), 'y': LinearAxis(stacked: true)},
);
// #enddocregion bar-stack-groups

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: groupedStacks)),
        ),
      ),
    ),
  );
}
