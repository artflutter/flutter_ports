// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-border-width
const sameBorders = BarDataset(
  label: 'A number',
  data: values,
  backgroundColor: .constant(.solid(tealFill)),
  borderColor: .constant(.solid(teal)),
  borderWidth: 3,
);
// #enddocregion bar-border-width
