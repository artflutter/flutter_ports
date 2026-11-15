// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-border-width-object
const sideBorders = BarDataset(
  label: 'A width for each side',
  data: values,
  backgroundColor: .constant(.solid(tealFill)),
  borderColor: .constant(.solid(teal)),
  // No bottom border: an omitted side has no border.
  extra: {
    'borderWidth': {'top': 6, 'left': 1, 'right': 1},
  },
);
// #enddocregion bar-border-width-object
