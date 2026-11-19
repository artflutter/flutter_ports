// Ported from Chart.js v4.6.1 src/core/core.layouts.defaults.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.layouts.defaults.js`.
///
/// The value object of `defaults.set` is a typed option scope of the kind
/// `LayoutOptions` (Chart.js ADR 0054 §3), and numbers are `double`
/// (Chart.js ADR 0146). [IDefaults] is the interface of the `defaults` object
/// of `core.defaults.js`.
library;

import 'package:flutter/painting.dart' show EdgeInsets;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// core.layouts.defaults.js:1 `applyLayoutsDefaults`.
void applyLayoutsDefaults(IDefaults defaults) {
  defaults.set(
    'layout',
    LayoutOptionsScope()
      ..autoPadding = true
      ..padding = EdgeInsets.zero,
  );
}
