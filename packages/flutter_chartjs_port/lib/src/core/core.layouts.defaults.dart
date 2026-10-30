// Ported from Chart.js v4.6.1 src/core/core.layouts.defaults.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.layouts.defaults.js`.
///
/// The value object of `defaults.set` is a typed option scope of the kind
/// `LayoutOptions` (Chart.js ADR 0054 §3), and numbers are `double`
/// (Chart.js ADR 0045). [Defaults] is the interface of the `defaults` object
/// of `core.defaults.js`.
library;

import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show LayoutOptionsScope, PaddingScope;
import 'package:flutter_chartjs_port/src/types/index.dart';

/// core.layouts.defaults.js:1 `applyLayoutsDefaults`.
void applyLayoutsDefaults(Defaults defaults) {
  defaults.set(
    'layout',
    LayoutOptionsScope()
      ..autoPadding = true
      ..padding = (PaddingScope()
        ..top = 0.0
        ..right = 0.0
        ..bottom = 0.0
        ..left = 0.0),
  );
}
