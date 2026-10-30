// Original code, not ported from Chart.js: the typed data item interface.

/// The interface of a typed data item (Chart.js ADR 0054 §7).
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;

/// A data item with typed fields: `DataPoint` of the typed API
/// (`lib/src/typed/`) implements it. The interface is here, because ported
/// files never import `lib/src/typed/` (Chart.js ADR 0052 §8). The parse
/// functions read its fields when the parsing key is the default key, else
/// by name through the face.
abstract interface class TypedDataItem implements JsObjectFace {
  /// `x`: a `double`, a `DateTime` (a JS `Date`) or a `String`.
  Object get x;

  /// `y`: Dart `null` is JS `null`.
  double? get y;

  /// `r`: Dart `null` is an absent `r`.
  double? get r;
}
