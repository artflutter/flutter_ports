// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion gaps-break
const brokenLine = LineDataset(
  label: 'With gaps',
  data: [65, 59, null, 81, 56, null, 40],
  borderColor: .constant(.solid(teal)),
);
// #enddocregion gaps-break
