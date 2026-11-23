// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

/// The third line color of the examples.
const Color blue = Color.fromRGBO(54, 162, 235, 1);

/// The percentage example, with the values of the selected variant.
// #docregion bar-percentages
ChartConfig percentages({required double category, required double bar}) =>
    ChartConfig(
      labels: const ['Q1', 'Q2', 'Q3'],
      datasets: [
        for (final (label, data, color) in const [
          ('A', [30, 50, 40], teal),
          ('B', [45, 35, 55], blue),
        ])
          BarDataset(
            label: label,
            data: .values(data),
            backgroundColor: .constant(.solid(color)),
            categoryPercentage: category,
            barPercentage: bar,
          ),
      ],
    );
// #enddocregion bar-percentages

void main() {
  Chart.register(registerables);
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ChartView(config: percentages(category: 1, bar: 1)),
          ),
        ),
      ),
    ),
  );
}
