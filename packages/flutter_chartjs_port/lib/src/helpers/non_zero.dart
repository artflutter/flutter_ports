// Original code, not ported from Chart.js: the zero and NaN test of a number.

/// The test `if (x)` of upstream on a number that has a Dart type.
library;

/// The test `if (x)` of upstream on a `double` or a `double?`.
extension NonZeroDouble on double? {
  /// Upstream `if (x)` on a number: false for null, 0, -0 and NaN.
  bool get isNonZero {
    final value = this;
    return value != null && value != 0.0 && !value.isNaN;
  }
}
