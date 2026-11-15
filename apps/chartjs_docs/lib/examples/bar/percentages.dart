// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The percentage example, with the values of the selected variant.
// #docregion bar-percentages
ChartConfig percentages({required double category, required double bar}) =>
    ChartConfig(
      type: .bar,
      labels: const ['Q1', 'Q2', 'Q3'],
      datasets: [
        for (final (label, data, color) in const [
          ('A', [30, 50, 40], teal),
          ('B', [45, 35, 55], blue),
        ])
          BarDataset(
            label: label,
            data: data,
            backgroundColor: .constant(.solid(color)),
            categoryPercentage: category,
            barPercentage: bar,
          ),
      ],
    );
// #enddocregion bar-percentages
