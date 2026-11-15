// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-scopes
const scopedBar = ChartConfig(
  type: .bar,
  labels: months,
  // For this dataset only.
  datasets: [
    BarDataset(
      label: 'Sales',
      data: values,
      backgroundColor: .constant(.solid(tealFill)),
      borderColor: .constant(.solid(teal)),
    ),
  ],
  // For all bar elements.
  elements: ChartElements(
    bar: BarElementStyle(borderWidth: 2, borderRadius: 6),
  ),
  // For all bar datasets. This scope has no parameter.
  extra: {
    'datasets': {
      'bar': {'barPercentage': 0.6},
    },
  },
);
// #enddocregion bar-scopes
