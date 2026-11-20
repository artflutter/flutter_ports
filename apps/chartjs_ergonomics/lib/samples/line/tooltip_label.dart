// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const tooltipLabel = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: sales,
      borderColor: .constant(.solid(teal)),
    ),
  ],
  tooltip: ChartTooltip(
    callbacks: TooltipCallbacks(title: monthTitle, label: unitsLabel),
  ),
);

List<String>? monthTitle(TooltipModel tooltip, List<TooltipItem> items) => [
  'Month: ${items.first.label.join(' ')}',
];

// null keeps the built-in label.
List<String>? unitsLabel(TooltipModel tooltip, TooltipItem item) => [
  '${item.formattedValue} units',
];
// #enddocregion sample
