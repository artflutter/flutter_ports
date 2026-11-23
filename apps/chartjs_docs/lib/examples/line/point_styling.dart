// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

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

/// The values of the first docs chart.
const List<num?> values = [65, 59, 80, 81, 56, 55, 40];

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

/// The fill color that goes with [teal].
const Color tealFill = Color.fromRGBO(75, 192, 192, 0.25);

/// The point style example, with the style of the selected variant.
// #docregion point-styling
ChartConfig pointStyling(PointStyle style) => ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Visitors',
      data: const .values(values),
      borderColor: const .constant(.solid(teal)),
      pointStyle: .constant(style),
      pointRadius: const .constant(9),
      pointBorderWidth: 2,
      pointBackgroundColor: const .constant(.solid(tealFill)),
      pointBorderColor: const .constant(.solid(teal)),
      extra: const {'pointHitRadius': 14},
    ),
  ],
);
// #enddocregion point-styling

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
            child: ChartView(config: pointStyling(const CirclePointStyle())),
          ),
        ),
      ),
    ),
  );
}
