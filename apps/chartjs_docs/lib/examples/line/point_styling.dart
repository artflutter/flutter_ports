// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The point style example, with the style of the selected variant.
// #docregion point-styling
ChartConfig pointStyling(PointStyle style) => ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Visitors',
      data: values,
      borderColor: const .constant(.solid(teal)),
      pointStyle: style,
      pointRadius: 9,
      pointBorderWidth: 2,
      pointBackgroundColor: const .constant(.solid(tealFill)),
      pointBorderColor: const .constant(.solid(teal)),
      extra: const {'pointHitRadius': 14},
    ),
  ],
);
// #enddocregion point-styling
