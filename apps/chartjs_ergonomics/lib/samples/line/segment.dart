// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const segment = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: .values(sales),
      borderColor: .constant(.solid(teal)),
      borderWidth: 3,
      segment: LineSegmentStyle(borderColor: downInRed),
    ),
  ],
);

// null keeps the line color.
ChartPaint? downInRed(ScriptableLineSegmentContext part) =>
    sales[part.p1DataIndex]! < sales[part.p0DataIndex]!
    ? const .solid(red)
    : null;
// #enddocregion sample
