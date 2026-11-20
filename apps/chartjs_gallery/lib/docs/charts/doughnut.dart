// Ported from Chart.js v4.6.1 docs/charts/doughnut.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
import 'dart:ui';

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The labels of the two blocks: `doughnut.md:17-33` and `:55-71` are the
/// same.
const List<String> _labels = ['Red', 'Blue', 'Yellow'];

/// The `backgroundColor` of the two blocks.
const ChartValue<ChartPaint> _backgrounds = ChartValue.indexed([
  ChartPaint.solid(Color.fromRGBO(255, 99, 132, 1)),
  ChartPaint.solid(Color.fromRGBO(54, 162, 235, 1)),
  ChartPaint.solid(Color.fromRGBO(255, 205, 86, 1)),
]);

/// The doughnut chart of `docs/charts/doughnut.md:15-47`, with each key and
/// value of the docs block.
ChartConfig doughnutConfig() => const ChartConfig(
  labels: _labels,
  datasets: [
    DoughnutDataset(
      label: 'My First Dataset',
      data: [300, 50, 100],
      backgroundColor: _backgrounds,
      hoverOffset: 4,
    ),
  ],
);

/// The pie chart of `docs/charts/doughnut.md:53-85`, with each key and
/// value of the docs block.
ChartConfig pieConfig() => const ChartConfig(
  labels: _labels,
  datasets: [
    PieDataset(
      label: 'My First Dataset',
      data: [300, 50, 100],
      backgroundColor: _backgrounds,
      hoverOffset: 4,
    ),
  ],
);
