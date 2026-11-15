// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

// #docregion data-points
final pointsLine = ChartConfig(
  type: .line,
  datasets: [
    LineDataset(
      label: 'An x and a y for each item',
      points: [
        DataPoint(10, 20),
        DataPoint(15, 10),
        DataPoint(40, 30),
        DataPoint(45, 25),
      ],
      borderColor: const .constant(.solid(teal)),
    ),
  ],
  scales: const {'x': LinearAxis()},
);
// #enddocregion data-points

void main() {
  Chart.register(registerables);
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: ChartView(config: pointsLine)),
        ),
      ),
    ),
  );
}
