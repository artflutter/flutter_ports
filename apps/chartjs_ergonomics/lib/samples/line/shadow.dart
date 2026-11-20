// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const shadow = ChartConfig(
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: sales,
      borderColor: .constant(.solid(teal)),
      borderWidth: 3,
      shadow: ChartShadow(
        color: Color(0x66000000),
        blur: 10,
        offset: Offset(0, 6),
      ),
    ),
  ],
);
// #enddocregion sample
