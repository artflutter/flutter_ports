// Ported from Chart.js v4.5.1 src/helpers/helpers.core.ts (MIT, Chart.js Contributors).

/// Partial port of `src/helpers/helpers.core.ts`: `isFinite` only, the symbol
/// that `helpers.math.ts` imports.
///
/// @namespace Chart.helpers
library;

import 'package:flutter_chartjs/src/js/js_number.dart';

/// helpers.core.ts:61 `isNumberFinite`: whether [value] is a finite number.
///
/// Dart has no `Number` wrapper objects, so `value instanceof Number` has no
/// counterpart.
bool _isNumberFinite(Object? value) {
  return value is num && jsIsFinite(value);
}

/// helpers.core.ts:65 `isFinite`, the exported name of `isNumberFinite`.
const bool Function(Object? value) isFinite = _isNumberFinite;
