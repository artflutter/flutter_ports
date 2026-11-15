// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

/// The second line color of the examples.
const Color red = Color.fromRGBO(255, 99, 132, 1);

// #docregion segment
const trend = <num?>[65, 59, 80, 81, null, 55, 40, 62];

const segmentLine = ChartConfig(
  type: .line,
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon'],
  datasets: [
    LineDataset(
      label: 'Trend',
      data: trend,
      borderColor: .constant(.solid(teal)),
      spanGaps: true,
      segment: LineSegmentStyle(
        borderColor: segmentColor,
        borderDash: segmentDash,
      ),
    ),
  ],
);

// Gray across a gap, red where the line goes down; null keeps the line color.
ChartPaint? segmentColor(ScriptableLineSegmentContext segment) {
  final from = trend[segment.p0DataIndex];
  final to = trend[segment.p1DataIndex];
  if (from == null || to == null) {
    return const ChartPaint.solid(Color.fromRGBO(0, 0, 0, 0.2));
  }
  return from > to ? const ChartPaint.solid(red) : null;
}

// Dashed across a gap.
List<double>? segmentDash(ScriptableLineSegmentContext segment) =>
    trend[segment.p0DataIndex] == null || trend[segment.p1DataIndex] == null
    ? const [6, 6]
    : null;
// #enddocregion segment

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: segmentLine)),
        ),
      ),
    ),
  );
}
