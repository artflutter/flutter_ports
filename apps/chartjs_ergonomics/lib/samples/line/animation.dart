// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const animation = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: sales,
      borderColor: .constant(.solid(teal)),
    ),
  ],
  animation: ChartAnimation(
    duration: Duration(seconds: 2),
    easing: Curves.bounceOut,
  ),
);
// #enddocregion sample
