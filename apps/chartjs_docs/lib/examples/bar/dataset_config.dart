// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

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

// #docregion bar-dataset-config
const thinBars = ChartConfig(
  labels: months,
  datasets: [
    BarDataset(
      label: 'Thin bars',
      barPercentage: 0.5,
      barThickness: BarThickness.pixels(6),
      maxBarThickness: 8,
      minBarLength: 2,
      data: .values([10, 20, 30, 40, 50, 60, 70]),
    ),
  ],
);
// #enddocregion bar-dataset-config

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: thinBars)),
        ),
      ),
    ),
  );
}
