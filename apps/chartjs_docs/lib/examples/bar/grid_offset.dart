// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-grid-offset
const offsetGrid = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [BarDataset(label: 'Visitors', data: values)],
  scales: {'x': CategoryAxis(grid: AxisGrid(offset: true))},
);
// #enddocregion bar-grid-offset
