// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
final fillSplit = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales against a target of 60',
      data: sales,
      borderColor: const .constant(.solid(teal)),
      fill: const FillTarget.toValue(60)
          .split(above: const .solid(tealFill), below: const .solid(redFill)),
    ),
  ],
);
// #enddocregion sample
