// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The data of the examples with a negative value.
const List<num?> mixedSigns = [65, -30, 80, 81, -20, 55, 40];

/// The labels of `Utils.months({count: 7})`.
const List<Object> months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
];

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

/// The fill color that goes with [teal].
const Color tealFill = Color.fromRGBO(75, 192, 192, 0.25);

/// The border skip example, with the value of the selected variant.
// #docregion bar-border-skipped
// A BorderSkippedEdge, false or true.
ChartConfig borderSkipped(Object skipped) => ChartConfig(
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

void main() {
  Chart.register(registerables);
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ChartView(config: borderSkipped(BorderSkippedEdge.start)),
          ),
        ),
      ),
    ),
  );
}
