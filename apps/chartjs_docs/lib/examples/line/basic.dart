// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion basic
const basicLine = ChartConfig(
  labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
  datasets: [
    LineDataset(
      label: 'My First Dataset',
      data: [65, 59, 80, 81, 56, 55, 40],
      fill: .none,
      borderColor: .constant(.solid(Color.fromRGBO(75, 192, 192, 1))),
      tension: 0.1,
    ),
  ],
);
// #enddocregion basic

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: basicLine)),
        ),
      ),
    ),
  );
}
