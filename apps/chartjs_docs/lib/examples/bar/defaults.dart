// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// Sets a default for all bar charts that the app creates after this call.
void skipNullInAllBarCharts() {
  // #docregion bar-defaults
  defaults.override('bar', {'skipNull': true});
  // #enddocregion bar-defaults
}
