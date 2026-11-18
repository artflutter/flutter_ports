// Ported from Chart.js v4.6.1 docs/charts/mixed.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
import 'dart:ui';

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The mixed chart of `docs/charts/mixed.md:27-70`: a `scatter` chart with
/// a `bar` and a `line` dataset, with each key and value of the docs block.
ChartConfig mixedConfig() => const ChartConfig(
  type: .scatter,
  labels: ['January', 'February', 'March', 'April'],
  datasets: [
    BarDataset(
      label: 'Bar Dataset',
      data: [10, 20, 30, 40],
      borderColor: ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 1)),
      ),
      backgroundColor: ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 0.2)),
      ),
    ),
    LineDataset(
      label: 'Line Dataset',
      data: [50, 50, 50, 50],
      fill: .none,
      borderColor: ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(54, 162, 235, 1)),
      ),
    ),
  ],
  scales: {'y': LinearAxis(beginAtZero: true)},
);
