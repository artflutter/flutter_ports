// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const elementDefaults = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(label: 'Sales', data: sales),
    LineDataset(label: 'Costs', data: costs),
  ],
  // Defaults for all lines and points of this chart.
  elements: ChartElements(
    line: LineElementStyle(tension: 0.3, borderWidth: 4),
    point: PointElementStyle(radius: 6, pointStyle: RectRotPointStyle()),
  ),
);
// #enddocregion sample
