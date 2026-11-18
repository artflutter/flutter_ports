// Ported from Chart.js v4.6.1 docs/charts/scatter.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
import 'dart:ui';

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The scatter chart of `docs/charts/scatter.md:5-47`, with each key and
/// value of the docs block.
ChartConfig scatterConfig() => ChartConfig(
  type: .scatter,
  datasets: [
    ScatterDataset(
      label: 'Scatter Dataset',
      points: [
        DataPoint(-10, 0),
        DataPoint(0, 10),
        DataPoint(10, 5),
        DataPoint(0.5, 5.5),
      ],
      backgroundColor: const ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 1)),
      ),
    ),
  ],
  scales: const {'x': LinearAxis(position: .bottom)},
);
