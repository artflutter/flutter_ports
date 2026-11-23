// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
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

/// The third line color of the examples.
const Color blue = Color.fromRGBO(54, 162, 235, 1);

/// The data of the stepped examples.
const List<num?> stepValues = [10, 40, 25, 60, 45, 80, 70];

// #docregion stepped-before
const stepBefore = LineDataset(
  label: 'stepped: .before',
  data: .values(stepValues),
  borderColor: .constant(.solid(blue)),
  stepped: SteppedLine.before,
);
// #enddocregion stepped-before

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: ChartView(
              config: ChartConfig(labels: months, datasets: [stepBefore]),
            ),
          ),
        ),
      ),
    ),
  );
}
