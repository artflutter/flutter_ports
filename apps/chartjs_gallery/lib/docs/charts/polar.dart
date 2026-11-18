// Ported from Chart.js v4.6.1 docs/charts/polar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
import 'dart:ui';

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The polar area chart of `docs/charts/polar.md:7-43`, with each key and
/// value of the docs block.
ChartConfig polarAreaConfig() => const ChartConfig(
  type: .polarArea,
  labels: ['Red', 'Green', 'Yellow', 'Grey', 'Blue'],
  datasets: [
    PolarAreaDataset(
      label: 'My First Dataset',
      data: [11, 16, 7, 3, 14],
      backgroundColor: ChartValue.indexed([
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 1)),
        ChartPaint.solid(Color.fromRGBO(75, 192, 192, 1)),
        ChartPaint.solid(Color.fromRGBO(255, 205, 86, 1)),
        ChartPaint.solid(Color.fromRGBO(201, 203, 207, 1)),
        ChartPaint.solid(Color.fromRGBO(54, 162, 235, 1)),
      ]),
    ),
  ],
);
