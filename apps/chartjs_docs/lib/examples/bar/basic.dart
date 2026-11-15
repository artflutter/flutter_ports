// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-basic
const barFills = <ChartPaint>[
  .solid(Color.fromRGBO(255, 99, 132, 0.2)),
  .solid(Color.fromRGBO(255, 159, 64, 0.2)),
  .solid(Color.fromRGBO(255, 205, 86, 0.2)),
  .solid(Color.fromRGBO(75, 192, 192, 0.2)),
  .solid(Color.fromRGBO(54, 162, 235, 0.2)),
  .solid(Color.fromRGBO(153, 102, 255, 0.2)),
  .solid(Color.fromRGBO(201, 203, 207, 0.2)),
];

const barBorders = <ChartPaint>[
  .solid(Color.fromRGBO(255, 99, 132, 1)),
  .solid(Color.fromRGBO(255, 159, 64, 1)),
  .solid(Color.fromRGBO(255, 205, 86, 1)),
  .solid(Color.fromRGBO(75, 192, 192, 1)),
  .solid(Color.fromRGBO(54, 162, 235, 1)),
  .solid(Color.fromRGBO(153, 102, 255, 1)),
  .solid(Color.fromRGBO(201, 203, 207, 1)),
];

const basicBar = ChartConfig(
  type: .bar,
  labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
  datasets: [
    BarDataset(
      label: 'My First Dataset',
      data: [65, 59, 80, 81, 56, 55, 40],
      backgroundColor: .indexed(barFills),
      borderColor: .indexed(barBorders),
      borderWidth: 1,
    ),
  ],
  scales: {'y': LinearAxis(beginAtZero: true)},
);
// #enddocregion bar-basic

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: basicBar)),
        ),
      ),
    ),
  );
}
