// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const gradient = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: .values(sales),
      borderWidth: 4,
      // The points are canvas pixels, not chart values.
      borderColor: .constant(
        ChartGradient.linear(Offset.zero, Offset(700, 0), [blue, red]),
      ),
    ),
  ],
);
// #enddocregion sample
