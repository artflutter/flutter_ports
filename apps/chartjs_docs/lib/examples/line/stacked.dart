// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
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

/// The second line color of the examples.
const Color red = Color.fromRGBO(255, 99, 132, 1);

/// The fill color that goes with [red].
const Color redFill = Color.fromRGBO(255, 99, 132, 0.25);

/// The third line color of the examples.
const Color blue = Color.fromRGBO(54, 162, 235, 1);

/// The fill color that goes with [blue].
const Color blueFill = Color.fromRGBO(54, 162, 235, 0.25);

// #docregion stacked
const stackedLines = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Mobile',
      data: [30, 35, 28, 40, 45, 42, 50],
      borderColor: .constant(.solid(teal)),
      backgroundColor: .constant(.solid(tealFill)),
      fill: .toStacked,
    ),
    LineDataset(
      label: 'Desktop',
      data: [20, 25, 22, 18, 24, 30, 26],
      borderColor: .constant(.solid(blue)),
      backgroundColor: .constant(.solid(blueFill)),
      fill: .toStacked,
    ),
    LineDataset(
      label: 'Tablet',
      data: [10, 8, 12, 14, 9, 11, 15],
      borderColor: .constant(.solid(red)),
      backgroundColor: .constant(.solid(redFill)),
      fill: .toStacked,
    ),
  ],
  scales: {'y': LinearAxis(stacked: true, beginAtZero: true)},
);
// #enddocregion stacked

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: stackedLines)),
        ),
      ),
    ),
  );
}
