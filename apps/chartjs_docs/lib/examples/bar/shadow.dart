// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-shadow
const shadowBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Shadow',
      data: values,
      backgroundColor: .constant(.solid(teal)),
      shadow: ChartShadow(
        color: Color(0x66000000),
        blur: 10,
        offset: Offset(0, 6),
      ),
    ),
  ],
);
// #enddocregion bar-shadow
