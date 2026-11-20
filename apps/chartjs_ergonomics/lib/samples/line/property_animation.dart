// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const propertyAnimation = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Hover a point',
      data: sales,
      borderColor: .constant(.solid(teal)),
      pointRadius: 5,
      pointHoverRadius: 12,
    ),
  ],
  // One item for each animated property.
  animations: [
    RadiusAnimation(
      duration: Duration(milliseconds: 700),
      easing: Curves.elasticOut,
    ),
  ],
);
// #enddocregion sample
