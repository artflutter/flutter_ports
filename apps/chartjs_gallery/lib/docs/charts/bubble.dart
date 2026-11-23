// Ported from Chart.js v4.6.1 docs/charts/bubble.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
import 'dart:ui';

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The bubble chart of `docs/charts/bubble.md:5-36`, with each key and
/// value of the docs block.
ChartConfig bubbleConfig() => ChartConfig(
  datasets: [
    BubbleDataset(
      label: 'First Dataset',
      data: [DataPoint.bubble(20, 30, 15), DataPoint.bubble(40, 10, 10)],
      backgroundColor: const ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 1)),
      ),
    ),
  ],
);
