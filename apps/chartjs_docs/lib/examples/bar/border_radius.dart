// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

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

// #docregion bar-border-radius
const roundedBars = BarDataset(
  label: 'A number',
  data: mixedSigns,
  backgroundColor: .constant(.solid(teal)),
  borderRadius: 12,
);
// #enddocregion bar-border-radius

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
              config: ChartConfig(
                type: .bar,
                labels: months,
                datasets: [roundedBars],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
