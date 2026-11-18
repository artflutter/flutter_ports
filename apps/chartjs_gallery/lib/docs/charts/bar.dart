// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
import 'dart:ui';

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The labels of `Utils.months({count: 7})` (`docs/scripts/utils.js:91-104`).
const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
];

/// The `backgroundColor` of the two blocks.
const ChartValue<ChartPaint> _backgrounds = ChartValue.indexed([
  ChartPaint.solid(Color.fromRGBO(255, 99, 132, 0.2)),
  ChartPaint.solid(Color.fromRGBO(255, 159, 64, 0.2)),
  ChartPaint.solid(Color.fromRGBO(255, 205, 86, 0.2)),
  ChartPaint.solid(Color.fromRGBO(75, 192, 192, 0.2)),
  ChartPaint.solid(Color.fromRGBO(54, 162, 235, 0.2)),
  ChartPaint.solid(Color.fromRGBO(153, 102, 255, 0.2)),
  ChartPaint.solid(Color.fromRGBO(201, 203, 207, 0.2)),
]);

/// The `borderColor` of the two blocks.
const ChartValue<ChartPaint> _borders = ChartValue.indexed([
  ChartPaint.solid(Color.fromRGBO(255, 99, 132, 1)),
  ChartPaint.solid(Color.fromRGBO(255, 159, 64, 1)),
  ChartPaint.solid(Color.fromRGBO(255, 205, 86, 1)),
  ChartPaint.solid(Color.fromRGBO(75, 192, 192, 1)),
  ChartPaint.solid(Color.fromRGBO(54, 162, 235, 1)),
  ChartPaint.solid(Color.fromRGBO(153, 102, 255, 1)),
  ChartPaint.solid(Color.fromRGBO(201, 203, 207, 1)),
]);

/// The vertical bar chart of `docs/charts/bar.md:5-54`, with each key and
/// value of the docs block.
ChartConfig barVerticalConfig() => const ChartConfig(
  type: .bar,
  labels: _months,
  datasets: [
    BarDataset(
      label: 'My First Dataset',
      data: [65, 59, 80, 81, 56, 55, 40],
      backgroundColor: _backgrounds,
      borderColor: _borders,
      borderWidth: 1,
    ),
  ],
  scales: {'y': LinearAxis(beginAtZero: true)},
);

/// The horizontal bar chart of `docs/charts/bar.md:304-351`, without the
/// dataset keys `axis` and `fill`: Chart.js reads neither of them for a bar
/// dataset.
ChartConfig barHorizontalConfig() => const ChartConfig(
  type: .bar,
  labels: _months,
  datasets: [
    BarDataset(
      label: 'My First Dataset',
      data: [65, 59, 80, 81, 56, 55, 40],
      backgroundColor: _backgrounds,
      borderColor: _borders,
      borderWidth: 1,
    ),
  ],
  indexAxis: YAxis(),
);
