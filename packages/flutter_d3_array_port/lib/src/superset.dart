// Ported from d3-array v3.2.4 src/superset.js (ISC, Mike Bostock).

/// Port of `src/superset.js` of d3-array 3.2.4.
library;

@pragma('vm:prefer-inline')
bool _isNaN<T>(T value) => value is num && value.isNaN;

/// Returns `true` if [values] is a superset of [other] (every value in [other]
/// also appears in [values]), lazily consuming [values].
// DIVERGES(d3-array): adapt-array-typed-api, uses native Dart value-equal
// Set<T> with SameValueZero NaN handling.
bool superset<T>(Iterable<T> values, Iterable<T> other) {
  final iterator = values.iterator;
  final seen = <T>{};
  var seenNaN = false;
  for (final o in other) {
    final oNaN = _isNaN(o);
    if (oNaN ? seenNaN : seen.contains(o)) continue;
    while (true) {
      if (!iterator.moveNext()) return false;
      final value = iterator.current;
      final valNaN = _isNaN(value);
      if (valNaN) {
        seenNaN = true;
        if (oNaN) break;
      } else {
        seen.add(value);
        if (!oNaN && o == value) break;
      }
    }
  }
  return true;
}
