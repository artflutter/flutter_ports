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

/// The fill color that goes with [teal].
const Color tealFill = Color.fromRGBO(75, 192, 192, 0.25);

/// The second line color of the examples.
const Color red = Color.fromRGBO(255, 99, 132, 1);

/// The fill color that goes with [red].
const Color redFill = Color.fromRGBO(255, 99, 132, 0.25);

// #docregion bar-interactions
const hoverBars = BarDataset(
  label: 'Move the pointer over a bar',
  data: values,
  backgroundColor: .constant(.solid(tealFill)),
  borderColor: .constant(.solid(teal)),
  borderWidth: 1,
  hoverBackgroundColor: .constant(.solid(redFill)),
  hoverBorderColor: .constant(.solid(red)),
  hoverBorderWidth: 3,
  extra: {'hoverBorderRadius': 8},
);
// #enddocregion bar-interactions

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: ChartView(
              config: ChartConfig(labels: months, datasets: [hoverBars]),
            ),
          ),
        ),
      ),
    ),
  );
}
