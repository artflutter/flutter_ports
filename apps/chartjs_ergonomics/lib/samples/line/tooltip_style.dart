// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const tooltipStyle = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: .values(sales),
      borderColor: .constant(.solid(teal)),
    ),
  ],
  tooltip: ChartTooltip(
    backgroundColor: .solid(Color(0xF0FFFFFF)),
    titleColor: .solid(Color(0xFF17243B)),
    bodyColor: .solid(Color(0xFF475569)),
    titleFont: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    padding: EdgeInsets.all(12),
    cornerRadius: 10,
    displayColors: false,
  ),
);
// #enddocregion sample
