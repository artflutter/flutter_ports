// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.

import 'package:chartjs_docs/examples/bar_data.dart';
import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The border skip example, with the value of the selected variant.
// #docregion bar-border-skipped
// A BorderSkippedEdge, false or true.
ChartConfig borderSkipped(Object skipped) => ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Border width 4',
      data: mixedSigns,
      backgroundColor: const .constant(.solid(tealFill)),
      borderColor: const .constant(.solid(teal)),
      borderWidth: 4,
      extra: {'borderSkipped': skipped},
    ),
  ],
);
// #enddocregion bar-border-skipped
