// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// Sets a default for all line charts that the app creates after this call.
void spanGapsInAllLineCharts() {
  // #docregion defaults
  defaults.override('line', {'spanGaps': true});
  // #enddocregion defaults
}
