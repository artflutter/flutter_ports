// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion stepped-after
const stepAfter = LineDataset(
  label: 'stepped: .after',
  data: stepValues,
  borderColor: .constant(.solid(blue)),
  stepped: SteppedLine.after,
);
// #enddocregion stepped-after
