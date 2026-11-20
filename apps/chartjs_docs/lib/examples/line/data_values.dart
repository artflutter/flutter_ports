// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

// #docregion data-values
const valuesLine = ChartConfig(
  labels: ['Mon', 'Tue', 'Wed', 'Thu'],
  datasets: [
    LineDataset(
      label: 'One value for each label',
      data: [20, 10, 30, 25],
      borderColor: .constant(.solid(teal)),
    ),
  ],
);
// #enddocregion data-values

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: valuesLine)),
        ),
      ),
    ),
  );
}
