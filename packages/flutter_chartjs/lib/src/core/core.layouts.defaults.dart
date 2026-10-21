// Ported from Chart.js v4.5.1+7169e651 src/core/core.layouts.defaults.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.layouts.defaults.js`.
///
/// Option objects are `Map<String, Object?>` and numbers are `double`
/// (Chart.js ADRs 0006 and 0032). [Defaults] is the interface of the
/// `defaults` object of `core.defaults.js`.
library;

import 'package:flutter_chartjs/src/types/index.dart';

/// core.layouts.defaults.js:1 `applyLayoutsDefaults`.
void applyLayoutsDefaults(Defaults defaults) {
  defaults.set('layout', <String, Object?>{
    'autoPadding': true,
    'padding': <String, Object?>{
      'top': 0.0,
      'right': 0.0,
      'bottom': 0.0,
      'left': 0.0,
    },
  });
}
