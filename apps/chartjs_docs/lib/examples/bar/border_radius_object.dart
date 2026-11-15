// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/bar_data.dart';
import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-border-radius-object
const cornerBars = BarDataset(
  label: 'A radius for each corner',
  data: mixedSigns,
  backgroundColor: .constant(.solid(teal)),
  extra: {
    'borderRadius': {'topLeft': 16, 'topRight': 2},
  },
);
// #enddocregion bar-border-radius-object
