// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

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
