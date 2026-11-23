// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
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

/// The line chart of `docs/charts/line.md:5-31`, with each key and value of
/// the docs block.
ChartConfig lineConfig() => const ChartConfig(
  labels: _months,
  datasets: [
    LineDataset(
      label: 'My First Dataset',
      data: .values([65, 59, 80, 81, 56, 55, 40]),
      fill: .none,
      borderColor: ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(75, 192, 192, 1)),
      ),
      tension: 0.1,
    ),
  ],
);

/// The vertical line chart of `docs/charts/line.md:233-285`, without the
/// dataset key `axis`, which Chart.js does not read.
ChartConfig lineVerticalConfig() => const ChartConfig(
  labels: _months,
  datasets: [
    LineDataset(
      label: 'My First Dataset',
      data: .values([65, 59, 80, 81, 56, 55, 40]),
      fill: .none,
      backgroundColor: ChartValue.indexed([
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 0.2)),
        ChartPaint.solid(Color.fromRGBO(255, 159, 64, 0.2)),
        ChartPaint.solid(Color.fromRGBO(255, 205, 86, 0.2)),
        ChartPaint.solid(Color.fromRGBO(75, 192, 192, 0.2)),
        ChartPaint.solid(Color.fromRGBO(54, 162, 235, 0.2)),
        ChartPaint.solid(Color.fromRGBO(153, 102, 255, 0.2)),
        ChartPaint.solid(Color.fromRGBO(201, 203, 207, 0.2)),
      ]),
      borderColor: ChartValue.indexed([
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 1)),
        ChartPaint.solid(Color.fromRGBO(255, 159, 64, 1)),
        ChartPaint.solid(Color.fromRGBO(255, 205, 86, 1)),
        ChartPaint.solid(Color.fromRGBO(75, 192, 192, 1)),
        ChartPaint.solid(Color.fromRGBO(54, 162, 235, 1)),
        ChartPaint.solid(Color.fromRGBO(153, 102, 255, 1)),
        ChartPaint.solid(Color.fromRGBO(201, 203, 207, 1)),
      ]),
      borderWidth: 1,
    ),
  ],
  indexAxis: YAxis(),
  scales: [LinearAxis(.x, beginAtZero: true)],
);
