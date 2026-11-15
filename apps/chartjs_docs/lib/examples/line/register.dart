// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// Registers the chart components, one time for the app.
void registerCharts() {
  // #docregion register
  Chart.register(registerables);
  // #enddocregion register
}
