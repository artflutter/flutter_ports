// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The values of the first docs chart.
const List<num?> values = [65, 59, 80, 81, 56, 55, 40];

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

/// The second line color of the examples.
const Color red = Color.fromRGBO(255, 99, 132, 1);

/// A chart with the one dataset [dataset] over [months].
ChartConfig oneLine(LineDataset dataset) =>
    ChartConfig(type: .line, labels: months, datasets: [dataset]);

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

// #docregion scriptable
const scriptableLine = LineDataset(
  label: 'Score',
  data: values,
  borderColor: .constant(.solid(teal)),
  // A typed function for a color.
  backgroundColor: .resolver(pointFill),
  // A list by data index, through extra.
  extra: {
    'pointRadius': [4, 6, 8, 10, 8, 6, 4],
  },
);

ChartPaint pointFill(ChartContext context) {
  final index = context.dataIndex;
  return ChartPaint.solid(index != null && values[index]! >= 60 ? teal : red);
}
// #enddocregion scriptable

void main() {
  Chart.register(registerables);
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: ChartView(config: oneLine(scriptableLine))),
        ),
      ),
    ),
  );
}
