// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// Bars on a linear x axis, with uneven spaces between the x values.
final unevenPoints = [
  DataPoint(1, 20),
  DataPoint(2, 35),
  DataPoint(4, 30),
  DataPoint(8, 45),
  DataPoint(9, 25),
];

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

// #docregion bar-thickness-flex
final flexBars = ChartConfig(
  type: .bar,
  datasets: [
    BarDataset(
      label: 'Widths from the spaces',
      points: unevenPoints,
      backgroundColor: const .constant(.solid(teal)),
      barThickness: BarThickness.flex,
    ),
  ],
  scales: const {'x': LinearAxis()},
);
// #enddocregion bar-thickness-flex

void main() {
  Chart.register(registerables);
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: ChartView(config: flexBars)),
        ),
      ),
    ),
  );
}
