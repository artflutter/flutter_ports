// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion scopes
const scopedLine = ChartConfig(
  type: .line,
  labels: months,
  // For this dataset only.
  datasets: [
    LineDataset(
      label: 'Sales',
      data: values,
      borderColor: .constant(.solid(teal)),
    ),
  ],
  // For all line elements and all point elements.
  elements: ChartElements(
    line: LineElementStyle(tension: 0.3, borderWidth: 4),
    point: PointElementStyle(radius: 6),
  ),
  // For all line datasets. This scope has no parameter.
  extra: {
    'datasets': {
      'line': {'pointHoverRadius': 10},
    },
  },
);
// #enddocregion scopes
