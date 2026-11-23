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

/// The values of the first docs chart.
const List<num?> values = [65, 59, 80, 81, 56, 55, 40];

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

// #docregion scopes
const scopedLine = ChartConfig(
  labels: months,
  // For this dataset only.
  datasets: [
    LineDataset(
      label: 'Sales',
      data: .values(values),
      borderColor: .constant(.solid(teal)),
    ),
  ],
  // For all line elements and all point elements.
  elements: ChartElements(
    line: LineElementStyle(tension: 0.3, borderWidth: 4),
    point: PointElementStyle(radius: 6),
  ),
  // For all line datasets. This scope has no parameter.
  extra: {
    'datasets': {
      'line': {'pointHoverRadius': 10},
    },
  },
);
// #enddocregion scopes

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: scopedLine)),
        ),
      ),
    ),
  );
}
