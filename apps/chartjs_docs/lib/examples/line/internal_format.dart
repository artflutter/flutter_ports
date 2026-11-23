// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion internal-format
final preparedLine = LineDataset(
  label: 'Sorted, with no parse step',
  data: .points([DataPoint(0, 12), DataPoint(1, 18), DataPoint(2, 9)]),
  extra: const {'parsing': false},
);
// #enddocregion internal-format
