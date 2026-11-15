// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-data-values
const valuesBar = ChartConfig(
  type: .bar,
  labels: ['Mon', 'Tue', 'Wed', 'Thu'],
  datasets: [
    BarDataset(label: 'One value for each label', data: [20, 10, 30, 25]),
  ],
);
// #enddocregion bar-data-values
