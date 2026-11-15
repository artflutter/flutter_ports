// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion line-dashed
const dashedLine = LineDataset(
  label: 'Dashed',
  data: values,
  borderColor: .constant(.solid(teal)),
  borderDash: [10, 6],
  borderCapStyle: StrokeCap.round,
  extra: {'borderDashOffset': 2},
);
// #enddocregion line-dashed
