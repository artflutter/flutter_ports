// Original code, not ported from Chart.js: the data scope of a test Map.

/// The [ChartDataScope] of a data Map of a test, for the `data` setter of a
/// chart or a config (row `adapt-config-objects`).
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// A new [ChartDataScope] with each own key of [map] in its order and the
/// same value, as the config boundary makes it from a raw data Map.
ChartDataScope dataScopeOf(Map<String, Object?> map) {
  final scope = ChartDataScope();
  for (final MapEntry(:key, :value) in map.entries) {
    scope.jsWrite(key, value);
  }
  return scope;
}
